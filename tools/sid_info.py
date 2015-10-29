#!/usr/bin/python
# ----------------------------------------------------------------------------
# Shows SID info - riq
# ----------------------------------------------------------------------------
'''
Little tool to display SID info
'''
from __future__ import division, unicode_literals, print_function
import sys
import os
import struct


__docformat__ = 'restructuredtext'


def print_header(header, v1, flags, addr):
    print("Header: %s, Version: %d (Offset: $%04x)" % (header, v1[0], v1[1]))
    print("Load Address: $%04x ($%04x)" % (v1[2], addr))
    print("Init Address: $%04x" % v1[3])
    print("Play Address: $%04x" % v1[4])
    print("Songs: %d / Start Song: %d" % (v1[5], v1[6]))
    print("Speed: %s" % format(v1[7], '#032b'))
    print("Title: %s" % v1[8].decode('utf8', 'ignore'))
    print("Author: %s" % v1[9].decode('utf8', 'ignore'))
    print("Released: %s" % v1[10].decode('utf8', 'ignore'))

    if flags is not None:
        str_flags = ''

        if flags & 0b00000001:
            str_flags += 'Compute! Sidplayer mus data'
        else:
            str_flags += 'Built-in music player'

        if (flags & 0b00000010) >> 1:
            str_flags += ', PlaySID specific'
        else:
            str_flags += ', C64 compatible'

        f = (flags & 0b00001100) >> 2
        if f == 0:
            str_flags += ', Unknown'
        elif f == 1:
            str_flags += ', PAL'
        elif f == 2:
            str_flags += ', NTSC'
        elif f == 3:
            str_flags += ', PAL & NTSC'

        f = (flags & 0b00110000) >> 4
        if f == 0:
            str_flags += ', Unknown'
        elif f == 1:
            str_flags += ', 6581'
        elif f == 2:
            str_flags += ', 8580'
        elif f == 3:
            str_flags += ', 6581 & 8580'

        print("Flags: %s" % str_flags)
    print()

    
def run(sid_file):
    f = open(sid_file)
    buf = f.read()

    header = buf[0:4]
    if header == 'PSID' or header == 'RSID':
        print("File: %s" % sid_file)
        v1 = struct.unpack_from(">HHHHHHHI32s32s32s", buf, 4)
        flags = None
        addr = struct.unpack_from("<H", buf, 0x76)[0]

        # version 2
        if v1[0] == 2:
            flags = struct.unpack_from(">H", buf, 118)[0]
            addr = struct.unpack_from("<H", buf, 0x7c)[0]

        print_header(header, v1, flags, addr)
    else:
        print("%s - Not a valid SID file" % sid_file)

    f.close()


def help():
    print("%s v0.1 - An tool to print SID info\n" % os.path.basename(sys.argv[0]))
    print("Example:\n%s *.sid" % os.path.basename(sys.argv[0]))
    sys.exit(-1)


if __name__ == "__main__":
    if len(sys.argv) == 1:
        help()

    for f in sys.argv[1:]:
        run(f)
