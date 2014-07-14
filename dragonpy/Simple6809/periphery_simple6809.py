#!/usr/bin/env python
# encoding:utf8

"""
    DragonPy - Dragon 32 emulator in Python
    =======================================

    :created: 2013-2014 by Jens Diemer - www.jensdiemer.de
    :copyleft: 2013-2014 by the DragonPy team, see AUTHORS for more details.
    :license: GNU GPL v3 or above, see LICENSE for more details.
"""

import logging
import sys
import os
import Queue

try:
    import Tkinter
except Exception, err:
    print "Error importing Tkinter: %s" % err
    Tkinter = None

try:
    import pty # only available under Linux
    import serial # Maybe not installed
except ImportError:
    pass

from dragonpy.components.periphery import PeripheryBase, TkPeripheryBase


log = logging.getLogger("DragonPy.simple6809.Periphery")


class Simple6809PeripheryBase(PeripheryBase):
    def __init__(self, cfg):
        super(Simple6809PeripheryBase, self).__init__(cfg)
        self.read_address2func_map = {
            0xa000: self.read_acia_status, # Control/status port of ACIA
            0xa001: self.read_acia_data, # Data port of ACIA
            0xbffe: self.reset_vector,
        }
        self.write_address2func_map = {
            0xa000: self.write_acia_status, # Control/status port of ACIA
            0xa001: self.write_acia_data, # Data port of ACIA
        }

    def write_acia_status(self, cpu_cycles, op_address, address, value):
        return 0xff
    def read_acia_status(self, cpu_cycles, op_address, address):
        return 0x03

    def read_acia_data(self, cpu_cycles, op_address, address):
        if self.user_input_queue.empty():
            return 0x0

        char = self.user_input_queue.get()
        value = ord(char)
        log.info("%04x| (%i) read from ACIA-data, send back %r $%x",
            op_address, cpu_cycles, char, value
        )
        return value

    def write_acia_data(self, cpu_cycles, op_address, address, value):
        char = chr(value)
        log.info("*"*79)
        log.info("Write to screen: %s ($%x)" , repr(char), value)
        log.info("*"*79)

        if value >= 0x90: # FIXME: Why?
            value -= 0x60
            char = chr(value)
#            log.info("convert value -= 0x30 to %s ($%x)" , repr(char), value)

        if value <= 9: # FIXME: Why?
            value += 0x41
            char = chr(value)
#            log.info("convert value += 0x41 to %s ($%x)" , repr(char), value)

        self.new_output_char(char)




class Simple6809PeripherySerial(Simple6809PeripheryBase):
    """
    TODO: not working!
    """
    def __init__(self, cfg):
        super(Simple6809PeripherySerial, self).__init__(cfg)

        self.master, slave = pty.openpty()
        s_name = os.ttyname(slave)

        print "Serial name: %s" % s_name

        # http://pyserial.sourceforge.net/pyserial_api.html
        self.serial = serial.Serial(
            port=s_name, # Device name or port number number or None.
            baudrate=115200, # Baud rate such as 9600 or 115200 etc.
#             bytesize=serial.SEVENBITS, # Number of data bits. Possible values: FIVEBITS, SIXBITS, SEVENBITS, EIGHTBITS
#             parity= ... #Enable parity checking. Possible values: PARITY_NONE, PARITY_EVEN, PARITY_ODD PARITY_MARK, PARITY_SPACE
#             stopbits= ... #Number of stop bits. Possible values: STOPBITS_ONE, STOPBITS_ONE_POINT_FIVE, STOPBITS_TWO
#              timeout=0, # non-blocking mode (return immediately on read)
#              timeout=None, # wait forever
#             xonxoff= ... #Enable software flow control.
#             rtscts=True, # Enable hardware (RTS/CTS) flow control.
#             dsrdtr= ... #Enable hardware (DSR/DTR) flow control.
#             writeTimeout= ... #Set a write timeout value.
#             interCharTimeout= ... #Inter-character timeout, None to disable (default).
        )
        log.log(100, repr(self.serial.getSettingsDict()))
        print "Please connect, e.g.: 'screen %s'" % s_name
        print "(ENTER to continue!)"
        sys.stdout.flush() # for eclipse :(
        raw_input()

        self.serial.write("Welcome to DragonPy") # write to pty
        self.serial.flush() # wait until all data is written


    def read_rs232_interface(self, cpu_cycles, op_address, address):
        """
        $00   0  NUL (Null Prompt)
        $01   1  SOH (Start of heading)
        $02   2  STX (Start of Text)
        $03   3  ETX (End of Text)
        $04   4  EOT (End of transmission)
        $05   5  ENQ (Enqiry)
        $06   6  ACK (Acknowledge)
        $07   7  BEL (Bell)
        $08   8  BS  (Backspace)
        $09   9  HT  (Horizontal Tab)
        $0a  10  LF  (LineFeed)
        $0b  11  VT  (Vertical Tab)
        $0c  12  FF  (Form Feed)
        $0d  13  CR  (Carriage Return)
        $0e  14  SO  (Shift Out)
        $0f  15  SI  (Shift In)
        $10  16  DLE (Data link Escape)
        $11  17  DC1 (X-On)
        $12  18  DC2 (X-On)
        $13  19  DC3 (X-Off)
        $14  20  DC4 (X-Off)
        $15  21  NAK (No Acknowledge)
        $16  22  SYN (Synchronous idle)
        $17  23  ETB (End transmission blocks)
        $18  24  CAN (Cancel)
        $19  25  EM  (End of Medium)
        $1a  26  SUB (Substitute)
        $1b  27  ESC (Escape)
        $1c  28  FS  (File Separator)
        $1d  29  GS  (Group Separator)
        $1e  30  RS  (Record Seperator)
        $1f  31  US  (Unit Seperator)
        $20  32  BLA (Blank)
        """
        log.info("%04x| (%i) read from RS232 address: $%x",
            op_address, cpu_cycles, address,
        )
        if address == 0xa000:
            return 0x02


