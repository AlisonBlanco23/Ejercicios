.global _start

_start:
    mov x0, #0          // x0 = 0
    add x0, x0, #100    // x0 = x0 + 100

    mov x8, #93         // exit
    svc #0
