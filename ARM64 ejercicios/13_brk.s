.global _start

.data
ptr: .word 0          // pointer

.text
_start:
    mov x8, #214      // syscall brk (Linux)
    mov x0, #0        // brk(NULL)
    svc #0

    ldr x1, =ptr      // x1 = &ptr
    str x0, [x1]      // ptr = brk address

    add x0, x0, #4    // x0 = x0 + 4
    mov x8, #214
    svc #0            // reserve dynamic memory

    ldr x1, =ptr      // x1 = &ptr
    ldr x2, [x1]      // x2 = *x1 = ptr
    mov x3, #100
    str x3, [x2]      // *ptr = 100

    ldr x1, =ptr      // x1 = &ptr
    ldr x2, [x1]      // x2 = *x1 = ptr
    ldr x0, [x2]      // x0 = *ptr
    mov x8, #93       // syscall exit
    svc #0
