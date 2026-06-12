// ============================================================
// modulo_5_tendencia.s
// Integrante 5 - Tendencia Acumulada Avanzada
// Curso: ACYE1 - Segundo Semestre 2026
//
// Lo que hace este modulo:
//   1. Leo HUM_SUELO_1 (columna 3) con leer_datos de utils.s
//   2. Copio esos datos a arr_suelo1 antes de que la siguiente
//      llamada a leer_datos los sobreescriba en datos[]
//   3. Leo HUM_SUELO_2 (columna 4) con leer_datos
//   4. Calculo tendencia de HUM_SUELO_1 usando arr_suelo1
//   5. Calculo tendencia de HUM_SUELO_2 usando datos[]
//   6. Escribo ambos resultados en resultado_tendencia.txt
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

str_area1:
    .asciz "AREA=HUM_SUELO_1\n"
str_area1_len = . - str_area1

str_area2:
    .asciz "AREA=HUM_SUELO_2\n"
str_area2_len = . - str_area2

str_separador:
    .asciz "---\n"
str_separador_len = . - str_separador

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

// ============================================================
// Memoria sin inicializar
// ============================================================
.section .bss

// buffer mas grande porque escribo dos secciones de resultados
.comm buffer_salida, 1024, 8

// arreglo propio para guardar HUM_SUELO_1
// lo necesito porque leer_datos sobreescribe datos[] con cada llamada
.comm arr_suelo1, 240, 8

// buffers para convertir numeros a texto, dos juegos uno por columna
.comm buf_inc1,  32, 8
.comm buf_dec1,  32, 8
.comm buf_mup1,  32, 8
.comm buf_mdn1,  32, 8
.comm buf_acc1,  32, 8

.comm buf_inc2,  32, 8
.comm buf_dec2,  32, 8
.comm buf_mup2,  32, 8
.comm buf_mdn2,  32, 8
.comm buf_acc2,  32, 8

// ============================================================
// Codigo principal
// ============================================================
.section .text
.global _start

_start:

    // ---------------------------------------------------------
    // Paso 1: leo HUM_SUELO_1 con utils.s
    // despues de esto datos[] tiene los 30 valores de suelo 1
    // ---------------------------------------------------------
    mov x0, #3
    bl leer_datos

    // ---------------------------------------------------------
    // Paso 2: copio datos[] a mi arreglo arr_suelo1
    // si no hago esto, cuando llame leer_datos para suelo 2
    // los valores de suelo 1 se pierden para siempre
    //
    //   x0 = puntero origen (datos[] de utils)
    //   x1 = puntero destino (arr_suelo1 mio)
    //   x2 = contador del 0 al 29
    // ---------------------------------------------------------
    adr x0, datos
    adr x1, arr_suelo1
    mov x2, #0

