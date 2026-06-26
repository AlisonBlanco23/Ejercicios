.global _start

.data
filename: .asciz "test.txt"
buffer: .asciz "Hello, \nWorld!\n"

.text
_start:
	mov x0, #-100		// load AT_FDCWD
	ldr x1, =filename	// load filename address
	mov x2, #101		// O_CREATE | O_WRONGLY
	mov x3, #0777		// load octal 777
	mov x8, #56		// load OPENAT
	svc #0			// syscall
	mov x20, x0		// preserve file descriptor AT_FDCWD

	mov x0, x20		// load FD
	ldr x1, =buffer		// load buffer address
	mov x2, #15		// buffer size
	mov x8, #64 		// load WRITE
	svc #0			// syscall

	mov x0, x20		// load FD
	mov x8, #57		// load CLOSE
	svc #0			// syscall

	mov x8, #93		// load exit
	svc #0			// syscall
