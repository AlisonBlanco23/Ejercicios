.global _start

.data
a: .word 10

.bss
b: .space 8

.text
_start:
        ldr x1, =a        // x1 = addr of a
        ldr x2, [x1]      // x0 = cont of a
        ldr x3, =b        // x3 = addr of b
        str x2, [x3]      // b = a
        ldr x0, [x3]

        mov x8, #93
        svc #0
