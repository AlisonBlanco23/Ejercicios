.global _start

_start:
        movz x1, #0xDDCC                // load lo number to clean
        movk x1, #0xFFEE, lsl #16       // load hi number to clean
        movz x2, #0x00FF                // mask to clean left 6 hex
        ands x0, x1, x2                  // clean and set in x0

        mov x8, #93
        svc #0
