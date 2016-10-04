#!/usr/bin/python
# ----------------------------------------------------------------------------
# copy files usinb opencbm
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
    for line in lines[1:-2]:
        print(line)
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
    return files

def run(drive, directory):
    if not os.path.exists(directory):
        os.makedirs(directory)

    subprocess.call(['cbmctrl','reset'])

    p = subprocess.Popen(['cbmctrl', 'dir', drive], stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    output, err = p.communicate(b"input data that is passed to subprocess' stdin")
    rc = p.returncode
    files = parse_files(output)
    cwd = os.getcwd()
    os.chdir(directory)
    imaged64 = directory + '.d64'
    subprocess.call(['c1541','-format', directory+',82', 'd64', imaged64])
    for name in files:
        print("Copying %s" % name)
        subprocess.call(['cbmread', drive, name, '-o', name])
        subprocess.call(['c1541', imaged64, '-write', name])
    subprocess.call(['c1541','-list'])
    os.chdir(cwd)

def help():
    print("%s v0.1 - Utility to copy files using opencbm\n" % os.path.basename(sys.argv[0]))
    print("Example:\n%s 8 directory_name" % os.path.basename(sys.argv[0]))
    sys.exit(-1)


if __name__ == "__main__":
    if len(sys.argv) != 3:
        help()

    run(*sys.argv[1:])

