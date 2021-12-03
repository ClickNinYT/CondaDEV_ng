import sys
sys.path.append('..')

from mmfparser.data.exe import ExecutableData
from mmfparser.data.gamedata import GameData
from mmfparser.data.mfa import MFA
from mmfparser.translators.pame2mfa import translate
from mmfparser.bytereader import ByteReader
from misc import *

import sys
import os
import string
import os.path 

def main():
    log("CondaDEV Decompiler (rev 1.0)", 1)
    log("By ClickNin, pete7201 and 1987kostya - Only for Educational Purposes", 1)
    try:
       input = sys.argv[1]
    except:
        log("Error: No EXE Specified!", 0)
        exit()
    try:
       output = sys.argv[2]
    except:
        log("Warning: No output directory specified!", 3)
        log("Warning: Defaulting to C:\Out...", 3)
        output = "C:\Out"
        pass
    def checks():
        path = output
        isdir = os.path.isdir(path)
        if isdir == True:
            log("Output Directory Check Passed!", 1)
            pass
        else:
            log("Warning: Output Directory Not Exist, Creating...", 3)
            os.makedirs(output)
            log("Output Directory Check Passed!", 1)
            pass
    def exe_checks():
        if input.endswith('.ccn') or input.endswith('.exe'):
            pass
        else:
            log("Error: Input is not an vaild EXE or CCN file!", 0)
            exit()
    #run check out directory and check exe availablity
    exe_checks()
    checks()
    fp = ByteReader(open(input, 'rb'))
    if input.endswith('.ccn'):
        newGame = GameData(fp)
    else:
        newExe = ExecutableData(fp, loadImages=True)

        for file in newExe.packData.items:
            name = file.filename.split('\\')[-1]
            log('Dumping packed file %r' % name + '...', 1)
            open(os.path.join(output, name), 'wb').write(file.data)

        newGame = newExe.gameData

    if newGame.files is not None:
        for file in newGame.files.items:
            name = file.name.split('\\')[-1]
            log('Dumping embedded file %r' % name + '...', 1)
            open(os.path.join(output, name), 'wb').write(str(file.data))
    newGame.files = None

    def out(value):
        log(value, 1)
    log('Translating MFA...', 1)
    newMfa = translate(newGame, print_func = out)
    s = newGame.name
    whitelist = string.letters + string.digits
    new_s = ''
    for char in s:
        if char in whitelist:
            new_s += char
    log("Application Name: " + new_s, 1)
    out_path = os.path.join(output, new_s + '.mfa')
    log('Writing MFA...', 1)
    newMfa.write(ByteReader(open(out_path, 'wb')))

    # newMfa = MFA(ByteReader(open(out_path, 'rb')))
    log('Decompilation Finished!', 1)

if __name__ == '__main__':
    main()
