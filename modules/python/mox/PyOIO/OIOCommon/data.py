import pytz
from datetime import datetime
from virkning import Virkning


class Item(object):

    def __init__(self, registrering, data):
        self.registrering = registrering
        self.virkning = Virkning(data['virkning'])


class ItemContainer(list):

    def at(self, time):
        return [item for item in self if item.virkning.in_effect(time)]

    @property
    def current(self):
        return self.at(datetime.now(pytz.utc))
