.global _start

_start:
    mov x1, #0b10010      // initial state
    mov x2, #0b101        // new data from sensor
    orr x0, x1, x2        // x0 = x1 || x2

    mov x8, #93
    svc #0
