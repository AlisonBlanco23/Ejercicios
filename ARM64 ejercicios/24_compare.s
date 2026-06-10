.global _start

_start:
	mov x1, #10 // move numbers to compare
	mov x2, #20

	cmp x1, x2 // compare 10-20 to set nzcv
	mrs x0, nzcv // move nzcv to x0
	lsr x0, x0, #28 // shift 28 bits to see nzcv

	mov x8, #93 // exit syscall
	svc #0
