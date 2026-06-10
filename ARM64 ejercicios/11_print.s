.global _start

_start:
	mov x0, #1 //set stdout
	ldr x1, =msg //load msg
	mov x2, #14 //set msg size
	mov x8, #64 //write code
	svc #0 // syscall

	mov x8, #93 //exit
	svc #0

.data
msg: .asciz "Hello, World!\n"
