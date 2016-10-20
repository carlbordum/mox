#!/usr/bin/python

import argparse
import os
import sys
import subprocess
from socket import gethostname
from installutils import Config, VirtualEnv

domain = gethostname()
DIR = os.path.dirname(os.path.realpath(sys.argv[0]))
MOXDIR = os.path.abspath(DIR + "/../..")
MODULES_DIR = os.path.abspath(MOXDIR + "/modules/python")

parser = argparse.ArgumentParser(description='Install MoxWiki')

parser.add_argument('-y', '--overwrite-virtualenv', action='store_true')
parser.add_argument('-n', '--keep-virtualenv', action='store_true')

parser.add_argument('--wiki-host', action='store', default="http://%s" % domain)
parser.add_argument('--wiki-user', action='store')
parser.add_argument('--wiki-pass', action='store')

parser.add_argument('--amqp-host', action='store')
parser.add_argument('--amqp-user', action='store')
parser.add_argument('--amqp-pass', action='store')
parser.add_argument('--amqp-queue', action='store')

parser.add_argument('--rest-host', action='store', default="http://%s" % domain)
parser.add_argument('--rest-user', action='store')
parser.add_argument('--rest-pass', action='store')

args = parser.parse_args()

# ------------------------------------------------------------------------------

virtualenv = VirtualEnv(DIR + "/python-env")
created = virtualenv.create(args.overwrite_virtualenv, args.keep_virtualenv)
if created:
    subprocess.call(['ln', '--symbolic', '--force', MODULES_DIR + "/mox", virtualenv.environment_dir + "/local/mox"])
    virtualenv.run("python " + DIR + "/setup.py develop")

# ------------------------------------------------------------------------------

configfile = DIR + "/moxwiki/settings.conf"

config_map = {
    'wiki_host': 'moxwiki.wiki.host',
    'wiki_user': 'moxwiki.wiki.username',
    'wiki_pass': 'moxwiki.wiki.password',
    'amqp_host': 'moxwiki.amqp.host',
    'amqp_user': 'moxwiki.amqp.username',
    'amqp_pass': 'moxwiki.amqp.password',
    'amqp_queue': 'moxwiki.amqp.queue',
    'rest_host': 'moxwiki.rest.host',
    'rest_user': 'moxwiki.rest.username',
    'rest_pass': 'moxwiki.rest.password'
}
config = Config(configfile)

for key in config_map:
    value = None
    if hasattr(args, key):
        value = getattr(args, key)
    if value is None:
        # Not good. We must have these values. Prompt the user
        value = raw_input("%s = " % key)
    else:
        print "%s = %s" % (key, value)
    config.set(config_map[key], value)

config.save()

# ------------------------------------------------------------------------------

proc = subprocess.Popen(['sudo', 'cp', "%s/setup/moxwiki.conf" % DIR, '/etc/init/'])
proc.wait()