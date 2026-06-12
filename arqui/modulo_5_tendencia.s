// ============================================================
// modulo_5_tendencia.s
// Integrante 5 - Tendencia Acumulada Avanzada
// Curso: ACYE1 - Segundo Semestre 2026
//
// Lo que hace este modulo:
//   1. Leo los 30 datos de HUM_SUELO_1 (columna 3) usando leer_datos de utils.s
//   2. Calculo cuantos incrementos y decrementos hay entre datos consecutivos
//   3. Busco la racha mas larga de subida y de bajada
//   4. Acumulo la diferencia total para saber si la tendencia es UP, DOWN o STABLE
//   5. Escribo todo en resultado_tendencia.txt
//
// Formulas:
//   DIF_i    = X_i - X_(i-1)
//   DIF_ACUM = Suma de todos los DIF_i
//   Si DIF_ACUM > 0 => TREND=UP
//   Si DIF_ACUM < 0 => TREND=DOWN
//   Si DIF_ACUM = 0 => TREND=STABLE
//
// Funciones que uso de utils.s:
//   leer_datos   -> llena datos[] con la columna que le pido
//   int_a_ascii  -> convierte numero a texto para escribirlo
//   datos        -> arreglo compartido con los 30 valores
// ============================================================

.extern leer_datos
.extern int_a_ascii
.extern datos

// ============================================================
// Textos fijos del archivo de salida
// ============================================================
.section .data

nombre_salida:
    .asciz "resultado_tendencia.txt"

linea_module:
    .asciz "MODULE=ADVANCED_TREND\n"
linea_module_len = . - linea_module

linea_total:
    .asciz "TOTAL_VALUES=30\n"
linea_total_len = . - linea_total

label_inc:      .asciz "INCREMENTS="
label_inc_len = . - label_inc

label_dec:      .asciz "DECREMENTS="
label_dec_len = . - label_dec

label_mup:      .asciz "MAX_UP_STREAK="
label_mup_len = . - label_mup

label_mdn:      .asciz "MAX_DOWN_STREAK="
label_mdn_len = . - label_mdn

label_acc:      .asciz "ACCUM_DIFF="
label_acc_len = . - label_acc

str_trend_up:     .asciz "TREND=UP\n"
str_trend_up_len = . - str_trend_up

str_trend_down:   .asciz "TREND=DOWN\n"
str_trend_down_len = . - str_trend_down

str_trend_stable: .asciz "TREND=STABLE\n"
str_trend_stable_len = . - str_trend_stable

str_minus:      .asciz "-"

// ============================================================
// Memoria sin inicializar
// ============================================================
.section .bss

.comm buffer_salida, 512, 8

// buffers para convertir cada numero a texto
.comm buf_inc,  32, 8
.comm buf_dec,  32, 8
.comm buf_mup,  32, 8
.comm buf_mdn,  32, 8
.comm buf_acc,  32, 8

// ============================================================
// Codigo principal
// ============================================================
.section .text
.global _start

_start:

    // ---------------------------------------------------------
    // Paso 1: pido a utils que lea la columna 3 = HUM_SUELO_1
    // despues de esta llamada, datos[] tiene los 30 valores listos
    // ---------------------------------------------------------
    mov x0, #3
    bl leer_datos

    // ---------------------------------------------------------
    // Paso 2: recorro los 30 datos comparando cada uno con el anterior
    // para ir contando incrementos, decrementos y rachas
    //
    // registros que uso:
    //   x19 = puntero al arreglo datos
    //   x20 = indice i, arranca en 1 porque comparo con el anterior
    //   x21 = contador de incrementos
    //   x22 = contador de decrementos
    //   x23 = racha de subida actual
    //   x24 = racha de bajada actual
    //   x25 = racha maxima de subida
    //   x26 = racha maxima de bajada
    //   x27 = diferencia acumulada (puede quedar negativa)
    // ---------------------------------------------------------
    adr x19, datos
    mov x20, #1             // empiezo en i=1 para poder ver datos[i-1]
    mov x21, #0             // incrementos
    mov x22, #0             // decrementos
    mov x23, #0             // racha_up actual
    mov x24, #0             // racha_down actual
    mov x25, #0             // max_up
    mov x26, #0             // max_down
    mov x27, #0             // accum_diff

