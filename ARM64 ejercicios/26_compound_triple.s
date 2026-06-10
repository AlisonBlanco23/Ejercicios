.global _start

_start:
	mov x0, #15 // test value
	mov x1, #10 // lower limit
	mov x2, #20 // upper limit
	mov x3, #20 // different value

	cmp x0, x1 // x3 = (15 > 10) ? 1 : 0
	cset x4, gt

	cmp x0, x2 // x4 = (15 < 20) ? 1 : 0
	cset x5, lt

	cmp x0, x3 // x4 = (15 != 15) ? 1 : 0
	cset x6, ne

	and x0, x4, x5 // x0 = x3 & x4 & x6
	and x0, x0, x6

	mov x8, #93 // exit syscall
	svc #0
