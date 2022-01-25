from mmfparser.loader import DataLoader
from mmfparser.bytereader import ByteReader
from mmfparser.data.chunkloaders import all
import sys

sys.path.append('..\..\..\..')
from misc import *

class ObjectHeaders(DataLoader, _ObjectTypeMixin):
    def init(self):
        self.headers = None
    
    def read(self, reader):
        start = reader.tell()
        end = start + reader.size()
        headers_count = 0
        headers = all.ObjectHeader(reader)
        current = 0
        while reader.tell() < end:
            prop = all.ObjectHeader(reader)
            log("Reading object headers...", 1)
            prop.read(reader)
            chunkSize = reader.readInt()
            headers_count = current
            log(str(headers_count), 1)
            log(str(headers), 1)
            current += 1
    
    def write(self, reader):
        log("Warning: Not yet implemented!", 3)
        pass


class ObjectPropertyList(DataLoader, _ObjectTypeMixin):
    def init(self):
        self.Props = None

    def read(self, reader):
        start = reader.tell()
        end = start + reader.size()
        chunksize = reader.readInt()
        Props_count = 0
        Props = all.ObjectProperties(reader)
        current = 0
        while reader.tell() < end:
            prop = all.ObjectProperties(reader)
            prop.read()
            log("Reading object properties...", 1)
            Props_count = current
            log(str(Props_count), 1)
            log(str(Props), 1)
            current += 1

    def write(self, reader):
        log("Warning: Not yet implemented!", 3)
        pass

class ObjectNames(DataLoader, _ObjectTypeMixin):
    def write(self, reader):
        log("Warning: Not yet implemented!", 3)
        pass

    def read(self, reader):
        start = reader.tell()
        end = start + reader.size()
        Names_count = 0
        current = 0
        while reader.tell() < end:
            name = reader.readString()
            Names_count = current
            Names = name
            log(str(Names_count), 1)
            log(str(Names), 1)
            current += 1

    def __init__(self, reader):
        self.Names = None
        
        