.loop_tendencia:
    cmp x20, #30
    beq .fin_tendencia

    // cargo datos[i-1] y datos[i]
    sub x9,  x20, #1
    ldr x10, [x19, x9,  lsl #3]    // datos[i-1]
    ldr x11, [x19, x20, lsl #3]    // datos[i]

    // DIF_i = datos[i] - datos[i-1]
    sub x12, x11, x10
    add x27, x27, x12       // acumulo la diferencia

    cmp x12, #0
    bgt .es_incremento
    blt .es_decremento

    // si la diferencia es 0, reseteo ambas rachas
    mov x23, #0
    mov x24, #0
    b .siguiente

.es_incremento:
    add x21, x21, #1        // incrementos++
    add x23, x23, #1        // racha_up++
    mov x24, #0             // reseteo racha_down
    cmp x23, x25
    ble .siguiente
    mov x25, x23            // actualizo max_up si supero el record
    b .siguiente

.es_decremento:
    add x22, x22, #1        // decrementos++
    add x24, x24, #1        // racha_down++
    mov x23, #0             // reseteo racha_up
    cmp x24, x26
    ble .siguiente
    mov x26, x24            // actualizo max_down si supero el record

.siguiente:
    add x20, x20, #1
    b .loop_tendencia

.fin_tendencia:

    // ---------------------------------------------------------
    // Paso 3: armo el texto de salida en buffer_salida
    // x9 va marcando cuantos bytes llevo escritos en el buffer
    // ---------------------------------------------------------
    mov x9, #0

    bl .copiar_module
    bl .copiar_total

    // INCREMENTS=<valor>
    bl .copiar_label_inc
    mov x0, x21
    adr x1, buf_inc
    bl int_a_ascii
    adr x0, buf_inc
    bl .copiar_cadena
    bl .copiar_newline

    // DECREMENTS=<valor>
    bl .copiar_label_dec
    mov x0, x22
    adr x1, buf_dec
    bl int_a_ascii
    adr x0, buf_dec
    bl .copiar_cadena
    bl .copiar_newline

    // MAX_UP_STREAK=<valor>
    bl .copiar_label_mup
    mov x0, x25
    adr x1, buf_mup
    bl int_a_ascii
    adr x0, buf_mup
    bl .copiar_cadena
    bl .copiar_newline

    // MAX_DOWN_STREAK=<valor>
    bl .copiar_label_mdn
    mov x0, x26
    adr x1, buf_mdn
    bl int_a_ascii
    adr x0, buf_mdn
    bl .copiar_cadena
    bl .copiar_newline

    // ACCUM_DIFF=<valor> (este puede ser negativo, lo manejo aparte)
    bl .copiar_label_acc
    mov x28, x27            // guardo x27 en x28 para no perderlo

    cmp x27, #0
    bge .accum_positivo

    // si es negativo, escribo el signo "-" y luego el valor absoluto
    adr x0, buffer_salida
    mov w2, #45             // 45 = '-' en ASCII
    strb w2, [x0, x9]
    add x9, x9, #1
    neg x28, x27            // valor absoluto

.accum_positivo:
    mov x0, x28
    adr x1, buf_acc
    bl int_a_ascii
    adr x0, buf_acc
    bl .copiar_cadena
    bl .copiar_newline

    // TREND=UP / DOWN / STABLE segun el signo de accum_diff
    cmp x27, #0
    bgt .trend_up
    blt .trend_down

    // STABLE
    bl .copiar_trend_stable
    b .escribir_archivo

.trend_up:
    bl .copiar_trend_up
    b .escribir_archivo

.trend_down:
    bl .copiar_trend_down

.escribir_archivo:
    // ---------------------------------------------------------
    // Paso 4: guardo el buffer en resultado_tendencia.txt
    // ---------------------------------------------------------
    mov x8, #56             // syscall openat
    mov x0, #-100           // AT_FDCWD
    adr x1, nombre_salida
    mov x2, #577            // O_WRONLY | O_CREAT | O_TRUNC
    mov x3, #0644
    svc #0
    mov x10, x0             // guardo el fd

    mov x8, #64             // syscall write
    mov x0, x10
    adr x1, buffer_salida
    mov x2, x9              // cuantos bytes escribi
    svc #0

    mov x8, #57             // syscall close
    mov x0, x10
    svc #0

    // ---------------------------------------------------------
    // Paso 5: tambien lo muestro en pantalla
    // ---------------------------------------------------------
    mov x8, #64
    mov x0, #1
    adr x1, buffer_salida
    mov x2, x9
    svc #0

    // fin del programa
    mov x8, #93
    mov x0, #0
    svc #0


// ============================================================
// Funciones para copiar texto al buffer_salida
// Todas usan x9 como posicion actual.
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

.copiar_label_inc:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, label_inc
.lp_linc:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_linc
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_linc
.fin_linc:
    ldp x29, x30, [sp], #16
    ret

.copiar_label_dec:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, label_dec
.lp_ldec:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_ldec
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_ldec
.fin_ldec:
    ldp x29, x30, [sp], #16
    ret

.copiar_label_mup:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, label_mup
.lp_lmup:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_lmup
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_lmup
.fin_lmup:
    ldp x29, x30, [sp], #16
    ret

.copiar_label_mdn:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, label_mdn
.lp_lmdn:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_lmdn
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_lmdn
.fin_lmdn:
    ldp x29, x30, [sp], #16
    ret

.copiar_label_acc:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, label_acc
.lp_lacc:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_lacc
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_lacc
.fin_lacc:
    ldp x29, x30, [sp], #16
    ret

.copiar_trend_up:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, str_trend_up
.lp_tup:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_tup
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_tup
.fin_tup:
    ldp x29, x30, [sp], #16
    ret

.copiar_trend_down:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, str_trend_down
.lp_tdn:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_tdn
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_tdn
.fin_tdn:
    ldp x29, x30, [sp], #16
    ret

.copiar_trend_stable:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, str_trend_stable
.lp_tst:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_tst
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_tst
.fin_tst:
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
