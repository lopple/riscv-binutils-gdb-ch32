#as: -march=rv32imacxw -mabi=ilp32
#objdump: -dr -M xw
#source: xw.s

.*:[ \t]+file format .*riscv


Disassembly of section .text:

0+000 <target>:
[ \t]+0:[ \t]+3fe0[ \t]+c\.lbu[ \t]+s0,31\(a5\)
[ \t]+2:[ \t]+3f66[ \t]+c\.lhu[ \t]+s1,62\(a4\)
[ \t]+4:[ \t]+b6e8[ \t]+c\.sb[ \t]+a0,15\(a3\)
[ \t]+6:[ \t]+ae6e[ \t]+c\.sh[ \t]+a1,30\(a2\)
[ \t]+8:[ \t]+8790[ \t]+c\.lbusp[ \t]+a2,15\(sp\)
[ \t]+a:[ \t]+87b4[ \t]+c\.lhusp[ \t]+a3,30\(sp\)
[ \t]+c:[ \t]+83d8[ \t]+c\.sbsp[ \t]+a4,7\(sp\)
[ \t]+e:[ \t]+877c[ \t]+c\.shsp[ \t]+a5,14\(sp\)
[ \t]+10:[ \t]+8000[ \t]+c\.lbusp[ \t]+s0,0\(sp\)
[ \t]+12:[ \t]+8120[ \t]+c\.lhusp[ \t]+s0,2\(sp\)
[ \t]+14:[ \t]+81c0[ \t]+c\.sbsp[ \t]+s0,3\(sp\)
[ \t]+16:[ \t]+8260[ \t]+c\.shsp[ \t]+s0,4\(sp\)