#         char = self.serial.read()
        char = os.read(self.master, 1) # read from pty
        if char == "":
            value = 0x0
        else:
            value = ord(char)

        log.info("%04x| (%i) get from RS232 (address: $%x): %r ($%x)",
            op_address, cpu_cycles, address, char, value
        )
        return value

    def write_rs232_interface(self, cpu_cycles, op_address, address, value):
        if value == 0x95:
            # RTS low:
            log.info("%04x| (%i) set RTS low",
                op_address, cpu_cycles
            )
            try:
                self.serial.setRTS(True)
            except Exception, err:
                log.info("Error while serial.setRTS: %s" % err)
            return

        log.info("%04x| (%i) write to RS232 address: $%x value: $%x (dez.: %i) ASCII: %r" % (
            op_address, cpu_cycles, address, value, value, chr(value)
        ))
        self.serial.write(chr(value)) # write to pty
        self.serial.flush() # wait until all data is written


class Simple6809PeripheryUnittest(Simple6809PeripheryBase):
    def __init__(self, *args, **kwargs):
        super(Simple6809PeripheryUnittest, self).__init__(*args, **kwargs)
        self._out_buffer = ""
        self.out_lines = []

    def new_output_char(self, char):
#        sys.stdout.write(char)
#        sys.stdout.flush()
        self._out_buffer += char
        if char == "\n":
            self.out_lines.append(self._out_buffer)
            self._out_buffer = ""


class Simple6809PeripheryTk(TkPeripheryBase, Simple6809PeripheryBase):
    TITLE = "DragonPy - Simple 6809"
    GEOMETRY = "+500+300"
    INITAL_INPUT = "\r\n".join([
#         'PRINT "HELLO WORLD!"',
#         '? 123',

        '10 FOR I=1 TO 3',
        '20 PRINT STR$(I)+" DRAGONPY"',
        '30 NEXT I',
        'RUN',
        '',
        'LIST',

    ]) + "\r\n"

    def event_return(self, event):
        self.user_input_queue.put("\r")
#         self.user_input_queue.put("\n")

    _STOP_AFTER_OK_COUNT = None
#     _STOP_AFTER_OK_COUNT = 2
    def update(self, cpu_cycles):
        is_empty = self.output_queue.empty()
        super(Simple6809PeripheryTk, self).update(cpu_cycles)
        if self._STOP_AFTER_OK_COUNT is not None and not is_empty:
            print "\ncpu cycle:", cpu_cycles
            txt = self.text.get(1.0, Tkinter.END)
            if txt.count("OK\r\n") >= self._STOP_AFTER_OK_COUNT:
                log.critical("-> exit!")
                self.destroy()


# Simple6809Periphery = Simple6809PeripherySerial
Simple6809Periphery = Simple6809PeripheryTk

Simple6809TestPeriphery = Simple6809PeripheryUnittest


def test_run():
    import subprocess
    cmd_args = [
        sys.executable,
#         "/usr/bin/pypy",
        os.path.join("..", "DragonPy_CLI.py"),
#        "--verbosity=5",
#         "--verbosity=10", # DEBUG
#         "--verbosity=20", # INFO
#        "--verbosity=30", # WARNING
#         "--verbosity=40", # ERROR
        "--verbosity=50", # CRITICAL/FATAL

        "--cfg=Simple6809",
#         "--max=500000",
#         "--max=20000",
#         "--max=1",
    ]
    print "Startup CLI with: %s" % " ".join(cmd_args[1:])
    subprocess.Popen(cmd_args, cwd="..").wait()

if __name__ == "__main__":
    test_run()
