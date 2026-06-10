.global _start

.data
a: .word 0
s: .string "hola"

.text
_start:
        ldr x1, =s           // x1 = addr of s
        ldr x2, [x1, #3]     // x2 = s[3]
        ldr x3, =a           // x3 = addr of a
        strb w2, [x3]        // a = s[3]
        ldr x0, [x3]

        mov x8, #93
        svc #0
