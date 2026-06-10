.global _start

.data
a: .word 1, 2, 3

.text
_start:
        ldr x1, =a           // x1 = addr of a
        mov x2, #8
        ldr x0, [x1, x2]     // x0 = cont of a[2]

        mov x8, #93
        svc #0





