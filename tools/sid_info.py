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

reload(sys)
sys.setdefaultencoding('utf8')


__docformat__ = 'restructuredtext'


def analyze_sidtracker64(v1, buf):
    # Sidtracker64 v2 first 8 bytes
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

    # [$1001]
    real_init_address = struct.unpack_from("<H", buf, 0x7e + 1)

    # [$1001 will something like this: we only care about bytes 1 and 3
    # lda #0x73         ; 2 bytes
    # ldx #0x89         ; 2 bytes
    # sta 0xdc04        ; 3 bytes
    # stx 0xdc05        ; 3 bytes

    real_init_address = struct.unpack_from("<H", buf, 0x7e + 1)[0]
    freq = struct.unpack_from("<xBxB", buf, 0x7e + real_init_address - 0x1000)
    pal_freq = freq[0] + freq[1] * 256
    ntsc_freq = ((pal_freq+1) * 1022727 / 985248) - 1
    paln_freq = ((pal_freq+1) * 1023440 / 985248) - 1
    freq_hz =  985248 / pal_freq

    print("  Play Frequency: ~%.2fhz" % freq_hz)
    print("  CIA Timer PAL: $%04x" % pal_freq)
    print("  CIA Timer NTSC: $%04x" % ntsc_freq)
    print("  CIA Timer PAL-N: $%04x" % paln_freq)


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

def print_freq_tables(v1, load_addr, buf):
    offset = v1[1]

    array = buf[offset+2:-1]

    lo_freqs = [
            b'\x16\x27\x38\x4b\x5f',    # PAL
            b'\x16\x27\x38\x4b\x5e',    # PAL
            b'\x16\x27\x39\x4b\x5f',    # PAL
            b'\x17\x27\x39\x4b\x5f',    # PAL

            b'\x0c\x1c\x2d\x3e\x51',    # NTSC
            b'\x0c\x1c\x2d\x3f\x52',    # NTSC
            b'\x0c\x1c\x2d\x3e\x47',    # NTSC
           ]

    hi_freqs = [
            # with 12 '01's
            b'\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x02\x02',    # PAL
            # with 11 '01's
            b'\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x01\x02\x02\x02',
           ]


    f_lo = None
    f_hi = None
    f_type = 'PAL'

    # try to find lo freq table
    for i,lo in enumerate(lo_freqs):
        found = array.find(lo)
        if found != -1:
            f_lo = found
            if i >= 4:
                f_type = 'NTSC'
            break

    for hi in hi_freqs:
        found = array.find(hi)
        if found != -1:
            f_hi = found
            break

    if f_lo and f_hi:
        print("Freq table addr (lo/hi): $%04x / $%04x (%s)" % (load_addr + f_lo, load_addr + f_hi, f_type))
    else:
        print("Freq table addr: not found")


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
        print_freq_tables(v1, addr, buf)

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
