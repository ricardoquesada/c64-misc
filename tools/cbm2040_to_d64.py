#!/usr/bin/python
# ----------------------------------------------------------------------------
# copy CBM2040 formatted disks to d64 images
# ----------------------------------------------------------------------------
'''
Little tool to display SID info
'''
from __future__ import division, unicode_literals, print_function
import sys
import os
import struct
import subprocess
import re


__docformat__ = 'restructuredtext'


def parse_files(output):
    files = []
    lines = output.split('\n')
    print(output)
    for line in lines[1:-2]:
#        r = re.match("\s*(\d*)\s*(\"\.*\")\s*prg\s*",line)
        r = re.match("\s*(\d*).*\"(.*)\".*(\w\w\w).*",line)
        if r is not None:
            name = r.group(2)
            ext = r.group(3)
            if ext == "seq":
                name = name + ",s"
            elif ext == "del":
                name = name + ",d"
            elif ext == "usr":
                name = name + ",u"
            elif ext == "rel":
                name = name + ",l"
            files.append(name)
    # title
    r = re.match(".*\"(.*)\" (..).*",lines[0])
    title = r.group(1) + "," + r.group(2)

    # blocks free
    r = re.match("\s*(\d*).*", lines[-2])
    blocks_free = int(r.group(1))
    fmt = 'd64'
    # it seems that 2040-formatted disks have 6 more blocks than d64
    # use d71 when needed
    if blocks_free <= 6:
        fmt = 'd71'
    return title,files,fmt


def run(drive, directory):
    if not os.path.exists(directory):
        os.makedirs(directory)

    subprocess.call(['cbmctrl','reset'])

    p = subprocess.Popen(['cbmctrl', 'dir', drive], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, err = p.communicate(b"input data that is passed to subprocess' stdin")
    rc = p.returncode
    title,files,fmt = parse_files(output)
    cwd = os.getcwd()
    os.chdir(directory)
    imaged82 = directory + '.' + fmt
    subprocess.call(['c1541','-format', title, fmt, imaged82])
    for name in files:
        print("Copying %s" % name)
        # can't read files that contians the: '(.)'
        name_fixed = name.replace("(.)", "(?)")
        subprocess.call(['cbmread', '-q', drive, name_fixed, '-o', name])
        # cbmread will write replace '/' with '_' when creating files
        name_fixed = name.replace('/','_')
        subprocess.call(['c1541', imaged82, '-write', name_fixed, name])
    subprocess.call(['c1541', imaged82, '-list'])
    os.chdir(cwd)


def help():
    print("%s v0.1 - Utility to copy CBM2040-formatted floppy disk to d64/d71 images\n" % os.path.basename(sys.argv[0]))
    print("Example:\n%s 8 directory_name" % os.path.basename(sys.argv[0]))
    sys.exit(-1)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        help()

    run(*sys.argv[1:])

