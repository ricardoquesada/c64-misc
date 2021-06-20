#!/usr/bin/python3

import subprocess
import sys

# Ignore first argument which is "self"
for name in sys.argv[1:]:
    print(name)
    subprocess.run(("c1541", name, "-list"))
    print("\n")
