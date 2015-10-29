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


def analyze_sidtracker64(v1, buf):
    # Sidtracker64 is v2 first 8 bytes
    #   jmp 0x1826          ; 3 bytes
    #   ldx #0x00           ; 2 bytes
    #   jsr 0x17f8          ; 3 bytes...
    #   ignore the first 6 bytes then until we get to the '0x17f8'
    address = struct.unpack_from("<H", buf, 0x7e + 6)[0]

    # In "17f8" we should have something like
    #   lda 0x1874,x        ; 1874 - 4 is where all the shadow variables are
    #   and 0x189f,x        ; 189f, 189f + 7 and 189f+14 are where the gates varaibles are
    init_address = v1[3]
    diff = address - init_address
    addresses = struct.unpack_from("<xHxH", buf, 0x7e + diff)
    print("SidTracker64 info:")
    print("  Shadow variables: $%04x - $%04x" % (addresses[0] - 4, addresses[0] + 19))
    print("  Gate variables: $%04x, $%04x, $%04x" % (addresses[1], addresses[1] + 7, addresses[1] + 14))

    freq_offset = len(buf) - 0x7e - 215
    print("  Freq. PAL table lo/hi: $%04x / $%04x" % (v1[3] + freq_offset, v1[3] + freq_offset + 96))


def print_header(header, v1, flags, addr):
    print("Header: %s, Version: %d (Offset: $%04x)" % (header, v1[0], v1[1]))
    print("Load Address: $%04x ($%04x)" % (v1[2], addr))
    print("Init Address: $%04x" % v1[3])
    print("Play Address: $%04x" % v1[4])
    print("Songs: %d / Start Song: %d" % (v1[5], v1[6]))
    print("Speed: %s" % format(v1[7], '#032b'))
    print("Title: %s" % v1[8].decode('utf8', 'ignore').rstrip('\x00'))
    print("Author: %s" % v1[9].decode('utf8', 'ignore').rstrip('\x00'))
    print("Released: %s" % v1[10].decode('utf8', 'ignore').rstrip('\x00'))

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

        if 'SidTracker64' in v1[9].decode('utf8','ignore'):
            analyze_sidtracker64(v1, buf)
    else:
        print("%s - Not a valid SID file" % sid_file)

    f.close()
    print("\n")


def help():
    print("%s v0.1 - An tool to print SID info\n" % os.path.basename(sys.argv[0]))
    print("Example:\n%s *.sid" % os.path.basename(sys.argv[0]))
    sys.exit(-1)


if __name__ == "__main__":
    if len(sys.argv) == 1:
        help()

    for f in sys.argv[1:]:
        run(f)
