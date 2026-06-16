.global _start

.data
msg1: .asciz "First message! \n"
msg2: .asciz "Second message!\n"
msg3: .asciz "Third message! \n"

.text
_start:
	ldr x1, =msg1		// x1 = &msg1
	bl print		// procedure call

	ldr x1, =msg2		// x1 = &msg2
	bl print		// procedure call

	ldr x1, =msg3		// x1 = &msg3
	bl print		// procedure call

	mov x8, #93		// exit
	svc #0

print:
	mov x0, #1
	mov x2, #17
	mov x8, #64
	svc #0
	ret
