1 PRINT:PRINT "TEST CC WITH LSL V0.2"
2 PRINT "(GPL V3 OR ABOVE)"
3 PRINT:PRINT "COPYLEFT (C) 2013 JENS DIEMER":PRINT
11 COUNT=14
20 LA=&H4000			' LOAD / EXECUTE ADDRESS
25 PRINT "POKE MACHINE CODE TO: $";HEX$(LA)
30 PA = LA			' START ADDRESS FOR POKE
50 READ HB$			' HEX CONSTANTS
60 IF HB$="END" THEN 100
65 V=VAL("&H"+HB$)
70 POKE PA,V	                ' POKE VALUE INTO MEMORY
75 'PRINT "POKE $";HEX$(V);" AT $";HEX$(PA)
80 PA = PA + 1			' INCREMENT POKE ADDRESS
90 GOTO 50
100 PRINT "LOADED, END ADDRESS IS: $"; HEX$(PA-1)
110 PRINT:INPUT "INPUT START VALUE (DEZ)";A$
115 IF A$="" THEN 20000 ELSE A=VAL(A$)
120 A=A-1
130 GOTO 500
140 PRINT "UP/DOWN OR ANYKEY FOR NEW VALUE";
150 I$ = INKEY$:IF I$="" THEN 150
160 IF I$=CHR$(&H5E) THEN A=A2-(COUNT*2) : GOTO 500 ' UP KEYPRESS
170 IF I$=CHR$(&H0A) THEN A=A2 : GOTO 500 ' DOWN KEYPRESS
180 GOTO 110 ' NOT UP/DOWN
500 CLS:PRINT "A=";A;" VALUE FROM $4500: ";PEEK(&H4500)
540 PRINT "              EFHINZVC"
550 FOR I = 1 TO COUNT
551 A2=(A+I) AND &HFF
552 'PRINT "SET A=";A2
553 POKE &H4500,A2 ' SET START VALUE
560 EXEC LA
570 CC=PEEK(&H4501) ' CC-REGISTER
580 A3=PEEK(&H4500) ' INC RESULT
590 ' CREATE BITS
600 T = CC
610 B7$=".":IF T AND 128 THEN B7$="E"
620 B6$=".":IF T AND 64 THEN B6$="F"
630 B5$=".":IF T AND 32 THEN B5$="H"
640 B4$=".":IF T AND 16 THEN B4$="I"
650 B3$=".":IF T AND 8 THEN B3$="N"
660 B2$=".":IF T AND 4 THEN B2$="Z"
670 B1$=".":IF T AND 2 THEN B1$="V"
680 B0$=".":IF T AND 1 THEN B0$="C"
690 PRINT "A=";RIGHT$("  "+STR$(A3),4);" CC=$";RIGHT$(" "+HEX$(CC),2);":";B7$;B6$;B5$;B4$;B3$;B2$;B1$;B0$
700 NEXT I
710 GOTO 140
1000 ' MACHINE CODE IN HEX
1010 ' LDA $4500
1020 DATA B6,45,00
1030 ' CLR,TFR TO CLEAR CC
1040 ' CLR B
1050 DATA 5F
1060 ' TFR B,CC
1070 DATA 1F,9A
1080 ' LSLA/ASLA
1090 DATA 48
2000 ' TFR CC,B
2010 DATA 1F,A9
2020 ' STA $4500
2030 DATA B7,45,00
2040 ' STB $4501
2050 DATA F7,45,01
10000 ' RTS
10010 DATA 39
10020 DATA END
20000 PRINT:PRINT "BYE"
