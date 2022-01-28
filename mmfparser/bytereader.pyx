from __future__ import with_statement
from __future__ import absolute_import

cdef extern from "stdlib.h":
    void *memcpy(void * str1, void * str2, size_t n)

cdef extern from "Python.h":
    FILE * PyFile_AsFile(object)

from libc.stdio cimport fseek, ftell, fread, fwrite

from mmfparser.common cimport allocate_memory

import struct
import subprocess
import os
import traceback
import sys
import tempfile
import contextlib
import io
import typing
import zlib
from io import BytesIO
from io import open
from builtins import bytes

BYTE = struct.Struct('b')
UBYTE = struct.Struct('B')
SHORT = struct.Struct('h')
USHORT = struct.Struct('H')
FLOAT = struct.Struct('f')
DOUBLE = struct.Struct('d')
INT = struct.Struct('i')
UINT = struct.Struct('I')

cdef class ByteReader

cdef inline int check_available(ByteReader reader, size_t size) except -1:
    if reader.pos + size > reader.data_size:
        import traceback
        traceback.print_stack()
        raise struct.error('%s bytes required' % size)
    return 0

cdef inline void ensure_size(ByteReader reader, size_t size):
    if size < reader.data_size:
        size = reader.data_size
    if len(reader.original) >= (reader.start + size) and not reader.shared:
        if size > reader.data_size:
            reader.data_size = size
        return
    cdef char * buf
    newData = allocate_memory(size * 3, &buf)
    memcpy(buf, reader.buffer, reader.data_size)
    reader.original = newData
    reader.buffer = <unsigned char *>buf
    reader.data_size = size
    reader.start = 0
    reader.shared = False

cdef inline void ensure_write_size(ByteReader reader, size_t size):
    ensure_size(reader, reader.pos + size)

cimport cython

