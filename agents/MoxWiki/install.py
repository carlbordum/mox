#!/usr/bin/python

import argparse
import os
import sys
import subprocess
from installutils import VirtualEnv, LogFile

DIR = os.path.dirname(os.path.realpath(sys.argv[0]))
MOXDIR = os.path.abspath(DIR + "/../..")

parser = argparse.ArgumentParser(description='Install MoxWiki')

parser.add_argument('-y', '--overwrite-virtualenv', action='store_true')
parser.add_argument('-n', '--keep-virtualenv', action='store_true')

args = parser.parse_args()

# -----------------------------------------------------------------------------

install_log = LogFile("%s/install.log" % DIR)
install_log.create()

virtualenv = VirtualEnv(DIR + "/python-env")
created = virtualenv.create(args.overwrite_virtualenv, args.keep_virtualenv)
if created:
    print "Running setup.py"
    virtualenv.run(DIR + "/setup.py develop")
    virtualenv.add_moxlib_pointer()

# -----------------------------------------------------------------------------

subprocess.Popen(
    [
        'sudo', 'cp', "%s/setup/moxwiki.conf" % DIR, '/etc/init/'
    ]
).wait()

program_log = LogFile('/var/log/mox/moxwiki.log')
program_log.create()

subprocess.Popen(['sudo', 'service', "moxwiki", 'restart']).wait()
