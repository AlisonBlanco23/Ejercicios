// determinant = a - b
//
// a = matrix[0, 0] * matrix[1, 1]
// b = matrix[1, 0] * matrix[0, 1]

.global _start

.extern itoa

.data
matrix:
    .word 25, 11
    .word 10, 20

.bss
buffer: .space 11

.text
_start:
    ldr x10, =matrix        // load matrix address

    mov x0, #0
    mov x1, #0
    mov x2, #2
    bl offset                // x11 = offset matrix[0, 0]
    mov x11, x0

    mov x0, #1
    mov x1, #1
    mov x2, #2
    bl offset                // x12 = offset matrix[1, 1]
    mov x12, x0

    add x11, x10, x11        // load values with offset
    ldr w11, [x11]           // load 32 bits
    add x12, x10, x12
    ldr w12, [x12]           // load 32 bits
    mul x13, x11, x12        // x13 = x11 * x12 (a)

    mov x0, #1
    mov x1, #0
    mov x2, #2
    bl offset                // x11 = offset matrix[1, 0]
    mov x11, x0

    mov x0, #0
    mov x1, #1
    mov x2, #2
    bl offset                // x12 = offset matrix[0, 1]
    mov x12, x0

    add x11, x10, x11        // load values with offset
    ldr w11, [x11]           // load 32 bits
    add x12, x10, x12
    ldr w12, [x12]           // load 32 bits
    mul x14, x11, x12        // x14 = x11 * x12 (b)

    sub x11, x13, x14        // x11 = x13 - x14 (det = a - b)

    mov x0, x11
    ldr x1, =buffer
    bl itoa                  // call itoa

    mov x0, #1
    ldr x1, =buffer          // print buffer
    mov x2, #11
    mov x8, #64
    svc #0

    mov x8, #93               // exit
    svc #0

offset:                       // row-major offset
    mul x3, x0, x2
    add x3, x3, x1
    mov x4, #4
    mul x0, x3, x4
    ret
