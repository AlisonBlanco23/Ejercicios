// ============================================================
// modulo_1_media.s
// Integrante 1 - Media Aritmética Ponderada
// Curso: ACYE1 - Segundo Semestre 2026
//
// Lo que hace este modulo:
//   1. Lee los 30 datos de Temperatura (columna 1) desde lecturas.csv
//      usando leer_datos de utils.s
//   2. Calcula la media aritmética ponderada con pesos W1=1, W2=2 ... W30=30
//   3. Escribe el resultado en resultado_media.txt
//
// Fórmula:
//   MEDIA_PONDERADA = Σ(Xi * Wi) / ΣWi
//   Donde Wi = i+1, es decir, el primer dato tiene peso 1,
//   el segundo tiene peso 2, y así hasta el dato 30 con peso 30
//
// Funciones que uso de utils.s:
//   leer_datos      -> llena el arreglo datos[] con la columna que le pida
//   int_a_ascii     -> convierte un numero entero a texto legible
//   datos           -> arreglo compartido donde viven los 30 valores
// ============================================================

.extern leer_datos
.extern int_a_ascii
.extern datos

// ============================================================
// Textos fijos que van en el archivo de salida
// ============================================================
.section .data

nombre_salida:
    .asciz "resultado_media.txt"

linea_module:
    .asciz "MODULE=WEIGHTED_MEAN\n"
linea_module_len = . - linea_module

linea_total:
    .asciz "TOTAL_VALUES=30\n"
linea_total_len = . - linea_total

label_sumx:     .asciz "SUM_X="
label_sumx_len = . - label_sumx

label_wsum:     .asciz "WEIGHT_SUM="
label_wsum_len = . - label_wsum

label_mean:     .asciz "WEIGHTED_MEAN="
label_mean_len = . - label_mean

// ============================================================
// Memoria sin inicializar
// ============================================================
.section .bss

// buffer donde armo todo el texto antes de escribirlo al archivo
.comm buffer_salida, 512, 8

// buffers temporales para convertir cada numero a texto
.comm buf_sumx,  32, 8
.comm buf_wsum,  32, 8
.comm buf_media, 32, 8


// ============================================================
// Código principal
// ============================================================
.section .text
.global _start

_start:

    // ---------------------------------------------------------
    // Paso 1: llamo a leer_datos de utils.s con columna 1 = TEMP
    // Esto abre lecturas.csv, extrae la columna TEMP y la guarda
    // en el arreglo global datos[] que vive en utils.s
    // ---------------------------------------------------------
    mov x0, #1
    bl leer_datos

    // ---------------------------------------------------------
    // Paso 2: calcular la media ponderada
    // recorro los 30 datos y voy acumulando:
    //   x20 = suma simple de todos los datos (SUM_X)
    //   x22 = suma ponderada Σ(Xi * Wi)
    //   x23 = suma de pesos Σ(Wi) = 1+2+...+30 = 465
    //   x21 = indice i (0 a 29)
    //   x24 = peso actual Wi = i+1 (arranca en 1, sube hasta 30)
    // ---------------------------------------------------------
    adr x19, datos
    mov x20, #0             // suma simple
    mov x21, #0             // indice
    mov x22, #0             // suma ponderada
    mov x23, #0             // suma de pesos
    mov x24, #1             // peso actual, empieza en 1

.loop_media:
    cmp x21, #30
    beq .fin_media

    ldr x25, [x19, x21, lsl #3]    // cargo datos[i]

    add x20, x20, x25              // SUM_X += datos[i]

    mul x26, x25, x24              // Xi * Wi
    add x22, x22, x26              // suma_ponderada += Xi * Wi

    add x23, x23, x24              // suma_pesos += Wi

    add x21, x21, #1               // i++
    add x24, x24, #1               // Wi++
    b .loop_media

.fin_media:
    // media ponderada = suma_ponderada / suma_pesos
    udiv x27, x22, x23             // x27 = WEIGHTED_MEAN

    // ---------------------------------------------------------
    // Paso 3: armar el texto de salida en buffer_salida
    // x9 va marcando hasta donde he escrito en el buffer
    // ---------------------------------------------------------
    mov x9, #0

    bl .copiar_module
    bl .copiar_total

    // SUM_X=<valor>
    bl .copiar_label_sumx
    mov x0, x20
    adr x1, buf_sumx
    bl int_a_ascii
    adr x0, buf_sumx
    bl .copiar_cadena
    bl .copiar_newline

    // WEIGHT_SUM=<valor>
    bl .copiar_label_wsum
    mov x0, x23
    adr x1, buf_wsum
    bl int_a_ascii
    adr x0, buf_wsum
    bl .copiar_cadena
    bl .copiar_newline

    // WEIGHTED_MEAN=<valor>
    bl .copiar_label_mean
    mov x0, x27
    adr x1, buf_media
    bl int_a_ascii
    adr x0, buf_media
    bl .copiar_cadena
    bl .copiar_newline

    // ---------------------------------------------------------
    // Paso 4: escribir el buffer al archivo resultado_media.txt
    // ---------------------------------------------------------
    mov x8, #56             // syscall openat
    mov x0, #-100           // AT_FDCWD
    adr x1, nombre_salida
    mov x2, #577            // O_WRONLY | O_CREAT | O_TRUNC
    mov x3, #0644
    svc #0
    mov x10, x0             // guardo el fd del archivo

    mov x8, #64             // syscall write
    mov x0, x10
    adr x1, buffer_salida
    mov x2, x9              // cuantos bytes escribi
    svc #0

    mov x8, #57             // syscall close
    mov x0, x10
    svc #0

    // ---------------------------------------------------------
    // Paso 5: imprimo el resultado en pantalla tambien
    // ---------------------------------------------------------
    mov x8, #64
    mov x0, #1              // stdout
    adr x1, buffer_salida
    mov x2, x9
    svc #0

    // fin del programa
    mov x8, #93
    mov x0, #0
    svc #0


// ============================================================
// Funciones auxiliares para copiar texto al buffer_salida
// Todas usan x9 como posicion actual en el buffer.
// x9 va creciendo cada vez que escribo un caracter.
// ============================================================

.copiar_module:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, linea_module
.lp_mod:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_mod
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_mod
.fin_mod:
    ldp x29, x30, [sp], #16
    ret

.copiar_total:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, linea_total
.lp_tot:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_tot
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_tot
.fin_tot:
    ldp x29, x30, [sp], #16
    ret

.copiar_label_sumx:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, label_sumx
.lp_lsx:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_lsx
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_lsx
.fin_lsx:
    ldp x29, x30, [sp], #16
    ret

.copiar_label_wsum:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, label_wsum
.lp_lws:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_lws
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_lws
.fin_lws:
    ldp x29, x30, [sp], #16
    ret

.copiar_label_mean:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, label_mean
.lp_lmn:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_lmn
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_lmn
.fin_lmn:
    ldp x29, x30, [sp], #16
    ret

.copiar_cadena:
    // recibe en x0 el puntero al texto que quiero copiar
    stp x29, x30, [sp, #-16]!
    mov x1, x0
    adr x0, buffer_salida
.lp_cad:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_cad
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_cad
.fin_cad:
    ldp x29, x30, [sp], #16
    ret

.copiar_newline:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    mov w2, #10
    strb w2, [x0, x9]
    add x9, x9, #1
    ldp x29, x30, [sp], #16
    ret
