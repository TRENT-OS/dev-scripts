#!/usr/bin/env python

################################################################################
#
# A script to list all USB serial ports
#
# Author: Axel Heider, axelheider(_at_)gmx.de
# Created:     2015-Apr-05
# Last Change: 2016-May-28
#
# License: Creative Commons, CC-BY-NC-SA 3.0/de
#          German:  http://creativecommons.org/licenses/by-nc-sa/3.0/de/
#          General: http://creativecommons.org/licenses/by-nc-sa/3.0/
#
# This script is based on stuff found in the internet. Thanks to everybody who
# published something. Tested with Mint and Ubuntu
#
################################################################################

import os

#-------------------------------------------------------------------------------
def find_ttyUSB(idVendor, idProduct):
    # find_tty_usb('067b', '2302') -> '/dev/ttyUSB0'
    DEV_DIR='/sys/bus/usb/devices'
    for dnBase in os.listdir(DEV_DIR):
        dn = os.path.join(DEV_DIR, dnBase)
        if not os.path.exists(join(dn, 'idVendor')):
            continue
        idVID = open(join(dn, 'idVendor')).read().strip()
        if idVID != idVendor:
            continue
        idPID = open(join(dn, 'idProduct')).read().strip()
        if idPID != idProduct:
            continue
        for subdir in os.listdir(dn):
            if subDir.startswith(dnBase+':'):
                for subSubDir in os.listdir(join(dn, subDir)):
                    if subSubDir.startswith('ttyUSB'):
                        return os.path.join('/dev', subSubDir)

#-------------------------------------------------------------------------------
def splitPathIntoArray(path):
    elements = []
    while ((path != '/') and (path != '')):
        path, tail = os.path.split(path)
        elements.insert(0,tail)
    return elements

#-------------------------------------------------------------------------------
def getParentDir(path, level=1):
    while (level > 0):
        path = os.path.dirname(path)
        level -= 1
    return path

#-------------------------------------------------------------------------------
def getIdFromFile(path,idFile):
    id = -1
    while ((path != '/') and (path != '')):

        idFileFullPath = os.path.join(path,idFile)
        if not os.path.isfile(idFileFullPath):
            path = getParentDir(path)
            continue

        with open(idFileFullPath) as f:
            content = f.read().splitlines()
            id = int(content[0])

        break

    return id

#-------------------------------------------------------------------------------
def getBusNum(path):
    ret = -1
    while ((path != '/') and (path != '')):
        devNumFile = os.path.join(path,"devnum")
        if not os.path.isfile(devNumFile):
            path = getParentDir(path)
            continue
        with open(devNumFile) as f:
            devNum = f.read().splitlines()
            ret = int(devNum[0])
        break


#-------------------------------------------------------------------------------
def detect_devs():
    DEV_DIR='/sys/class/tty'
    for dnBase in os.listdir(DEV_DIR):
        if not dnBase.startswith('ttyUSB'): continue
        dn = os.path.join(DEV_DIR, dnBase)
        devPath = os.path.realpath(dn)
        p = splitPathIntoArray(devPath)

        with open(os.path.join(dn,"device","uevent")) as f:
            r = f.read().splitlines()

        devDir = getParentDir(devPath,3)

        devNum = getIdFromFile(devDir,"devnum")
        busNum = getIdFromFile(devDir,"busnum")
        driver = r[0]

        print("  %s -> %s (Bus:Dev=%03d:%03d, %s)"%
              (dnBase, p[-4],busNum,devNum,driver))


    # DEV_DIR='/sys/bus/usb-serial/devices'
    # print "via %s"%(DEV_DIR)
    # ret
    # for dnBase in os.listdir(DEV_DIR):
    #     if not dnBase.startswith('ttyUSB'):
    #         continue
    #     dn = os.path.join(DEV_DIR, dnBase)
    #     p = rec_split(os.path.realpath(dn))
    #     print "  %s -> %s"%(dnBase, p[-2])
    #
    #
    # DEV_DIR='/sys/bus/usb/devices'
    # print "via %s"%(DEV_DIR)
    # for dnBase in os.listdir(DEV_DIR):
    #     dn = os.path.join(DEV_DIR, dnBase)
    #     for subDir in os.listdir(dn):
    #         if not subDir.startswith(dnBase+':'):
    #           continue
    #         for subSubDir in os.listdir(join(dn, subDir)):
    #             if not subSubDir.startswith('ttyUSB'):
    #               continue
    #             print "  %s -> %s"%(subSubDir, subDir)

#-------------------------------------------------------------------------------
def main():
    detect_devs()

    # Laptop Modem
    #   ttyUSB0 -> 1-1.5:1.1 (Bus:Dev=001:005, DRIVER=qcserial)
    #   ttyUSB1 -> 1-1.5:1.2 (Bus:Dev=001:005, DRIVER=qcserial)
    #   ttyUSB2 -> 1-1.5:1.3 (Bus:Dev=001:005, DRIVER=qcserial)
    #
    # GPIO
    #   ttyUSB3 -> 3-1.1.5:1.0 (Bus:Dev=003:008, DRIVER=ftdi_sio)
    #   ttyUSB4 -> 3-1.1.5:1.1 (Bus:Dev=003:008, DRIVER=ftdi_sio)
    #   ttyUSB5 -> 3-1.1.5:1.2 (Bus:Dev=003:008, DRIVER=ftdi_sio)
    #   ttyUSB6 -> 3-1.1.5:1.3 (Bus:Dev=003:008, DRIVER=ftdi_sio)
    #
    #  Hardkernel Arndale:
    #   ttyUSB7 -> 3-1.1.1.2:1.0 (Bus:Dev=003:012, DRIVER=ftdi_sio)
    #
    #  Hardkernel Odroid UART/USB adapter:
    #    ttyUSB4 -> 1-1.1.5:1.0 (Bus:Dev=001:007, DRIVER=cp210x)


#-------------------------------------------------------------------------------
if __name__ == '__main__':
    main()
