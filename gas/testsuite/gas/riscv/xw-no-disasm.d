#as: -march=rv32ecxw -mabi=ilp32e
#objdump: -dr
#source: xw.s

.*:[ \t]+file format .*riscv


Disassembly of section .text:

0+000 <target>:
[ \t]+0:[ \t]+3fe0[ \t]+fld[ \t]+fs0,248\(a5\)
[ \t]+2:[ \t]+3f66[ \t]+fld[ \t]+ft10,120\(sp\)
[ \t]+4:[ \t]+b6e8[ \t]+fsd[ \t]+fa0,232\(a3\)
[ \t]+6:[ \t]+ae6e[ \t]+fsd[ \t]+fs11,280\(sp\)
[ \t]+8:[ \t]+8790[ \t]+0x8790
[ \t]+a:[ \t]+87b4[ \t]+0x87b4
[ \t]+c:[ \t]+83d8[ \t]+0x83d8
[ \t]+e:[ \t]+877c[ \t]+0x877c
[ \t]+10:[ \t]+8000[ \t]+0x8000
[ \t]+12:[ \t]+8120[ \t]+0x8120
[ \t]+14:[ \t]+81c0[ \t]+0x81c0
[ \t]+16:[ \t]+8260[ \t]+0x8260
