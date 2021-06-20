#!/usr/bin/python3

import subprocess
import sys

# Ignore first argument which is "self"
for name in sys.argv[1:]:
    print(name)
    out = subprocess.check_output(("c1541", name, "-list"))
    print(out.decode("utf-8"))
    print("\n")
