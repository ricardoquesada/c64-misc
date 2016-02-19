#!/usr/bin/python
# ----------------------------------------------------------------------------
# converts .sid to .exo (crunched exomizer)
# ----------------------------------------------------------------------------
'''
Little tool to display SID info
'''
from __future__ import division, unicode_literals, print_function
import sys
import os
import struct
import subprocess


__docformat__ = 'restructuredtext'


def run(sid_file):
    basename = os.path.splitext(sid_file)[0]
    prg_file = basename + ".prg"
    exo_file = basename + ".exo"
    print("Converting %s to %s" % (sid_file, exo_file))
    
    subprocess.call(['dd','bs=1','skip=124', 'if=%s' % sid_file, 'of=%s' %  prg_file])
    subprocess.call(['exomizer', 'mem', prg_file, '-q', '-o', exo_file])


def help():
    print("%s v0.1 - Utility tha converts .sid to .exo (crunched exomizer) files\n" % os.path.basename(sys.argv[0]))
    print("Example:\n%s *.sid" % os.path.basename(sys.argv[0]))
    sys.exit(-1)


if __name__ == "__main__":
    if len(sys.argv) == 1:
        help()

    for f in sys.argv[1:]:
        run(f)
