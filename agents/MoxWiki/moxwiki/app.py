#!/usr/bin/python
# -*- coding: utf-8 -*-
import os
import json
import pytz
from datetime import datetime
from dateutil import parser as dateparser

from agent.amqpclient import MessageListener, CannotConnectException, InvalidCredentialsException
from agent.message import NotificationMessage, EffectUpdateMessage
from agent.config import read_properties_files, MissingConfigKeyError
from SeMaWi import Semawi
from PyLoRA import Lora
from PyOIO.OIOCommon.exceptions import InvalidOIOException
from PyOIO.organisation import Bruger, Interessefaellesskab, ItSystem, Organisation, OrganisationEnhed, OrganisationFunktion
from PyOIO.klassifikation import Facet, Klasse, Klassifikation

from jinja2 import Environment, PackageLoader
from moxwiki.jinja2_override.silentundefined import SilentUndefined

from moxwiki.exceptions import TemplateNotFoundException

DIR = os.path.dirname(os.path.realpath(__file__))

configfile = DIR + "/settings.conf"
statefile = DIR + "/state.json"
config = read_properties_files("/srv/mox/mox.conf", configfile)
template_environment = Environment(loader=PackageLoader('moxwiki', 'templates'), undefined=SilentUndefined, trim_blocks=True, lstrip_blocks=True)

class MoxWiki(object):

    statefile = DIR + "/state.json"
    state = None
    state_changed = False

    def __init__(self):

        self.loadstate()

        try:
            wiki_host = config['moxwiki.wiki.host']
            wiki_username = config['moxwiki.wiki.username']
            wiki_password = config['moxwiki.wiki.password']

            amqp_host = config['moxwiki.amqp.host']
            amqp_username = config['moxwiki.amqp.username']
            amqp_password = config['moxwiki.amqp.password']
            amqp_queue = config['moxwiki.amqp.queue']

            rest_host = config['moxwiki.rest.host']
            rest_username = config['moxwiki.rest.username']
            rest_password = config['moxwiki.rest.password']

        except KeyError as e:
            raise MissingConfigKeyError(str(e))

        self.accepted_object_types = ['bruger', 'interessefaellesskab', 'itsystem', 'organisation', 'organisationenhed', 'organisationfunktion']

        try:
            self.notification_listener = MessageListener(amqp_username, amqp_password, amqp_host, amqp_queue, queue_parameters={'durable': True})
            self.notification_listener.callback = self.callback
        except [CannotConnectException, InvalidCredentialsException] as e:
            print "Warning: %s" % e
            print "Not listening to AMQP messages on this channel"
            self.notification_listener = None

        self.semawi = Semawi(wiki_host, wiki_username, wiki_password)
        self.lora = Lora(rest_host, rest_username, rest_password)

    def loadstate(self):
        try:
            fp = open(statefile, 'r')
            self.state = json.load(fp)
            fp.close()
        except:
            self.state = {}
        self.state_changed = False

    def savestate(self):
        if self.state_changed:
            fp = open(statefile, 'w')
            json.dump(self.state, fp, indent=2)
            fp.close()
            self.state_changed = False

    def sync(self):

        try:
            lastsync = dateparser.parse(self.state['sync'][self.lora.host]['lastsync'])
            print "Last synchronization with %s was %s" % (self.lora.host, lastsync.strftime('%Y-%m-%d %H:%M:%S'))
            print "Getting latest changes from REST server"
        except:
            print "Has never synchronized before"
            print "Getting all objects from REST server"
            lastsync = None

        uuids = {}
        newsync = datetime.now(pytz.utc)
        for type in [Bruger, Interessefaellesskab, ItSystem, Organisation, OrganisationEnhed, OrganisationFunktion, Facet, Klasse, Klassifikation]:
            uuids[type.ENTITY_CLASS] = self.lora.get_uuids_of_type(type, lastsync)
        for entity_class, type_uuids in uuids.items():
            for uuid in type_uuids:
                item = self.lora.get_object(uuid, entity_class)
                self.update(item.ENTITY_CLASS, uuid, True)

        if not 'sync' in self.state:
            self.state['sync'] = {}
        if not self.lora.host in self.state['sync']:
            self.state['sync'][self.lora.host] = {}
        self.state['sync'][self.lora.host]['lastsync'] = newsync.isoformat()
        self.state_changed = True
        self.savestate()
        print "Synchronization complete"

    # Blocks until KeyboardInterrupt
    def listen(self):
        if self.notification_listener:
            self.notification_listener.run()

    def callback(self, channel, method, properties, body):
        message = NotificationMessage.parse(properties.headers, body)
        if message:
            print "Got a notification"
            if message.objecttype in self.accepted_object_types:
                print "Object type '%s' accepted" % message.objecttype
                try:
                    if message.lifecyclecode == 'Slettet':
                        print "lifecyclecode is '%s', performing delete" % message.lifecyclecode
                        self.delete(message.objecttype, message.objectid)
                    else:
                        print "lifecyclecode is '%s', performing update" % message.lifecyclecode
                        self.update(message.objecttype, message.objectid)
                except InvalidOIOException as e:
                    print e
            else:
                print "Object type '%s' rejected" % message.objecttype
        message = EffectUpdateMessage.parse(properties.headers, body)
        if message:
            print "Got an effect update"
            if message.objecttype in self.accepted_object_types:
                print "Object type '%s' accepted" % message.objecttype
                try:
                    self.update(message.objecttype, message.objectid)
                except InvalidOIOException as e:
                    print e
            else:
                print "Object type '%s' rejected" % message.objecttype

    def update(self, objecttype, objectid, accept_cached=False):
        instance = self.lora.get_object(objectid, objecttype, not accept_cached)
        title = instance.current.brugervendtnoegle
        pagename = "%s_%s" % (title, objectid)

        page = self.semawi.site.Pages[pagename]

        if not page.exists:
            previous_registrering = instance.current.before
            if previous_registrering:
                old_title = previous_registrering.brugervendtnoegle
                old_pagename = "%s_%s" % (old_title, objectid)
                old_page = self.semawi.site.Pages[old_pagename]
                if old_page.exists:
                    print "Moving wiki page %s to %s" % (old_pagename, pagename)
                    old_page.move(pagename, reason="LoRa object %s has changed name from %s to %s" % (objectid, old_title, title))

        template = template_environment.get_template("%s.txt" % objecttype)
        if template is None:
            raise TemplateNotFoundException("%s.txt" % objecttype)
        pagetext = template.render({'object': instance, 'begin': '{{', 'end': '}}'})

        if pagetext != page.text():
            page.save(pagetext, summary="Imported from LoRA instance %s" % self.lora.host)

    def delete(self, objecttype, objectid):
        instance = self.lora.get_object(objectid, objecttype)
        pagename = "%s_%s" % (instance.current.brugervendtnoegle, objectid)
        page = self.semawi.site.Pages[pagename]
        page.delete(reason="Deleted in LoRa instance %s" % self.lora.host)


main = MoxWiki()
main.sync()
main.listen()