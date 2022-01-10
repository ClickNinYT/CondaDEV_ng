import sys
sys.path.append('..')

from mmfparser.data.exe import ExecutableData
from mmfparser.data.gamedata import GameData
from mmfparser.data.mfa import MFA
from mmfparser.translators.pame2mfa import translate
from mmfparser.bytereader import ByteReader
from mmfparser.data.chunkloaders.imagebank import *
from mmfparser.loader import DataLoader
from misc import *

import sys
import os
import string
import os.path
                                                                                                                                                                                                                                                                                                                                                                                        
def main(opt):
    if opt == 0:
        log("decompile <game path> <output path>: Decompile a game", 2)
        exit()
    elif opt == 1:
        decompile()
    else:
        log("Error: Invaild option provided!", 0)
        exit()

def decompile():
    try:
       input = sys.argv[2]
    except:
        log("Error: No EXE Specified!", 0)
        exit()
    try:
       output1 = sys.argv[3]
    except:
        log("Warning: No output directory specified!", 3)
        log("Warning: Defaulting to C:\Out...", 3)
        output1 = "C:\Out"
        pass
    def checks():
        path = output1
        isdir = os.path.isdir(path)
        if isdir == True:
            #log("Output Directory Check Passed!", 1)
            pass
        else:
            #log("Warning: Output Directory Not Exist, Creating...", 3)
            os.makedirs(output1)
            #log("Output Directory Check Passed!", 1)
            pass

    def checks_custom(path1):
        path = path1
        isdir = os.path.isdir(path)
        if isdir == True:
            #log("Output Directory Check Passed!", 1)
            pass
        else:
            #log("Warning: Output Directory Not Exist, Creating...", 3)
            os.makedirs(path1)
            #log("Output Directory Check Passed!", 1)
            pass
    
    if input.endswith('.ccn'):
        #fp = ByteReader(open(input, 'rb'))
        #newGame = GameData(fp)
        log("Error: CCN Decompilation is not supported for now!", 0)
        exit()
    elif input.endswith('.apk'):
        #fp = ByteReader(open(input, 'rb'))
        #newGame = GameData(fp)
        log("Error: APK Decompilation is not supported for now!", 0)
        exit()
    elif input.endswith('.ipa'):
        #fp = ByteReader(open(input, 'rb'))
        #newGame = GameData(fp)
        log("Error: IPA Decompilation is not supported for now!", 0)
        exit()
    elif input.endswith('.exe'):
        fp = ByteReader(open(input, 'rb'))
        newExe = ExecutableData(fp, loadImages=True)
    else:
        log("Error: Unsupported file!", 0)
        exit()
    
    newGame = newExe.gameData

    s1 = newGame.name
    whitelist1 = string.letters + string.digits
    new_s1 = ''
    for char in s1:
        if char in whitelist1:
            new_s1 += char

    output_p = new_s1
    output = os.path.join(output1, output_p)
    checks_custom(output)

    for file in newExe.packData.items:
        name = file.filename.split('\\')[-1]
        log('Dumping packed file %r' % name + '...', 1)
        open(os.path.join(output, name), 'wb').write(file.data)

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
    try:
       option = sys.argv[1]
    except IndexError:
        log("Error: You must provide an option!", 0)
        log("Use 'help' option to get a list of available option.", 3)
        exit()
    if option == "help":
        main(0)
    elif option == "decompile":
        main(1)
    else:
        log("Error: Invaild option provided!", 0)
        exit()
    
