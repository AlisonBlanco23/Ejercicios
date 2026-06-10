.global _start

_start:
	mov x0, #15 // test value
	mov x1, #10 // lower limit
	mov x2, #20 // upper limit

	cmp x0, x1 // compare 15 - 10
	cset x3, gt // x3 = (15 > 10) ? 1 : 0

	cmp x0, x2 // compare 15 - 20
	cset x4, lt // x4 = (15 < 20) ? 1 : 0

	and x0, x3, x4 // x0 = x3 & x4

	mov x8, #93
	svc #0
