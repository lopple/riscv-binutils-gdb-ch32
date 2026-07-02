target:
	c.lbu x0,0(x9)
	c.lbu x8,0(x2)
	c.lhu x8,1(x9)
	c.lhu x8,64(x9)
	c.lbusp x7,0(sp)
	c.lbusp x8,16(sp)
	c.lhusp x8,1(sp)
	c.shsp x8,32(sp)
