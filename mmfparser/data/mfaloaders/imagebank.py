from mmfparser.loader import DataLoader
import hashlib
from mmfparser.data.chunkloaders.imagebank import ImageItem
from misc import *

class AGMIBank(DataLoader):
    palette = None
    graphicMode = 4
    def initialize(self):
        self.items = []
        self.itemDict = {}

    def read(self, reader):
        log("Reading Textures...", 1)
        self.graphicMode = reader.readInt()
        self.paletteVersion = reader.readShort(True)
        self.paletteEntries = reader.readShort(True)
        self.palette = [reader.readColor()
            for _ in xrange(256)]
        count = reader.readInt()
        log("Numbers of images: " + str(count), 1)
        for _ in xrange(count):
            item = self.new(ImageItem, reader, debug=True)
            self.items.append(item)
            self.itemDict[item.handle] = item

    def write(self, reader):
        log("Writing Textures...", 1)
        reader.writeInt(self.graphicMode)
        reader.writeShort(self.paletteVersion, True)
        reader.writeShort(self.paletteEntries, True)
        for item in self.palette:
            reader.writeColor(item)
        reader.writeInt(len(self.items))
        log("Number of images offsets: " + str(len(self.items)), 1)
        for item in self.items:
           #log("Writing image to MFA: " + str(len(reader)), 1)
           item.write(reader)


