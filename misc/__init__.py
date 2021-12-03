import sys
import os
from colorama import init
from colorama import Fore, Back, Style
from datetime import datetime

init()

def log(str, col):
    time = datetime.now().strftime('%H:%M:%S')
    log = '[' + time + ']' + ' ' + str  
    if col == 0:
       col = Fore.RED
    elif col == 1:
       col = Fore.GREEN
    elif col == 2:
       col = Style.RESET_ALL
    elif col == 3:
       col = Fore.YELLOW
    else:
       print Fore.RED + '[' + time + ']' + ' ' + 'Invaild color specified!'
       exit()
    print col + log
   