.loop_copiar:
    cmp x2, #30
    beq .fin_copiar
    ldr x3, [x0, x2, lsl #3]
    str x3, [x1, x2, lsl #3]
    add x2, x2, #1
    b .loop_copiar

.fin_copiar:

    // ---------------------------------------------------------
    // Paso 3: leo HUM_SUELO_2 con utils.s
    // ahora datos[] tiene los 30 valores de suelo 2
    // arr_suelo1 tiene guardados los de suelo 1
    // ---------------------------------------------------------
    mov x0, #4
    bl leer_datos

    // ---------------------------------------------------------
    // Paso 4: calculo tendencia de HUM_SUELO_1 usando arr_suelo1
    //
    // registros que uso:
    //   x19 = puntero al arreglo que estoy analizando
    //   x20 = indice i, empieza en 1 para comparar con el anterior
    //   x21 = contador de incrementos
    //   x22 = contador de decrementos
    //   x23 = racha de subida actual
    //   x24 = racha de bajada actual
    //   x25 = racha maxima de subida
    //   x26 = racha maxima de bajada
    //   x27 = diferencia acumulada (puede ser negativa)
    // ---------------------------------------------------------
    adr x19, arr_suelo1
    mov x20, #1
    mov x21, #0
    mov x22, #0
    mov x23, #0
    mov x24, #0
    mov x25, #0
    mov x26, #0
    mov x27, #0

.loop_tend1:
    cmp x20, #30
    beq .fin_tend1

    sub x9,  x20, #1
    ldr x10, [x19, x9,  lsl #3]    // datos[i-1]
    ldr x11, [x19, x20, lsl #3]    // datos[i]

    sub x12, x11, x10               // diferencia entre consecutivos
    add x27, x27, x12               // acumulo la diferencia total

    cmp x12, #0
    bgt .inc1
    blt .dec1

    // diferencia 0: reseteo las dos rachas
    mov x23, #0
    mov x24, #0
    b .sig1

.inc1:
    add x21, x21, #1
    add x23, x23, #1
    mov x24, #0
    cmp x23, x25
    ble .sig1
    mov x25, x23                    // nuevo record de racha subida
    b .sig1

.dec1:
    add x22, x22, #1
    add x24, x24, #1
    mov x23, #0
    cmp x24, x26
    ble .sig1
    mov x26, x24                    // nuevo record de racha bajada

.sig1:
    add x20, x20, #1
    b .loop_tend1

.fin_tend1:
    // guardo los 5 resultados de suelo1 en la pila
    // los voy a necesitar mas adelante cuando escriba el archivo
    // reservo 64 bytes alineado a 16
    sub sp, sp, #64
    str x21, [sp, #0]               // incrementos s1
    str x22, [sp, #8]               // decrementos s1
    str x25, [sp, #16]              // max_up s1
    str x26, [sp, #24]              // max_down s1
    str x27, [sp, #32]              // accum_diff s1

    // ---------------------------------------------------------
    // Paso 5: calculo tendencia de HUM_SUELO_2 usando datos[]
    // reutilizo los mismos registros x19-x27
    // ---------------------------------------------------------
    adr x19, datos
    mov x20, #1
    mov x21, #0
    mov x22, #0
    mov x23, #0
    mov x24, #0
    mov x25, #0
    mov x26, #0
    mov x27, #0

.loop_tend2:
    cmp x20, #30
    beq .fin_tend2

    sub x9,  x20, #1
    ldr x10, [x19, x9,  lsl #3]
    ldr x11, [x19, x20, lsl #3]

    sub x12, x11, x10
    add x27, x27, x12

    cmp x12, #0
    bgt .inc2
    blt .dec2

    mov x23, #0
    mov x24, #0
    b .sig2

.inc2:
    add x21, x21, #1
    add x23, x23, #1
    mov x24, #0
    cmp x23, x25
    ble .sig2
    mov x25, x23
    b .sig2

.dec2:
    add x22, x22, #1
    add x24, x24, #1
    mov x23, #0
    cmp x24, x26
    ble .sig2
    mov x26, x24

.sig2:
    add x20, x20, #1
    b .loop_tend2

.fin_tend2:
    // guardo resultados de suelo2 tambien en la pila
    str x21, [sp, #40]              // incrementos s2
    str x22, [sp, #48]              // decrementos s2
    str x25, [sp, #56]              // max_up s2
    // max_down y accum de s2 los mantengo en x26 y x27 en registros

    // ---------------------------------------------------------
    // Paso 6: armo el texto completo en buffer_salida
    // primero el encabezado, luego suelo 1, separador, luego suelo 2
    // ---------------------------------------------------------
    mov x9, #0

    bl .copiar_module
    bl .copiar_total

    // ---- bloque HUM_SUELO_1 ---------------------------------
    bl .copiar_area1

    ldr x21, [sp, #0]               // recupero resultados s1
    ldr x22, [sp, #8]
    ldr x25, [sp, #16]
    ldr x28, [sp, #24]              // max_down en x28 para no chocar
    ldr x27, [sp, #32]              // accum_diff s1

    bl .copiar_label_inc
    mov x0, x21
    adr x1, buf_inc1
    bl int_a_ascii
    adr x0, buf_inc1
    bl .copiar_cadena
    bl .copiar_newline

    bl .copiar_label_dec
    mov x0, x22
    adr x1, buf_dec1
    bl int_a_ascii
    adr x0, buf_dec1
    bl .copiar_cadena
    bl .copiar_newline

    bl .copiar_label_mup
    mov x0, x25
    adr x1, buf_mup1
    bl int_a_ascii
    adr x0, buf_mup1
    bl .copiar_cadena
    bl .copiar_newline

    bl .copiar_label_mdn
    mov x0, x28
    adr x1, buf_mdn1
    bl int_a_ascii
    adr x0, buf_mdn1
    bl .copiar_cadena
    bl .copiar_newline

    bl .copiar_label_acc
    mov x0, x27
    cmp x27, #0
    bge .acc1_pos
    adr x0, buffer_salida
    mov w2, #45
    strb w2, [x0, x9]
    add x9, x9, #1
    neg x27, x27
    mov x0, x27
.acc1_pos:
    adr x1, buf_acc1
    bl int_a_ascii
    adr x0, buf_acc1
    bl .copiar_cadena
    bl .copiar_newline

    ldr x27, [sp, #32]              // recargo para checar el signo
    cmp x27, #0
    bgt .trend1_up
    blt .trend1_down
    bl .copiar_trend_stable
    b .bloque2
.trend1_up:
    bl .copiar_trend_up
    b .bloque2
.trend1_down:
    bl .copiar_trend_down

.bloque2:
    bl .copiar_separador

    // ---- bloque HUM_SUELO_2 ---------------------------------
    bl .copiar_area2

    ldr x21, [sp, #40]              // recupero resultados s2
    ldr x22, [sp, #48]
    ldr x25, [sp, #56]
    // x26 y x27 siguen con max_down y accum_diff de s2 en registros

    bl .copiar_label_inc
    mov x0, x21
    adr x1, buf_inc2
    bl int_a_ascii
    adr x0, buf_inc2
    bl .copiar_cadena
    bl .copiar_newline

    bl .copiar_label_dec
    mov x0, x22
    adr x1, buf_dec2
    bl int_a_ascii
    adr x0, buf_dec2
    bl .copiar_cadena
    bl .copiar_newline

    bl .copiar_label_mup
    mov x0, x25
    adr x1, buf_mup2
    bl int_a_ascii
    adr x0, buf_mup2
    bl .copiar_cadena
    bl .copiar_newline

    bl .copiar_label_mdn
    mov x0, x26
    adr x1, buf_mdn2
    bl int_a_ascii
    adr x0, buf_mdn2
    bl .copiar_cadena
    bl .copiar_newline

    bl .copiar_label_acc
    mov x0, x27
    cmp x27, #0
    bge .acc2_pos
    adr x0, buffer_salida
    mov w2, #45
    strb w2, [x0, x9]
    add x9, x9, #1
    neg x27, x27
    mov x0, x27
.acc2_pos:
    adr x1, buf_acc2
    bl int_a_ascii
    adr x0, buf_acc2
    bl .copiar_cadena
    bl .copiar_newline

    // cargo de nuevo el accum original para checar el signo
    sub x0, x27, x27                // x0 = 0 como base
    // el valor ya modificado con neg puede estar positivo, uso x26 como ref
    // simplemente comparo x27 actual (ya es abs) vs 0 no sirve
    // necesito saber si el accum2 original era pos o neg
    // lo guardamos? No, pero si accum2 original era <0 escribimos neg y neg(x27)
    // para evitar complicaciones, volvemos a leer la tendencia desde x27 actual
    // si escribimos '-' antes es porque era negativo, si no, era positivo o 0
    // el truco: si escribimos el '-', x27 es ahora el abs y el trend es DOWN
    // si no escribimos el '-', x27 sigue siendo el valor y lo comparamos
    // Solucion limpia: guardar el signo antes de modificar x27

    // re-leer accum2 de la pila... pero no lo guardamos
    // usamos una variable auxiliar: recuperamos accum_diff2 del stack
    // En realidad no lo pusimos en stack. Lo mantenemos en x27 antes del neg.
    // Para solucionarlo correctamente comparo el buf_acc2 primer caracter:
    // si tiene '-' entonces trend es DOWN, si no, comparamos x27 vs 0
    adr x0, buf_acc2
    ldrb w1, [x0]
    cmp w1, #45                     // 45 = '-'
    beq .trend2_down

    cmp x27, #0
    beq .trend2_stable
    bl .copiar_trend_up
    b .escribir_archivo

.trend2_down:
    bl .copiar_trend_down
    b .escribir_archivo

.trend2_stable:
    bl .copiar_trend_stable

.escribir_archivo:
    // libero el espacio de la pila que reserve
    add sp, sp, #64

    // ---------------------------------------------------------
    // Paso 7: escribo el buffer en resultado_tendencia.txt
    // ---------------------------------------------------------
    mov x8, #56
    mov x0, #-100
    adr x1, nombre_salida
    mov x2, #577
    mov x3, #0644
    svc #0
    mov x10, x0

    mov x8, #64
    mov x0, x10
    adr x1, buffer_salida
    mov x2, x9
    svc #0

    mov x8, #57
    mov x0, x10
    svc #0

    // tambien lo muestro en pantalla
    mov x8, #64
    mov x0, #1
    adr x1, buffer_salida
    mov x2, x9
    svc #0

    mov x8, #93
    mov x0, #0
    svc #0


// ============================================================
// Funciones para copiar texto al buffer_salida
// Todas usan x9 como posicion actual
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

.copiar_area1:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, str_area1
.lp_a1:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_a1
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_a1
.fin_a1:
    ldp x29, x30, [sp], #16
    ret

.copiar_area2:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, str_area2
.lp_a2:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_a2
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_a2
.fin_a2:
    ldp x29, x30, [sp], #16
    ret

.copiar_separador:
    stp x29, x30, [sp, #-16]!
    adr x0, buffer_salida
    adr x1, str_separador
.lp_sep:
    ldrb w2, [x1]
    cmp w2, #0
    beq .fin_sep
    strb w2, [x0, x9]
    add x9, x9, #1
    add x1, x1, #1
    b .lp_sep
.fin_sep:
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
