global _start

.data
float1: .word 0x40200000                // 32-bit float: 2.5

.text
_start:
        ldr x0, =float1                 // load float1 addr>
        ldr s0, [x0]                    // load float1 valu>
        fmov w0, s0                     // copy s0 to w0 (b>

        mov x8, #93                     // exit
        svc #0
