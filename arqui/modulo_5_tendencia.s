// ============================================================
// modulo_5_tendencia.s
// Integrante 5 - Tendencia Acumulada Avanzada
// Curso: ACYE1 - Segundo Semestre 2026
//
// Variables analizadas:
//   - HUM_SUELO_1 (columna 3)
//   - HUM_SUELO_2 (columna 4)
//
// Entrada : lecturas.csv
// Salida  : resultado_tendencia.txt
//
// Formulas:
//   DIF_i    = X_i - X_(i-1)
//   DIF_ACUM = Suma de todos los DIF_i
//   DIF_ACUM > 0 => TREND=UP
//   DIF_ACUM < 0 => TREND=DOWN
//   DIF_ACUM = 0 => TREND=STABLE
//
// Funciones que uso de utils.s:
//   leer_datos   -> abre el CSV, extrae la columna pedida y llena datos[]
//   int_a_ascii  -> convierte un entero a texto ASCII
//   datos        -> arreglo global con los 30 valores leidos
//
// Compilar:
//   aarch64-linux-gnu-as utils.s -o utils.o
//   aarch64-linux-gnu-as modulo_5_tendencia.s -o modulo_5_tendencia.o
//   aarch64-linux-gnu-ld utils.o modulo_5_tendencia.o -o modulo_5_tendencia
//
// Ejecutar:
//   qemu-aarch64 ./modulo_5_tendencia
//   cat resultado_tendencia.txt
// ============================================================

.extern leer_datos
.extern int_a_ascii
.extern datos

// ---- Syscalls ---------------------------------------------
.equ SYS_OPENAT,  56
.equ SYS_CLOSE,   57
.equ SYS_WRITE,   64
.equ SYS_EXIT,    93
.equ AT_FDCWD,   -100
.equ O_WRONLY,    1
.equ O_CREAT,     64
.equ O_TRUNC,     512
.equ PERM_644,    0644

.equ N_DATOS,     30

// ===========================================================
// SECCION DE DATOS
// ===========================================================
.section .data

archivo_salida:   .asciz "resultado_tendencia.txt"

str_module:       .ascii "MODULE=ADVANCED_TREND\n"
.equ str_module_len, . - str_module

str_total:        .ascii "TOTAL_VALUES=30\n"
.equ str_total_len, . - str_total

str_sep:          .ascii "---\n"
.equ str_sep_len, . - str_sep

str_area1:        .ascii "AREA=HUM_SUELO_1\n"
.equ str_area1_len, . - str_area1

str_area2:        .ascii "AREA=HUM_SUELO_2\n"
.equ str_area2_len, . - str_area2

str_inc_lbl:      .ascii "INCREMENTS="
.equ str_inc_lbl_len, . - str_inc_lbl

str_dec_lbl:      .ascii "DECREMENTS="
.equ str_dec_lbl_len, . - str_dec_lbl

str_mup_lbl:      .ascii "MAX_UP_STREAK="
.equ str_mup_lbl_len, . - str_mup_lbl

str_mdn_lbl:      .ascii "MAX_DOWN_STREAK="
.equ str_mdn_lbl_len, . - str_mdn_lbl

str_acc_lbl:      .ascii "ACCUM_DIFF="
.equ str_acc_lbl_len, . - str_acc_lbl

str_trend_up:     .ascii "TREND=UP\n"
.equ str_trend_up_len, . - str_trend_up

str_trend_down:   .ascii "TREND=DOWN\n"
.equ str_trend_down_len, . - str_trend_down

str_trend_stable: .ascii "TREND=STABLE\n"
.equ str_trend_stable_len, . - str_trend_stable

str_minus:        .ascii "-"

// ===========================================================
// SECCION BSS
// ===========================================================
.section .bss

buf_conv:         .skip 32      // buffer para convertir int a ASCII

// Guardo aqui los datos de suelo1 antes de llamar leer_datos
// por segunda vez, porque leer_datos sobreescribe datos[]
arr_suelo1:       .skip 240     // 30 x 8 bytes

// Resultados HUM_SUELO_1
s1_increments:    .skip 8
s1_decrements:    .skip 8
s1_max_up:        .skip 8
s1_max_down:      .skip 8
s1_accum_diff:    .skip 8

// Resultados HUM_SUELO_2
s2_increments:    .skip 8
s2_decrements:    .skip 8
s2_max_up:        .skip 8
s2_max_down:      .skip 8
s2_accum_diff:    .skip 8

fd_out:           .skip 8

// ===========================================================
// SECCION DE CODIGO
// ===========================================================
.section .text
.global _start

// -----------------------------------------------------------
// _start - punto de entrada
// -----------------------------------------------------------
_start:
    // 1. Leer HUM_SUELO_1 usando utils.s
    //    leer_datos abre el CSV, extrae columna 3 y llena datos[]
    mov  x0,  #3
    bl   leer_datos

    // 2. Copiar datos[] a arr_suelo1 antes de que la siguiente
    //    llamada a leer_datos los sobreescriba
    adr  x0,  datos
    adr  x1,  arr_suelo1
    mov  x2,  #0
