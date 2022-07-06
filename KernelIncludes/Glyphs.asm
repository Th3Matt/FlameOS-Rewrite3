
Font:
	.FontLength: dd (.end-($+4))/25

	times 5*5*32 db 0

.Space: db 0x0,0x0,0x0,0x0,0x0
        db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x0,0x0,0x0,0x0

 .Excl: db 0x0,0x0,0xf,0x0,0x0
        db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0

.Quote: db 0x0,0xf,0x0,0xf,0x0
        db 0x0,0x3,0x0,0x3,0x0
		db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x0,0x0,0x0,0x0

 .Hash: db 0x0,0xa,0x5,0xf,0x0
        db 0xa,0xf,0xf,0xf,0x5
		db 0x0,0xf,0xa,0x5,0x0
		db 0xa,0xf,0xf,0xf,0x0
		db 0xa,0x5,0xf,0x0,0x0

	times ("'"-"#"-1)*5*5 db 0

   .SQ: db 0x0,0x0,0xf,0x0,0x0
        db 0x0,0x0,0x3,0x0,0x0
		db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x0,0x0,0x0,0x0

   .OB: db 0x0,0x0,0xe,0x5,0x0
        db 0x0,0xa,0x7,0x0,0x0
		db 0x0,0xa,0x5,0x0,0x0
		db 0x0,0xa,0xd,0x0,0x0
		db 0x0,0x0,0xb,0x5,0x0

   .CB: db 0x0,0xa,0xd,0x0,0x0
        db 0x0,0x0,0xb,0x5,0x0
		db 0x0,0x0,0xa,0x5,0x0
		db 0x0,0x0,0xe,0x5,0x0
		db 0x0,0xa,0x7,0x0,0x0

	times (","-")"-1)*5*5 db 0

 .comm: db 0x0,0x0,0x0,0x0,0x0
        db 0x0,0x0,0x0,0x0,0x0
        db 0x0,0x0,0x0,0x0,0x0
        db 0x0,0x0,0xf,0x5,0x0
        db 0x0,0xa,0xf,0x0,0x0

 .dash: db 0x0,0x0,0x0,0x0,0x0
        db 0x0,0x0,0x0,0x0,0x0
        db 0xa,0xf,0xf,0xf,0x5
        db 0x0,0x0,0x0,0x0,0x0
        db 0x0,0x0,0x0,0x0,0x0

  .dot: db 0x0,0x0,0x0,0x0,0x0
        db 0x0,0x0,0x0,0x0,0x0
        db 0x0,0x0,0x0,0x0,0x0
        db 0x0,0x0,0x0,0x0,0x0
        db 0x0,0x0,0xf,0x0,0x0

	times ("0"-"."-1)*5*5 db 0

	.0: db 0x0,0x8,0xf,0x4,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0x2,0xf,0x1,0x0

	.1: db 0x0,0x8,0xc,0x0,0x0
		db 0x0,0x3,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0xf,0xf,0xf,0x0

	.2: db 0x0,0xf,0xf,0x4,0x0
		db 0xa,0x1,0x2,0xd,0x0
		db 0x0,0x0,0x8,0xf,0x0
		db 0x0,0x8,0xf,0x1,0x0
		db 0x0,0xf,0xf,0xf,0x0

	.3: db 0x0,0xe,0xf,0xd,0x0
		db 0x0,0x3,0x8,0xf,0x0
		db 0x0,0xf,0xf,0x5,0x0
		db 0x0,0xc,0x2,0xf,0x0
		db 0x0,0xb,0xf,0x7,0x0

	.4: db 0x0,0x8,0xf,0xf,0x0
		db 0x0,0xf,0x1,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0x0,0x0,0xf,0x0

	.5: db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0xf,0xd,0x0
		db 0x0,0x0,0x0,0xf,0x0
		db 0x0,0xf,0xf,0x7,0x0

	.6: db 0x0,0x8,0xf,0xf,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0x2,0xf,0x1,0x0

	.7: db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0x0,0x0,0xf,0x0
		db 0x0,0x0,0xf,0x7,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0

	.8: db 0x0,0xe,0xf,0xd,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xa,0xf,0x5,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xb,0xf,0x7,0x0

	.9: db 0x0,0x8,0xf,0x4,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0x2,0xf,0xf,0x0
		db 0x0,0x0,0x0,0xf,0x0
		db 0x0,0xb,0xf,0x1,0x0

