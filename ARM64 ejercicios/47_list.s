.global _start
.extern itoa

.data
head: .dword 0          // pointer

.bss
buffer: .space 11       // buffer

.text
_start:
    mov x0, #30          // val
    ldr x1, =head        // head
    ldr x1, [x1]
    bl push              // push(val, head)

    mov x0, #20          // val
    ldr x1, =head        // head
    ldr x1, [x1]
    bl push              // push(val, head)

    mov x0, #10          // val
    ldr x1, =head        // head
    ldr x1, [x1]
    bl push              // push(val, head)

    mov x0, #10          // val
    ldr x1, =head        // head
    ldr x1, [x1]
    bl push              // push(val, head)
    ldr x0, =head        // print list
    ldr x0, [x0]
    bl print

    mov x8, #93          // exit
    svc #0


// push procedure

push:
    mov x10, x0          // val
    mov x11, x1          // head

    mov x8, #214         // new_node address
    svc #0
    mov x12, x0

    add x0, x0, #16       // allocate new_node 16 bytes
    mov x8, #214
    svc #0

    str x10, [x12]        // new_node.val = val
    str x11, [x12, #8]     // new_node.next = head
    ldr x13, =head
    str x12, [x13]         // head = new_node
    ret

// list printing procedure

print:
    stp lr, fp, [sp, #-16]!  // push lr
    mov fp, sp                // establecer nuevo marco
    mov x21, x0                // tmp = head
loop:
    cbz x21, end               // branch end if tmp == 0

    ldr x0, [x21]               // itoa(tmp.val, buffer)
    ldr x1, =buffer
    bl itoa

    mov x0, #1                  // print buffer
    ldr x1, =buffer
    mov x2, #11
    mov x8, #64
    svc #0

    ldr x21, [x21, #8]            // tmp = tmp.next
    b loop
end:
    ldp lr, fp, [sp], #16          // pop lr
    ret
