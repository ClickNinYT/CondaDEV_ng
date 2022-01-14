from mmfparser.bytereader import ByteReader
from mmfparser.loader import DataLoader
from mmfparser.exceptions import InvalidData

def findAppendedOffset(reader):
    """
    I personally hope I don't have to revisit this function
    """
    if reader.read(2) != bytes('MZ', encoding='utf8'):
        raise InvalidData('invalid executable signature')
    reader.seek(60)

    hdr_ofs = reader.readInt(True)

    reader.seek(hdr_ofs)
    if reader.read(4) != bytes('PE\x00\x00', encoding='utf8'):
        raise InvalidData('invalid PE signature')

    # COFF header
    reader.skipBytes(2)
    numberOfSections = reader.readShort(True)
    reader.skipBytes(16)

    # seek to first section table entry
    optional_header = 28 + 68
    data_dir = 16 * 8
    reader.skipBytes(optional_header + data_dir)

    pos = None

    for i in range(numberOfSections):
        start = reader.tell()
        name = reader.readByte()
        if name == '.extra':
            reader.seek(start+16+4)
            pos = reader.readInt(True) # pointerToRawData
            break
        elif i >= numberOfSections - 1:
            reader.seek(start+16)
            size = reader.readInt(True) # sizeOfRawData
            addr = reader.readInt(True) # pointerToRawData
            pos = addr + size
            break
        reader.seek(start+40)
    reader.seek(pos)
    return reader.tell()
