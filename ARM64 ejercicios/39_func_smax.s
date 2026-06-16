.global _start

_start:
	mov x0, #10		// test values
	mov x1, #15
	bl smax

	mov x8, #93		// exit
	svc #0

smax:
	cmp x0, x1		// NZCV set
	csel x0, x0, x1, ge	// (x0 >= z1) ? x0 : x1
	ret
