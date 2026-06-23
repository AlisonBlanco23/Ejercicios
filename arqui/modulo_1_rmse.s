// modulo_1_rmse.s
//
// Rutina 1: RMSE respecto a un valor ideal (seccion 4.19.1)
//
// Uso:
//   ./modulo_1_rmse archivo linea_inicial linea_final columna_sensor
//
// IDEAL es una constante fija definida en .data (.quad), tal como se
// indico: no se recibe por argumento.
//
// Formulas:
//   ERROR_i  = Y_i - IDEAL
//   ERROR2_i = ERROR_i * ERROR_i
//   MSE      = suma(ERROR2_i) / N        (division entera truncada)
//   RMSE     = sqrt_entera(MSE)
//
// Salida (STATUS=OK):
//   CALC=RMSE
//   COLUMN=<col>
//   WINDOW_START=<linea_inicial>
//   WINDOW_END=<linea_final>
//   COUNT=<N>
//   IDEAL=<ideal>
//   RMSE=<valor>
//   STATUS=OK
//
// Salida (error):
//   CALC=RMSE
//   STATUS=ERROR
//   ERROR=<codigo>
//   DETAIL=<detalle>
//
// IMPORTANTE - seguridad de registros:
//   read_column_to_stack (en utils.s) usa internamente x19,x20,x21,x22,x23
//   ademas del rango x0-x18. Por lo tanto NINGUN valor propio puede
//   guardarse en x0-x23 antes de llamarla y esperar que sobreviva.
//   Los valores de entrada (linea_inicial, linea_final, columna) se
//   guardan en .bss ANTES de llamar a read_column_to_stack, y se
//   recargan desde .bss DESPUES de la llamada.
//   Para el tramo posterior se usan x24-x27 (utils.s no los toca).
//   int_a_ascii SI preserva x19/x20 (hace stp/ldp), por lo que es seguro
//   llamarla con datos guardados en otros registros.

.data

IDEAL:
    .quad 55          // valor ideal de referencia (ajustar segun documentacion del grupo)

msg_calc:
    .ascii "CALC=RMSE\n"
    len_msg_calc = . - msg_calc

msg_column:
    .ascii "COLUMN="
    len_msg_column = . - msg_column

msg_wstart:
    .ascii "WINDOW_START="
    len_msg_wstart = . - msg_wstart

msg_wend:
    .ascii "WINDOW_END="
    len_msg_wend = . - msg_wend

msg_count:
    .ascii "COUNT="
    len_msg_count = . - msg_count

msg_ideal:
    .ascii "IDEAL="
    len_msg_ideal = . - msg_ideal

msg_rmse:
    .ascii "RMSE="
    len_msg_rmse = . - msg_rmse

msg_status_ok:
    .ascii "STATUS=OK\n"
    len_msg_status_ok = . - msg_status_ok

msg_status_error:
    .ascii "STATUS=ERROR\n"
    len_msg_status_error = . - msg_status_error

msg_err_label:
    .ascii "ERROR="
    len_msg_err_label = . - msg_err_label

msg_detail_label:
    .ascii "DETAIL="
    len_msg_detail_label = . - msg_detail_label

err_args:
    .ascii "INVALID_ARGS\n"
    len_err_args = . - err_args

detail_args:
    .ascii "EXPECTED_4_ARGS\n"
    len_detail_args = . - detail_args

err_insufficient:
    .ascii "INSUFFICIENT_DATA\n"
    len_err_insufficient = . - err_insufficient

detail_insufficient:
    .ascii "RMSE_REQUIRES_AT_LEAST_2_VALUES\n"
    len_detail_insufficient = . - detail_insufficient

newline:
    .ascii "\n"

.bss

ascii_buffer:
    .skip 32

// almacenamiento temporal de los argumentos de entrada, guardados
// ANTES de llamar a read_column_to_stack (que destruye x19-x23)
saved_linea_inicial:
    .skip 8
saved_linea_final:
    .skip 8
saved_columna:
    .skip 8

.text

.global _start
.extern read_column_to_stack
.extern int_a_ascii
.extern ascii_a_int

