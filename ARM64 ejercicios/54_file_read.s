.global _start

.data
filename: .asciz "test.txt"

.bss
buffer: .space 1024

.text
_start:
	mov x0, #-100 		// load AT_FDCWD
	ldr x1, =filename	// load filename address
	mov x2, #0		// O_RDONLY
	mov x3, #0777		// load octal 777
	mov x8, #56		// load OPENAT
	svc #0			// syscall
	mov x20, x0		// preserve file descriptor AT_FDCWD

	mov x0, x20		// load FD
	ldr x1, =buffer		// load buffer address
	mov x2, #1024		// buffer size
	mov x8, #63		// load READ
	svc #0			// syscall

	mov x0, x20		// load FD
	mov x8, #57		// load CLOSE
	svc #0			// syscall

	mov x0, #1		// load STDOUT
	ldr x1, =buffer		// load buffer address
	mov x2, #1024		// buffer size
	mov x8, #64		// load WRITE
	svc #0			// syscall

	mov x8, #93		// load exit
	svc #0
