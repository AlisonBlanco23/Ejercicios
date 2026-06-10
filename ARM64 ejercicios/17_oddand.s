.global _start

_start:
        mov x1, #33          // x1 = 33
        and x0, x1, #1       // x0 = x1 && 1

	mov x2, -1
	and x0, x1, x2
        mov x8, #93
        svc #0
