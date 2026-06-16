.global _start

.bss
str: .skip 27           // Reservar espacio para 26 letras + '\n'

.text
_start:
    ldr x0, =str        // x0 = buffer address
    mov x1, #26         // initial counter
    mov x2, #'a'        // initial symbol

loop:
    strb w2, [x0]       // store symbol in buffer
    add x2, x2, #1      // symbol increment
    sub x1, x1, #1      // counter decrement
    add x0, x0, #1      // buffer increment
    cbnz x1, loop       // if x1 != 0 loop

    mov x2, #10         // add '\n' to buffer
    strb w2, [x0]

    mov x0, #1          // print buffer
    ldr x1, =str
    mov x2, #27
    mov x8, #64
    svc #0

    mov x0, #0          // exit
    mov x8, #93
    svc #0