_start:
    // En _start (sin libc), argc y argv estan en el stack al iniciar:
    //   [sp]      = argc
    //   [sp + 8]  = argv[0] (nombre del programa)
    //   [sp + 16] = argv[1] (archivo)
    //   [sp + 24] = argv[2] (linea_inicial)
    //   [sp + 32] = argv[3] (linea_final)
    //   [sp + 40] = argv[4] (columna)
    ldr x0, [sp]              // x0 = argc

    cmp x0, #5
    bne modulo1_error_args

    ldr x17, [sp, #16]        // x17 = puntero a nombre de archivo (argv[1])

    ldr x0, [sp, #24]         // argv[2] = linea_inicial (string)
    bl ascii_a_int
    mov x12, x0               // x12 = linea_inicial

    ldr x0, [sp, #32]         // argv[3] = linea_final (string)
    bl ascii_a_int
    mov x13, x0               // x13 = linea_final

    ldr x0, [sp, #40]         // argv[4] = columna (string)
    bl ascii_a_int
    mov x11, x0               // x11 = columna_sensor

    // guardar argumentos en .bss ANTES de llamar a read_column_to_stack,
    // porque esa rutina destruye x19-x23 (y el resto de x0-x18)
    ldr x4, =saved_linea_inicial
    str x12, [x4]
    ldr x4, =saved_linea_final
    str x13, [x4]
    ldr x4, =saved_columna
    str x11, [x4]

    bl read_column_to_stack
    // x0 = inicio datos (mas reciente), x1 = limite superior,
    // x2 = N, x3 = posicion restore

    mov x24, x0               // x24 = puntero inicio datos en stack
    mov x25, x2               // x25 = N
    mov x26, x3               // x26 = posicion para restaurar stack

    cmp x25, #2
    blt modulo1_error_insufficient

    // recargar argumentos guardados
    ldr x4, =saved_linea_inicial
    ldr x27, [x4]              // x27 = linea_inicial (para salida)

    // ---- calcular suma de ERROR2_i ----
    ldr x4, =IDEAL
    ldr x29, [x4]              // x29 = IDEAL (registro estable, int_a_ascii no lo toca)

    mov x4, #0                // x4 = acumulador suma(ERROR2_i)
    mov x5, x24                // x5 = puntero recorrido
    mov x6, #0                // x6 = contador de elementos recorridos

modulo1_sum_loop:
    cmp x6, x25
    bge modulo1_sum_done

    ldr x7, [x5]              // Y_i
    sub x7, x7, x29            // ERROR_i = Y_i - IDEAL
    mul x7, x7, x7            // ERROR2_i
    add x4, x4, x7            // acumular

    add x5, x5, #16           // siguiente dato (cada dato ocupa 16 bytes en el stack)
    add x6, x6, #1
    b modulo1_sum_loop

modulo1_sum_done:
    // MSE = suma / N  (division entera truncada)
    udiv x10, x4, x25          // x10 = MSE (valores no negativos, division simple)

    // restaurar stack usado por read_column_to_stack (ya no necesitamos
    // los datos apuntados por x24)
    mov sp, x26

    // RMSE = sqrt_entera(MSE)
    mov x0, x10
    bl sqrt_entera
    mov x28, x0                // x28 = RMSE

    // ---- imprimir salida OK ----
    mov x0, #1
    ldr x1, =msg_calc
    mov x2, len_msg_calc
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =msg_column
    mov x2, len_msg_column
    mov x8, #64
    svc #0

    ldr x4, =saved_columna
    ldr x4, [x4]
    mov x0, x4
    ldr x1, =ascii_buffer
    bl int_a_ascii
    bl modulo1_print_ascii_nl

    mov x0, #1
    ldr x1, =msg_wstart
    mov x2, len_msg_wstart
    mov x8, #64
    svc #0

    mov x0, x27
    ldr x1, =ascii_buffer
    bl int_a_ascii
    bl modulo1_print_ascii_nl

    mov x0, #1
    ldr x1, =msg_wend
    mov x2, len_msg_wend
    mov x8, #64
    svc #0

    ldr x4, =saved_linea_final
    ldr x4, [x4]
    mov x0, x4
    ldr x1, =ascii_buffer
    bl int_a_ascii
    bl modulo1_print_ascii_nl

    mov x0, #1
    ldr x1, =msg_count
    mov x2, len_msg_count
    mov x8, #64
    svc #0

    mov x0, x25
    ldr x1, =ascii_buffer
    bl int_a_ascii
    bl modulo1_print_ascii_nl

    mov x0, #1
    ldr x1, =msg_ideal
    mov x2, len_msg_ideal
    mov x8, #64
    svc #0

    mov x0, x29
    ldr x1, =ascii_buffer
    bl int_a_ascii
    bl modulo1_print_ascii_nl

    mov x0, #1
    ldr x1, =msg_rmse
    mov x2, len_msg_rmse
    mov x8, #64
    svc #0

    mov x0, x28
    ldr x1, =ascii_buffer
    bl int_a_ascii
    bl modulo1_print_ascii_nl

    mov x0, #1
    ldr x1, =msg_status_ok
    mov x2, len_msg_status_ok
    mov x8, #64
    svc #0

    mov x0, #0
    mov x8, #93
    svc #0

// Imprime el contenido de ascii_buffer (terminado en NUL) seguido de '\n'.
// Usa x10-x12 como working registers; no toca x24-x28 ni x9/x27
// (los registros donde el caller mantiene sus valores vivos).
modulo1_print_ascii_nl:
    str x30, [sp, #-16]!       // guardar return address en el stack
    ldr x11, =ascii_buffer

modulo1_print_strlen:
    ldrb w12, [x11], #1
    cmp w12, #0
    bne modulo1_print_strlen

    sub x11, x11, #1
    ldr x12, =ascii_buffer
    sub x2, x11, x12           // longitud de la cadena

    mov x0, #1
    ldr x1, =ascii_buffer
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =newline
    mov x2, #1
    mov x8, #64
    svc #0

    ldr x30, [sp], #16
    ret

// sqrt_entera: raiz cuadrada entera truncada
// Mismo algoritmo dado en clase, convertido a subrutina (bl/ret en vez
// de _start/svc exit) para poder llamarlo desde dentro del modulo.
// x0 = numero de entrada, x0 = resultado
sqrt_entera:
    mov x1, x0        // x1 = numero del que se busca raiz (se preserva)
    mov x4, #1        // x4 = iterador (candidato a raiz)

sqrt_entera_loop:
    mul x2, x4, x4    // x2 = x4 * x4
    cmp x2, x1        // x2 > x1 ?
    bgt sqrt_entera_fin
    add x4, x4, #1
    b sqrt_entera_loop

sqrt_entera_fin:
    // el add anterior siempre nos deja una posicion arriba del
    // resultado correcto, por eso restamos uno
    sub x0, x4, #1
    ret

// ---- manejo de errores ----

modulo1_error_args:
    bl modulo1_print_error_header

    mov x0, #1
    ldr x1, =msg_err_label
    mov x2, len_msg_err_label
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =err_args
    mov x2, len_err_args
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =msg_detail_label
    mov x2, len_msg_detail_label
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =detail_args
    mov x2, len_detail_args
    mov x8, #64
    svc #0

    mov x0, #1
    mov x8, #93
    svc #0

modulo1_error_insufficient:
    mov sp, x26

    bl modulo1_print_error_header

    mov x0, #1
    ldr x1, =msg_err_label
    mov x2, len_msg_err_label
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =err_insufficient
    mov x2, len_err_insufficient
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =msg_detail_label
    mov x2, len_msg_detail_label
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =detail_insufficient
    mov x2, len_detail_insufficient
    mov x8, #64
    svc #0

    mov x0, #1
    mov x8, #93
    svc #0

modulo1_print_error_header:
    str x30, [sp, #-16]!

    mov x0, #1
    ldr x1, =msg_calc
    mov x2, len_msg_calc
    mov x8, #64
    svc #0

    mov x0, #1
    ldr x1, =msg_status_error
    mov x2, len_msg_status_error
    mov x8, #64
    svc #0

    ldr x30, [sp], #16
    ret
