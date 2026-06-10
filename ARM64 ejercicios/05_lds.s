.global _start

.data
a: .word 1, 2, 3

.text
_start:
        ldr x1, =a        // x1 = addr of a
        ldr x0, [x1]      // x0 = cont of a

        mov x8, #93
        svc #0
