.global _start

_start:
        mov x1, #32          // load number to multiply, 32
        mov x2, #2           // load exp in power 2 of 4
        add x0, xzr, x1, lsl 2      // x0 = 32 * 4

        mov x8, #93
        svc #0
