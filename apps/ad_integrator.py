# encoding: utf-8
""" POC of using pywinrm for AD management """
import sys
import xmltodict
import winrm
import ad_password
if sys.version_info[0] < 3:
    # This is needed to enforce correct handling of unicode
    exit('You will need python 3')


class AdIntegrator(object):
    def __init__(self):
        self.session = winrm.Session('https://192.168.1.234:5986/wsman',
                                     transport='ntlm',
                                     server_cert_validation='ignore',
                                     auth=('AD\Administrator',
                                           ad_password.password))
        self.dc = 'dc=ad,dc=magenta-aps,dc=dk'

    def test_connection(self, debug=False):
        """ Test that the winrm connection works
        :param debug: If true more output will be written to terminal
        :return: Return true if connection succeeded
        """
        r = self.session.run_cmd('ipconfig', ['/all'])
        if debug:
            print(r.status_code)
            print(r.std_out)
            print(r.std_err)
        return r.status_code == 0

    def _run_power_shell_script(self, ps_script):
        """ Run a PowerShell script on remote machine
        :param ps_script: The script to run
        :return: Tuple indicating success/failure and possible error message
        """
        r = self.session.run_ps(ps_script)
        if not r.status_code == 0:
            xml = xmltodict.parse(r.std_err[11:])['Objs']
            msg = xml['S'][0]['#text']
        else:
            msg = r.std_out
        return (r.status_code == 0, msg)

    def _format_path_string(self, ou):
        """ Format an OU path into X.500-syntax
        :param ou: Name of the OU, will be a list if not top-level
        :return: The X.500 formatted path
        """
        if isinstance(ou, list):
            path_string = ''
            for unit in ou:
                path_string += 'OU={},'.format(unit)
            path_string = path_string + self.dc
        elif ou:
            path_string = 'OU={},{}'.format(ou, self.dc)
        else:
            path_string = self.dc
        return path_string

    def create_password(self, user=None):
        """ Create a password for a user.
        Not implemented, returns hard-coded password

        I henhold til Jira issue OS2mo/MO-14 skal vi kunne oprette et pasword
        i henhold kommunens retningslinjer. Vi har brug for at se et
        eksempel på sådan et sæt retningslinjer.

        :param user: The user that needs the password
        :return: A password
        """
        return 'v30ccMNVEIC'.encode('ascii')

    def disable_user(self, name):
        """ Disable an AD user

        Jira issue OS2mo/MO-25
        Det er ikke rigtig klart hvordan denne funktion skal bruges, skal
        der bare kunne disables et brugernavn, eller skal der disables på
        rigtigt navn med risiko for fejl?
        """
        pass

    def create_user(self, name, ou):
        """ Create an AD user

        Vi får i henhold til Jira issue OS2mo/MO-11 brug for at have en
        mapningstabel som angiver hvilke felter der skal oprettes i AD.
        Dette kræver et eksempel på sådan en tabel, for at kunne gøres færdigt

        :param name: Name of the new user
        :param ou: AD Organisational Unit for the new user
        :param debug: If True, more output will be written to terminal
        :return: True if creation succeeded
        """
        password = self.create_password()
        username = name[0] + name[-5:]
        username = username.replace(' ', '')
        username = username.lower()
        path_string = self._format_path_string(ou)
        ps_script = ('New-ADUser -Name "{0}" -DisplayName "{0}" ' +
                     ' -SamAccountName "{1}" -Enable 1 ' +
                     ' -Path "{2}"' +
                     ' -AccountPassword (ConvertTo-SecureString {3} ' +
                     ' -AsPlainText -Force)').format(name, username,
                                                     path_string, password)
        return self._run_power_shell_script(ps_script)

    def create_ou(self, ou_name, super_ou=None, template=None):
        """ Create a new organizational unit, optionally using an existing OU
        as template

        Vi får i henhold til Jira issue OS2mo/MO-12 brug for at have en
        mapningstabel som angiver hvilke felter der skal oprettes i AD.
        Dette kræver et eksempel på sådan en tabel, for at kunne gøres færdigt

        :param ou_name: Name for the new OU
        :param template: Name of existing OU to use as template
        :return: True if creation succeeded
        """
        path_string = self._format_path_string(super_ou)
        if template is None:
            ps_script = 'New-ADOrganizationalUnit -Name "{0}" -Path "{1}"'.format(ou_name, path_string)
        else:
            template_path = self._format_path_string(template)
            ps_script = """
            $OuTemplate = Get-ADOrganizationalUnit -Identity "{0}" -Properties seeAlso,managedBy
            New-ADOrganizationalUnit -Name "{1}" -Path "{2}" -Instance $OuTemplate
            """.format(template_path, ou_name, path_string)
        print(ps_script)
        return self._run_power_shell_script(ps_script)

    def import_mo_structure(self):
        """ Ultra-ultra primitive implementation of an import of a MO
        installation into AD. Starts at root and recursively populates AD.
        """
        import requests

        def read_all_ou_children(uuid, current_ou_list=[]):
            response = requests.get(hostname + '/service/ou/' + uuid)
            ou_info = response.json()
            response = requests.get(hostname + '/service/ou/' + uuid + '/children')
            ou_list = response.json()
            name = ou_info['name']
            if ou_list:
                print('Insert ' + name + ' in ' + str(current_ou_list))
                self.create_ou(name, current_ou_list)
                current_ou_list = [name] + current_ou_list
                for ou in ou_list:
                    read_all_ou_children(ou['uuid'], current_ou_list)
            else:
                print('Insert ' + name + ' in ' + str(current_ou_list))
                self.create_ou(name, current_ou_list)

        hostname = 'http://morademo.atlas.magenta.dk'
        response = requests.get(hostname + '/service/o/')
        root_level = response.json()[0]  # We expect only one root level
        root = requests.get(hostname + '/service/o/' + root_level['uuid'] + '/children')
        organization_uuid = root.json()[0]['uuid']
        read_all_ou_children(organization_uuid)


def main():
    ad_int = AdIntegrator()
    # print(ad_int.test_connection())
    # print(ad_int.create_user('Lave Høns', ['Spas', 'Udenrigsforhold']))
    # print(ad_int.create_ou('Spas', super_ou=['Udenrigsforhold'],
    #                         template='Udenrigsforhold'))
    print(ad_int.import_mo_structure())


if __name__ == '__main__':
    main()