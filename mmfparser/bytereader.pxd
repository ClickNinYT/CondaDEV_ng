from libc.stdio cimport FILE

cdef class ByteReader:
    cdef unsigned char * buffer
    cdef unsigned int start, pos, data_size, lastPosition
    cdef bytes original
    cdef bint shared

    IF not IS_PYPY:
        cdef FILE * fp

    cdef object python_fp

    cpdef int tell(self)
    cpdef data(self)
    cpdef bint seek(self, int pos, int mode = ?)
    cpdef read(self, int size = ?)
    cpdef adjust(self, int to)
    cpdef size_t size(self)
    cpdef short readByte(self, bint asUnsigned = ?) except? -10
    cpdef int readShort(self, bint asUnsigned = ?) except? -10
    cpdef float readFloat(self) except? -10
    cpdef double readDouble(self) except? -10
    cpdef readInt(self, bint asUnsigned = ?)
    cpdef bytes readString(self, size=?)
    cpdef unicode readUnicodeString(self, size=?)
    cpdef tuple readColor(self)
    cpdef ByteReader readReader(self, size_t size)
    cpdef bint write(self, bytes data)
    cpdef bint write_size(self, char * data, size_t size)
    cpdef bint skipBytes(self, size_t n)
    cpdef bint rewind(self, size_t n)
    cdef bint _read(self, void * value, int size) except False