copiar_suelo1:
    cmp  x2,  #30
    beq  fin_copiar
    ldr  x3,  [x0, x2, lsl #3]
    str  x3,  [x1, x2, lsl #3]
    add  x2,  x2,  #1
    b    copiar_suelo1
fin_copiar:

    // 3. Leer HUM_SUELO_2 usando utils.s
    //    ahora datos[] tiene los valores de suelo 2
    mov  x0,  #4
    bl   leer_datos

    // 4. Calcular tendencia HUM_SUELO_1
    adr  x0,  arr_suelo1
    adr  x1,  s1_increments
    bl   calcular_tendencia

    // 5. Calcular tendencia HUM_SUELO_2
    adr  x0,  datos
    adr  x1,  s2_increments
    bl   calcular_tendencia

    // 6. Escribir resultado
    bl   escribir_resultado

    // 7. Salir
    mov  x8,  SYS_EXIT
    mov  x0,  #0
    svc  0


// ===========================================================
// SUBRUTINA: calcular_tendencia
//
// Recibe un arreglo de 30 datos y calcula:
//   incrementos, decrementos, max racha up/down, accum_diff
//
// Parametros:
//   x0 = puntero al arreglo de datos
//   x1 = puntero al bloque de resultados (5 valores x 8 bytes)
//
// Registros:
//   x19 = arreglo de datos
//   x20 = bloque de resultados
//   x21 = indice i (empieza en 1)
//   x22 = incrementos
//   x23 = decrementos
//   x24 = racha_up actual
//   x25 = racha_down actual
//   x26 = max_up
//   x27 = max_down
//   x28 = accum_diff
// ===========================================================
calcular_tendencia:
    stp  x29, x30, [sp, #-96]!
    mov  x29, sp
    stp  x19, x20, [sp, #16]
    stp  x21, x22, [sp, #32]
    stp  x23, x24, [sp, #48]
    stp  x25, x26, [sp, #64]
    stp  x27, x28, [sp, #80]

    mov  x19, x0
    mov  x20, x1
    mov  x21, #1
    mov  x22, #0
    mov  x23, #0
    mov  x24, #0
    mov  x25, #0
    mov  x26, #0
    mov  x27, #0
    mov  x28, #0

ct_loop:
    cmp  x21, N_DATOS
    bge  ct_fin

    sub  x9,  x21, #1
    ldr  x10, [x19, x9,  lsl #3]   // datos[i-1]
    ldr  x9,  [x19, x21, lsl #3]   // datos[i]
    sub  x11, x9,  x10             // DIF_i = datos[i] - datos[i-1]
    add  x28, x28, x11             // accum_diff += DIF_i

    cmp  x11, #0
    bgt  ct_incremento
    blt  ct_decremento

    mov  x24, #0
    mov  x25, #0
    b    ct_siguiente

ct_incremento:
    add  x22, x22, #1
    add  x24, x24, #1
    mov  x25, #0
    cmp  x24, x26
    ble  ct_siguiente
    mov  x26, x24
    b    ct_siguiente

ct_decremento:
    add  x23, x23, #1
    add  x25, x25, #1
    mov  x24, #0
    cmp  x25, x27
    ble  ct_siguiente
    mov  x27, x25

ct_siguiente:
    add  x21, x21, #1
    b    ct_loop

ct_fin:
    str  x22, [x20, #0]
    str  x23, [x20, #8]
    str  x26, [x20, #16]
    str  x27, [x20, #24]
    str  x28, [x20, #32]

    ldp  x27, x28, [sp, #80]
    ldp  x25, x26, [sp, #64]
    ldp  x23, x24, [sp, #48]
    ldp  x21, x22, [sp, #32]
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #96
    ret


// ===========================================================
// SUBRUTINA: escribir_resultado
//
// Abre resultado_tendencia.txt y escribe los resultados
// de HUM_SUELO_1 y HUM_SUELO_2 llamando a escribir_bloque
// para cada uno.
// ===========================================================
escribir_resultado:
    stp  x29, x30, [sp, #-32]!
    stp  x19, x20, [sp, #16]
    mov  x29, sp

    mov  x8,  SYS_OPENAT
    mov  x0,  AT_FDCWD
    adr  x1,  archivo_salida
    mov  x2,  O_WRONLY | O_CREAT | O_TRUNC
    mov  x3,  PERM_644
    svc  0
    cmp  x0,  #0
    blt  er_fin
    mov  x19, x0            // x19 = fd del archivo de salida

    adr  x0,  str_module
    mov  x1,  str_module_len
    bl   escribir_buf

    adr  x0,  str_total
    mov  x1,  str_total_len
    bl   escribir_buf

    // bloque HUM_SUELO_1
    adr  x0,  str_area1
    mov  x1,  str_area1_len
    bl   escribir_buf
    adr  x20, s1_increments
    bl   escribir_bloque

    adr  x0,  str_sep
    mov  x1,  str_sep_len
    bl   escribir_buf

    // bloque HUM_SUELO_2
    adr  x0,  str_area2
    mov  x1,  str_area2_len
    bl   escribir_buf
    adr  x20, s2_increments
    bl   escribir_bloque

    mov  x8,  SYS_CLOSE
    mov  x0,  x19
    svc  0

er_fin:
    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret


// ===========================================================
// SUBRUTINA: escribir_bloque
//
// Escribe los 5 campos de un bloque de resultados al archivo.
// x19 = fd ya abierto
// x20 = puntero al bloque [inc, dec, max_up, max_down, accum]
// ===========================================================
escribir_bloque:
    stp  x29, x30, [sp, #-16]!
    mov  x29, sp

    adr  x0,  str_inc_lbl
    mov  x1,  str_inc_lbl_len
    bl   escribir_buf
    ldr  x0,  [x20, #0]
    bl   escribir_uint_nl

    adr  x0,  str_dec_lbl
    mov  x1,  str_dec_lbl_len
    bl   escribir_buf
    ldr  x0,  [x20, #8]
    bl   escribir_uint_nl

    adr  x0,  str_mup_lbl
    mov  x1,  str_mup_lbl_len
    bl   escribir_buf
    ldr  x0,  [x20, #16]
    bl   escribir_uint_nl

    adr  x0,  str_mdn_lbl
    mov  x1,  str_mdn_lbl_len
    bl   escribir_buf
    ldr  x0,  [x20, #24]
    bl   escribir_uint_nl

    adr  x0,  str_acc_lbl
    mov  x1,  str_acc_lbl_len
    bl   escribir_buf
    ldr  x0,  [x20, #32]
    bl   escribir_int_nl    // este maneja negativos

    // TREND segun signo de accum_diff
    ldr  x0,  [x20, #32]
    cmp  x0,  #0
    bgt  eb_up
    blt  eb_down
    adr  x0,  str_trend_stable
    mov  x1,  str_trend_stable_len
    bl   escribir_buf
    b    eb_fin
eb_up:
    adr  x0,  str_trend_up
    mov  x1,  str_trend_up_len
    bl   escribir_buf
    b    eb_fin
eb_down:
    adr  x0,  str_trend_down
    mov  x1,  str_trend_down_len
    bl   escribir_buf
eb_fin:
    ldp  x29, x30, [sp], #16
    ret


// ===========================================================
// SUBRUTINA: escribir_buf
// Escribe x1 bytes desde x0 al archivo x19
// ===========================================================
escribir_buf:
    stp  x29, x30, [sp, #-16]!
    mov  x29, sp
    mov  x8,  SYS_WRITE
    mov  x2,  x1
    mov  x1,  x0
    mov  x0,  x19
    svc  0
    ldp  x29, x30, [sp], #16
    ret


// ===========================================================
// SUBRUTINA: escribir_uint_nl
// Convierte x0 (entero sin signo) a texto y escribe + '\n'
// Usa int_a_ascii de utils.s para la conversion
// ===========================================================
escribir_uint_nl:
    stp  x29, x30, [sp, #-16]!
    mov  x29, sp

    adr  x1,  buf_conv
    bl   int_a_ascii        // convierte x0 -> texto en buf_conv

    // calcular longitud del texto convertido
    adr  x0,  buf_conv
    mov  x1,  #0
eun_len:
    ldrb w2,  [x0, x1]
    cbz  w2,  eun_escribir
    add  x1,  x1,  #1
    b    eun_len
eun_escribir:
    // agregar \n al final del buffer
    mov  w2,  #10
    strb w2,  [x0, x1]
    add  x1,  x1,  #1

    bl   escribir_buf

    ldp  x29, x30, [sp], #16
    ret


// ===========================================================
// SUBRUTINA: escribir_int_nl
// Igual que escribir_uint_nl pero maneja numeros negativos.
// Si el numero es negativo escribe '-' primero y luego el abs
// ===========================================================
escribir_int_nl:
    stp  x29, x30, [sp, #-32]!
    stp  x19, x20, [sp, #16]
    mov  x29, sp

    cmp  x0,  #0
    bge  ein_positivo

    // escribir el signo '-' primero
    mov  x20, x0
    neg  x20, x20
    mov  x8,  SYS_WRITE
    mov  x0,  x19
    adr  x1,  str_minus
    mov  x2,  #1
    svc  0
    mov  x0,  x20           // ahora x0 tiene el valor absoluto

ein_positivo:
    bl   escribir_uint_nl

    ldp  x19, x20, [sp, #16]
    ldp  x29, x30, [sp], #32
    ret
