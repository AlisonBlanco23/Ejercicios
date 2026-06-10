.global _start

.data
a: .word 0xFFFFFFFF00000000
b: .word 0xFFFFFFFF

.text
_start:
	ldr x1, =a // x1 = addr of a
	ldr x2, =b // x2 = addr of b
	ldr x3, [x2] // x3 = content of a
	str x3, [x1] // a = a OR b
	ldrb w0, [x1] // return a

	mov x8, #93 // exit
	svc #0
