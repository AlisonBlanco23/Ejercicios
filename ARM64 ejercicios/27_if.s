.global _start

_start:
	mov x0, #10 // load values
	mov x1, #15

if: // if (x0 >= x1)
	cmp x0, x1
	b.lt endif
	add x0, x0, x1 // true

endif: // false

	mov x8, #93 // exit syscall
	svc #0

