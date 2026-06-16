.global _start

.bss
buffer: .skip 2

.text
_start:
	mov x0, #3		// test value
	ldr x1, =buffer		// buffer address

switch:
	cmp x0, #1
	b.eq case1

	cmp x0, #2
	b.eq case2

	cmp x0, #3
	b.eq case3

	b end

case1:				// add ASCII of 1 to buffer
	mov x0, #49
	strb w0, [x1]
	b end

case2:				// add ASCII of 2 to buffer
	mov x0, #50
	strb w0, [x1]
	b end

case3: 				// add ASCII of 3 t buffer
	mov x0, #51
	strb w0, [x1]

end:
	add x1, x1, #1		// add new line to buffer
	mov x2, #10
	strb w2, [x1]

	mov x0, #1		// print buffer
	ldr x1, =buffer
	mov x2, #2
	mov x8, #64
	svc #0

	mov x0, #0 		// exit
	mov x8, #93
	svc #0