.colon: db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0x0,0x0,0x0

	times ("A"-":"-1)*5*5 db 0

	.A: db 0x0,0x8,0xf,0x4,0x0
		db 0x0,0xf,0x3,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0

	.B:	db 0x0,0xf,0xf,0x4,0x0
		db 0x0,0xf,0x8,0xf,0x0
		db 0x0,0xf,0xf,0x5,0x0
		db 0x0,0xf,0x2,0xf,0x0
		db 0x0,0xf,0xf,0x1,0x0

	.C:	db 0x0,0xe,0xf,0xf,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xb,0xf,0xf,0x0

	.D:	db 0x0,0xf,0xf,0x4,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0xf,0x1,0x0

	.E: db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0xf,0xf,0x0

	.F: db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0x0,0x0,0x0

	.G: db 0x0,0xe,0xf,0xd,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0xa,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xb,0xf,0x7,0x0

	.H: db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0

	.I: db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0xf,0xf,0xf,0x0

	.J: db 0x0,0x0,0x0,0xf,0x0
		db 0x0,0x0,0x0,0xf,0x0
		db 0x0,0x0,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0xf,0xf,0x0

	.K: db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0xf,0x0,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0

	.L: db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0xf,0xf,0x0

	.M: db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0

	.N: db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x5,0xf,0x0
		db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0xf,0xa,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0

	.O: db 0x0,0xe,0xf,0xd,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xb,0xf,0x7,0x0

	.P: db 0x0,0xf,0xf,0xd,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0xf,0x7,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0x0,0x0,0x0

	.Q: db 0x0,0x8,0xf,0x4,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0x2,0xf,0x9,0x0

	.R: db 0x0,0xf,0xf,0x0,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0xf,0x0,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0

	.S: db 0x0,0x8,0xf,0x4,0x0
		db 0x0,0xf,0x0,0x1,0x0
		db 0x0,0x2,0xf,0x4,0x0
		db 0x0,0x8,0x0,0xf,0x0
		db 0x0,0x2,0xf,0x1,0x0

	.T: db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0

	.U: db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0x2,0xf,0xf,0x0

	.V: db 0x0,0x4,0x0,0x8,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0x2,0xf,0x1,0x0

	.W: db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0xf,0xf,0xf,0x0

	.X: db 0x2,0xf,0x0,0xf,0x1
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xa,0xf,0x5,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x8,0xf,0x0,0xf,0x4

	.Y: db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0

	.Z: db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0x0,0x0,0xf,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0xf,0xf,0x0

	times ("a"-"Z"-1)*5*5 db 0

	.a: db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0xa,0x3,0xd,0x0
		db 0x0,0x8,0xc,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0x2,0xf,0xb,0x0

	.b:	db 0x0,0x4,0x0,0x0,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0xf,0x4,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0x7,0xf,0x1,0x0

	.c:	db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x8,0xf,0x4,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0x2,0xf,0x1,0x0

	.d:	db 0x0,0x0,0x0,0xf,0x0
		db 0x0,0x0,0x0,0xf,0x0
		db 0x0,0xe,0xf,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xb,0xf,0xb,0x0

	.e: db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x8,0xf,0x4,0x0
		db 0x0,0xf,0xc,0xf,0x0
		db 0x0,0xf,0x0,0xc,0x0
		db 0x0,0x2,0xf,0x7,0x0

	.f: db 0x0,0x0,0xf,0xf,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0

	.g: db 0x0,0x8,0xc,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0x2,0xf,0xf,0x0
		db 0x0,0x0,0x0,0xf,0x0
		db 0x0,0x2,0xf,0x1,0x0

	.h: db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0xf,0x0,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0

	.i: db 0x0,0x0,0xc,0x0,0x0
		db 0x0,0x0,0x3,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0

	.j: db 0x0,0x0,0x0,0xf,0x0
		db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x0,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0xf,0xf,0x0

	.k: db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0xf,0x0,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0

	.l: db 0x0,0xf,0xd,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xb,0xf,0x0

	.m: db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x0,0x0,0x0,0x0
		db 0xa,0xe,0xf,0xe,0x4
		db 0xa,0x5,0xf,0xa,0x5
		db 0xa,0x5,0xf,0xa,0x5

	.n: db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0xf,0xf,0x4,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0

	.o: db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x8,0xf,0x4,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0x2,0xf,0x1,0x0

	.p: db 0x0,0x0,0x0,0x0,0x0
		db 0xa,0x5,0xf,0x4,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0xf,0x1,0x0
		db 0x0,0xf,0x0,0x0,0x0

	.q: db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x8,0xf,0x4,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0x2,0xf,0x9,0x0

	.r: db 0x0,0x0,0x0,0x0,0x0
		db 0xa,0x5,0xf,0xf,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0x0,0x0,0x0
		db 0x0,0xf,0x0,0x0,0x0

	.s: db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x8,0xc,0x0,0x0
		db 0x8,0x7,0x3,0x1,0x0
		db 0x0,0x3,0x3,0xd,0x0
		db 0x0,0xb,0xf,0x1,0x0

	.t: db 0x0,0x0,0xc,0x0,0x0
		db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0xf,0x0,0x0
		db 0x0,0x0,0x2,0xf,0x0

	.u: db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0xc,0x0,0xc,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xb,0xf,0xb,0x0

	.v: db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x4,0x0,0x8,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0x2,0xf,0x1,0x0

	.w: db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0xf,0xf,0xf,0x0

	.x: db 0x0,0x0,0x0,0x0,0x0
		db 0x8,0x4,0x0,0x8,0x4
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xa,0xf,0x5,0x0
		db 0x8,0xf,0x0,0xf,0x4

	.y: db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0xf,0x0,0xf,0x0
		db 0x0,0x2,0xf,0x1,0x0
		db 0x0,0xf,0x1,0x0,0x0

	.z: db 0x0,0x0,0x0,0x0,0x0
		db 0x0,0xf,0xf,0xf,0x0
		db 0x0,0x0,0x8,0x7,0x0
		db 0x0,0x8,0x7,0x0,0x0
		db 0x0,0xf,0xf,0xf,0x0

  .OCB: db 0x0,0x0,0xe,0x5,0x0
        db 0x0,0x8,0xf,0x0,0x0
        db 0x0,0xf,0x5,0x0,0x0
        db 0x0,0x2,0xf,0x0,0x0
        db 0x0,0x0,0xb,0x5,0x0

 .VBar: db 0x0,0x0,0xf,0x0,0x0
        db 0x0,0x0,0xf,0x0,0x0
        db 0x0,0x0,0xf,0x0,0x0
        db 0x0,0x0,0xf,0x0,0x0
        db 0x0,0x0,0xf,0x0,0x0

  .CCB: db 0x0,0xa,0xd,0x0,0x0
        db 0x0,0x0,0xf,0x4,0x0
        db 0x0,0x0,0xa,0xf,0x0
        db 0x0,0x0,0xf,0x1,0x0
        db 0x0,0xa,0x7,0x0,0x0

	.end:

	times (256-"}"-1)*5*5 db 0