import sys
import os
from datetime import datetime
import subprocess
import struct

def log(str, col):
    subprocess.call('', shell=True)
    time = datetime.now().strftime('%H:%M:%S')
    log = '[' + time + ']' + ' ' + str
    class colors:
        default = '\033[0m'
        green = '\033[92m'
        yellow = '\033[93m'
        red = '\033[91m'
    if col == 0:
       col = colors.red
    elif col == 1:
       col = colors.green
    elif col == 2:
       col = colors.default
    elif col == 3:
       col = colors.yellow
    else:
       print colors.red + '[' + time + ']' + ' ' + 'Invaild color specified!' + colors.default
       exit()
    cl = colors.default
    print col + log + cl

def CheckArch():
    ar = 8 * struct.calcsize("P")
    if ar == 32:
        arc = 32
        return arc
    elif ar == 64:
        arc = 64
        return arc
    else:
        arc = 0
        return arc
