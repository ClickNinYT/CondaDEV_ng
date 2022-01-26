from mmfparser.loader import DataLoader
from mmfparser.bytereader import ByteReader
from mmfparser.data.chunkloaders import all
from mmfparser.data.chunkloaders.common import _ObjectTypeMixin
import sys

sys.path.append('..\..\..\..')
from misc import *

class ObjectHeaders(DataLoader, _ObjectTypeMixin):
    headers = None
    headers_count = None
    start = None
    end = None
    current = None
    prop = None
    chunkSize = None
    
    def read(self, reader):
        self.start = reader.tell()
        self.end = self.start + reader.size()
        self.headers_count = 0
        self.headers = all.ObjectHeader(reader)
        self.current = 0
        while reader.tell() < self.end:
            try:
                self.prop = all.ObjectHeader(reader)
                #log("Reading object headers...", 1)
                self.prop.read(reader)
                self.chunkSize = reader.readInt()
                self.headers_count = self.current
                #log(str(self.headers_count), 1)
                #log(str(self.headers), 1)
                self.current += 1
            except:
                print("Warning: Header not readed!", 3)
                pass
    
    def write(self, reader):
        log("Warning: Not yet implemented!", 3)
        pass


class ObjectPropertyList(DataLoader, _ObjectTypeMixin):
    start = None
    end = None
    chunksize = None
    Props_count = None
    Props = None
    current = None
    prop = None

    def read(self, reader):
        self.start = reader.tell()
        self.end = self.start + reader.size()
        self.chunksize = reader.readInt()
        self.Props_count = 0
        self.Props = all.ObjectProperties(reader)
        self.current = 0
        while reader.tell() < self.end:
            try:
               #print reader.tell()
               self.prop = all.ObjectProperties(reader)
               #self.prop.read(reader)
               #self.prop.load(2)
               self.prop.readnew(2, None)
               #log("Reading object properties...", 1)
               self.Props_count = self.current
               #log(str(self.Props_count), 1)
               #log(str(self.Props), 1)
               self.current += 1
            except:
                log("Warning: Properties not readed!", 3)
                pass
  
    def write(self, reader):
        log("Warning: Not yet implemented!", 3)
        pass

class ObjectNames(DataLoader, _ObjectTypeMixin):
    start = None
    end = None
    Names_count = None
    Names = None
    name = None
    current = None
    
    def write(self, reader):
        log("Warning: Not yet implemented!", 3)
        pass

    def read(self, reader):
        self.start = reader.tell()
        self.end = self.start + reader.size()
        self.Names_count = 0
        self.current = 0
        while reader.tell() < self.end:
            self.name = reader.readString()
            self.Names_count = self.current
            self.Names = self.name
            self.current += 1
        
        