@cython.final
cdef class ByteReader:
    def __cinit__(self, input = None, start = None, size = None):
        self.pos = 0
        if isinstance(input, file):
            IF not IS_PYPY:
                self.fp = PyFile_AsFile(input)
            self.python_fp = input
            self.shared = False
            self.start = 0
            return
        else:
            self.python_fp = None
            if input is not None:
                data = input
            else:
                data = ''
        cdef bint isChild = start is not None and size is not None
        self.shared = isChild
        self.original = data
        cdef unsigned char * c_data
        c_data = data
        cdef int int_start
        if isChild:
            int_start = start
            self.start = int_start
            c_data += int_start
        if isChild:
            self.data_size = size
        else:
            self.data_size = len(data)

        self.buffer = c_data

    cpdef int tell(self):
        IF IS_PYPY:
            if self.python_fp:
                return self.python_fp.tell()
        ELSE:
            if self.fp != NULL:
                return ftell(self.fp)

        return self.pos

    cpdef data(self):
        cdef int pos
        IF IS_PYPY:
            if self.python_fp:
                pos = self.tell()
                self.seek(0)
                data = self.read()
                self.seek(pos)
                return data
        ELSE:
            if self.fp != NULL:
                pos = self.tell()
                self.seek(0)
                data = self.read()
                self.seek(pos)
                return data

        return self.buffer[0:self.data_size]

    cpdef bint seek(self, int pos, int mode = 0):
        IF IS_PYPY:
            if self.python_fp:
                self.python_fp.seek(pos, mode)
                return True
        ELSE:
            if self.fp != NULL:
                fseek(self.fp, pos, mode)
                return True

        if mode == 2:
            pos += self.data_size
        elif mode == 1:
            pos += self.pos
        if pos > self.data_size:
            pos = self.data_size
        if pos < 0:
            pos = 0
        self.pos = pos
        return True

    cpdef adjust(self, int to):
        cdef int value = to - (self.tell() % to)

        IF IS_PYPY:
            if self.python_fp:
                self.seek(self.tell() + value)
                return
        ELSE:
            if self.fp != NULL:
                self.seek(self.tell() + value)
                return

        self.pos += value

    cdef bint _read(self, void * value, int size) except False:
        IF IS_PYPY:
            cdef char * data_c
            if self.python_fp:
                data = self.python_fp.read(size)
                if len(data) < size:
                    raise struct.error('%s bytes required' % size)
                data_c = data
                memcpy(value, data_c, len(data))
                return True
        ELSE:
            cdef size_t read_bytes
            if self.fp != NULL:
                read_bytes = fread(value, 1, size, self.fp)
                if read_bytes < size:
                    raise struct.error('%s bytes required' % size)
                return True

        check_available(self, size)
        memcpy(value, (self.buffer + self.pos), size)
        self.pos += size
        return True

    cpdef read(self, int size = -1):
        cdef char * buf
        cdef size_t read_bytes

        IF IS_PYPY:
            if self.python_fp:
                if size == -1:
                    size = self.size() - self.tell()
                return self.python_fp.read(size)
        ELSE:
            if self.fp != NULL:
                if size == -1:
                    size = self.size() - self.tell()
                newData = allocate_memory(size, &buf)
                read_bytes = fread(buf, 1, size, self.fp)
                return newData

        if size == -1 or size + self.pos > self.data_size:
            size = self.data_size - self.pos
        if size < 0:
            size = 0
        data = self.buffer[self.pos:self.pos+size]
        self.pos += size
        if self.pos > self.data_size:
            self.pos = self.data_size
        return data

    cpdef size_t size(self):
        cdef int pos
        cdef int size

        IF IS_PYPY:
            if self.python_fp:
                pos = self.tell()
                self.seek(0, 2)
                size = self.tell()
                self.seek(pos)
                return size
        ELSE:
            if self.fp != NULL:
                pos = self.tell()
                self.seek(0, 2)
                size = self.tell()
                self.seek(pos)
                return size
        
        return self.data_size

    def __len__(self):
        return self.size()

    def __str__(self):
        return self.data()

    def __repr__(self):
        return repr(str(self))

    cpdef short readByte(self, bint asUnsigned = False) except? -10:
        cdef char value
        self._read(&value, 1)
        if asUnsigned:
            return <unsigned char>value
        return value

    cpdef int readShort(self, bint asUnsigned = False) except? -10:
        cdef short value
        cdef unsigned char byte1, byte2
        self._read(&byte1, 1)
        self._read(&byte2, 1)
        value = (byte2 << 8) | byte1
        if asUnsigned:
            return <unsigned short>value
        return value

    cpdef float readFloat(self) except? -10:
        cdef float value
        self._read(&value, 4)
        return value

    cpdef double readDouble(self) except? -10:
        cdef double value
        self._read(&value, 8)
        return value

    cpdef readInt(self, bint asUnsigned = False):
        cdef int value
        cdef unsigned char byte1, byte2, byte3, byte4
        self._read(&byte1, 1)
        self._read(&byte2, 1)
        self._read(&byte3, 1)
        self._read(&byte4, 1)
        value = ((byte4 << 24) | (byte3 << 16) | (byte2 << 8) | byte1)
        if asUnsigned:
            return <unsigned int>value
        return value

    cpdef bytes readString(self, size=None):
        if size is not None:
            return self.readReader(size).readString()
        data = ''
        while 1:
            c = self.read(1)
            if c in ('\x00', ''):
                break
            data += c
        return data

    cpdef unicode readUnicodeString(self, size=None):
        if size is not None:
            return self.readReader(size*2).readUnicodeString()

        cdef int currentPosition = self.tell()
        cdef int endPosition
        data = ''
        while 1:
            endPosition = self.tell()
            c = self.read(2)
            if len(c) != 2:
                break
            if c == '\x00\x00':
                break
            data += c

        return data.decode('utf-16-le')

    cpdef tuple readColor(self):
        cdef int currentPosition = self.tell()
        cdef short r = self.readByte(True)
        cdef short g = self.readByte(True)
        cdef short b = self.readByte(True)
        self.skipBytes(1)
        return (r, g, b)

    cpdef ByteReader readReader(self, size_t size):
        cdef ByteReader reader

        IF IS_PYPY:
            if self.python_fp:
                data = self.read(size)
                reader = ByteReader(data, 0, len(data))
                return reader
        ELSE:
            if self.fp != NULL:
                data = self.read(size)
                reader = ByteReader(data, 0, len(data))
                return reader

        check_available(self, size)
        self.shared = True
        reader = ByteReader(self.original, self.pos + self.start, size)
        self.pos += size
        return reader

    def readIntString(self):
        cdef size_t length = self.readInt(True)
        return self.read(length)

    cpdef bint write(self, bytes data):
        cdef size_t size = len(data)
        if size == 0:
            return False
        cdef char * c_data

        IF IS_PYPY:
            if self.python_fp:
                self.python_fp.write(data)
                return True
        ELSE:
            if self.fp != NULL:
                fwrite(<char *>data, 1, size, self.fp)
                return True

        ensure_write_size(self, size)
        c_data = data
        memcpy((self.buffer + self.pos), c_data, size)
        self.pos += size
        return True

    cpdef bint write_size(self, char * data, size_t size):
        if size == 0:
            return False

        IF IS_PYPY:
            if self.python_fp:
                self.python_fp.write(buffer(data, 0, size))
                return True
        ELSE:
            if self.fp != NULL:
                fwrite(data, 1, size, self.fp)
                return True

        ensure_write_size(self, size)
        memcpy((self.buffer + self.pos), data, size)
        self.pos += size
        return True

    def writeByte(self, value, asUnsigned = False):
        format = UBYTE if asUnsigned else BYTE
        self.writeStruct(format, value)

    def writeShort(self, value, asUnsigned = False):
        format = USHORT if asUnsigned else SHORT
        self.writeStruct(format, value)

    def writeFloat(self, value):
        self.writeStruct(FLOAT, value)

    def writeDouble(self, value):
        self.writeStruct(DOUBLE, value)

    def writeInt(self, value, asUnsigned = False):
        format = UINT if asUnsigned else INT
        self.writeStruct(format, value)

    def writeString(self, value, size_t size = -1):
        cdef unsigned int currentPosition
        if size == -1:
            self.write(value + "\x00")
        else:
            for i in range(size):
                self.writeByte(0)
            currentPosition = self.tell()
            self.rewind(size)
            self.write(value[:size-1])
            self.seek(currentPosition)

    def writeUnicodeString(self, value):
        self.write(value.encode('utf-16-le') + "\x00\x00")

    def writeColor(self, colorTuple):
        r, g, b = colorTuple
        self.writeByte(r, True)
        self.writeByte(g, True)
        self.writeByte(b, True)
        self.writeByte(0)

    def writeFormat(self, format, *values):
        self.write(struct.pack(format, *values))

    def writeStruct(self, structType, *values):
        self.write(structType.pack(*values))

    def writeReader(self, reader):
        self.write(reader.data())

    def writeIntString(self, value):
        self.writeInt(len(value), True)
        self.write(value)

    cpdef bint skipBytes(self, size_t n):
        self.seek(n, 1)

    cpdef bint rewind(self, size_t n):
        self.seek(-n, 1)

    def truncate(self, value):
        self.buffer.truncate(value)

    def checkDefault(self, value, *defaults):
        return checkDefault(self, value, *defaults)

    def openEditor(self):
        cdef object name
        if self.python_fp:
            name = self.python_fp.name
        else:
            fp = tempfile.NamedTemporaryFile('wb', delete = False)
            fp.write(self.data())
            fp.close()
            name = fp.name

        try:
            raw_input('Press enter to open hex editor...')
            openEditor(name, self.tell())
        except IOError:
            pass
        raw_input('(enter)')
    
    # New aera
    @contextlib.contextmanager
    def save_current_pos(self):
        entry = self.tell1()
        yield
        self.seek1(entry)

    def __bool1__(self):
        return self.tell1() < self.size1()

    def __int1__(self):
        return self.size1()

    def __repr1__(self):
        return "<byteio {}/{}>".format(self.tell1(), self.size1())

    def __len1__(self):
        return self.size1()

    def close(self):
        if hasattr(self.python_fp, 'mode'):
            if 'w' in getattr(self.python_fp, 'mode'):
                self.python_fp.close()

    def rewind1(self, amount):
        self.python_fp.seek1(-amount, io.SEEK_CUR)

    def skip1(self, amount):
        self.python_fp.seek1(amount, io.SEEK_CUR)

    def seek1(self, off, pos=io.SEEK_SET):
        self.python_fp.seek1(off, pos)

    def tell1(self):
        return self.python_fp.tell1()

    def size1(self):
        curr_offset = self.tell1()
        self.seek1(0, io.SEEK_END)
        ret = self.tell1()
        self.seek1(curr_offset, io.SEEK_SET)
        return ret

    def fill1(self, amount):
        for _ in range(amount):
            self._write1('\x00')

    # ------------ PEEK SECTION ------------ #

    def _peek1(self, size=1):
        with self.save_current_pos():
            return self._read1(size)

    def peek1(self, t):
        size = struct.calcsize(t)
        return struct.unpack(t, self._peek1(size))[0]

    def peek_fmt(self, fmt):
        size = struct.calcsize(fmt)
        return struct.unpack(fmt, self._peek1(size))

    def peek_uint64(self):
        return self.peek1('Q')
    
    def peek_int64(self):
        return self.peek1('q')

    def peek_uint32(self):
        return self.peek1('I')

    def peek_int32(self):
        return self.peek1('i')

    def peek_uint16(self):
        return self.peek1('H')

    def peek_int16(self):
        return self.peek1('h')

    def peek_uint8(self):
        return self.peek1('B')

    def peek_int8(self):
        return self.peek1('b')

    def peek_float(self):
        return self.peek1('f')

    def peek_double(self):
        return self.peek1('d')

    def peek_fourcc(self):
        with self.save_current_pos():
            return self.read_ascii_string(4)

    # ------------ READ SECTION ------------ #

    def _read1(self, size=-1):
        return self.python_fp.read1(size)

    def read1(self, t):
        size = struct.calcsize(t)
        return struct.unpack(t, self._read1(size))[0]

    def read_fmt(self, fmt):
        size = struct.calcsize(fmt)
        return struct.unpack(fmt, self._read1(size))

    def read_uint64(self):
        return self.read1(u'Q')

    def read_int64(self):
        return self.read1(u'q')

    def read_uint32(self):
        return self.read1(u'I')

    def read_int32(self):
        return self.read1(u'i')

    def read_uint16(self):
        return self.read1(u'H')

    def read_int16(self):
        return self.read1(u'h')

    def read_uint8(self):
        return self.read1(u'B')

    def read_int8(self):
        return self.read1(u'b')

    def read_float(self):
        return self.read1(u'f')

    def read_double(self):
        return self.read1(u'd')

    def read_wide_string(self, length=None):
        if length:
            return bytes(''.join([unichr(self.read_uint16()) for _ in range(length)]), u'utf').strip('\x00').decode(u'utf')

        acc = ''
        b = self.read_uint16()
        while b != 0:
            acc += chr(b)
            b = self.read_uint16()
        return acc

    def read_ascii_string(self, length=None):
        if length:
            return byts(''.join([unichr(self.read_uint8()) for _ in range(length)]), u'utf').strip('\x00').decode(u'utf')

        acc = u''
        b = self.read_uint8()
        while b != 0:
            acc += chr(b)
            b = self.read_uint8()
        return acc

    def read_fourcc(self):
        return self.read_ascii_string(4)

    def read_from_offset(self, offset, reader, **reader_args):
        if offset > self.size1():
            raise OffsetOutOfBounds()
        # curr_offset = self.tell()
        with self.save_current_pos():
            self.seek1(offset, io.SEEK_SET)
            ret = reader(**reader_args)
        # self.seek(curr_offset, io.SEEK_SET)
        return ret

    # ------------ WRITE SECTION ------------ #

    def _write1(self, data):
        self.python_fp.write(data)

    def write1(self, t, value):
        self._write1(struct.pack(t, value))

    def write_uint64(self, value):
        self.write1(u'Q', value)

    def write_int64(self, value):
        self.write1(u'q', value)

    def write_uint32(self, value):
        self.write1(u'I', value)

    def write_int32(self, value):
        self.write1(u'i', value)

    def write_uint16(self, value):
        self.write1(u'H', value)

    def write_int16(self, value):
        self.write1(u'h', value)

    def write_uint8(self, value):
        self.write1(u'B', value)

    def write_int8(self, value):
        self.write1(u'b', value)

    def write_float(self, value):
        self.write1(u'f', value)

    def write_double(self, value):
        self.write1(u'd', value)

    def write_ascii_string(self, string,size = 0, zero_terminated=True):
        entry = self.tell1()
        for c in string:
            self._write1(c.encode('ascii'))
        if zero_terminated:
            self._write1(b'\x00')
        if size and self.tell1()-entry<size:
            bytes_written = self.tell1()-entry
            self._write1(b'\x00'*(size-bytes_written))


    def write_fourcc(self, fourcc):
        self.write_ascii_string(fourcc)

    def write_to_offset(self, offset, writer, value, fill_to_target=False):
        if offset > self.size1() and not fill_to_target:
            raise OffsetOutOfBounds()
        curr_offset = self.tell()
        self.seek1(offset, io.SEEK_SET)
        ret = writer(value)
        self.seek1(curr_offset, io.SEEK_SET)
        return ret

    def read_bytes(self, size=-1):
        return self._read1(size)

    def read_float16(self):
        return self.read1('e')

    def write_bytes(self, data):
        self._write1(data)

    def decompress_block(self, size, decompressed_size, as_reader=False):
        data = self._read1(size)
        data = zlib.decompress(data)
        assert len(data) == decompressed_size
        if as_reader:
            return ByteReader(byte_object=data)
        else:
            return data

    def auto_decompress(self, as_reader=False):
        decomp_size = self.read_int32()
        comp_size = self.read_int32()
        return self.decompress_block(comp_size, decomp_size, as_reader)

    def check(self, size):
        return self.size1() - self.tell1() >= size

    def write_fmt(self,fmt, data):
        self.write1(fmt,data)

def openEditor(filename, position):
    return subprocess.Popen(['010editor', '%s@%s' % (filename, position)])

def checkDefault(ByteReader reader, value, *defaults):
    if value in defaults:
        return False
    cdef int lastPosition = reader.lastPosition
    cdef size_t size = reader.tell() - lastPosition
    reprDefaults = defaults
    if len(defaults) == 1:
        reprDefaults, = defaults
    cdef str message = ('unimplemented value at %s, size %s (should be '
        '%s but was %s)' % (lastPosition, size, reprDefaults, value))
    traceback.print_stack(file=sys.stdout)
    # print message
    if sys.stdin.isatty():
        reader.openEditor()
    raise SystemExit