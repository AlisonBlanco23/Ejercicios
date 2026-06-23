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
//   Se escribe unicamente al archivo resultado_rmse.txt (creado/truncado
//   en el directorio de trabajo actual). Sin stdout: stdout es exclusivo
//   del motor en vivo (Componente A), segun acuerdo del equipo.
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
//   Igual, unicamente a resultado_rmse.txt:
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

output_filename:
    .asciz "resultado_rmse.txt"

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
// fd del archivo de salida resultado_rmse.txt (se abre una vez al inicio)
saved_output_fd:
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

    // abrir (crear/truncar) resultado_rmse.txt ANTES de cualquier otra
    // cosa, para que cualquier error (incluso de argumentos) pueda
    // quedar registrado en el archivo, ya que ya no se usa stdout.
    // openat(AT_FDCWD=-100, pathname, flags, mode)
    //   flags = O_WRONLY(1) | O_CREAT(64) | O_TRUNC(512) = 577
    mov x0, #-100
    ldr x1, =output_filename
    mov x2, #577
    mov x3, #0644
    mov x8, #56
    svc #0

    ldr x4, =saved_output_fd
    str x0, [x4]              // guardar fd del archivo de salida

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

    // ---- imprimir salida OK (a stdout y a resultado_rmse.txt) ----
    ldr x0, =msg_calc
    mov x1, len_msg_calc
    bl modulo1_write

    ldr x0, =msg_column
    mov x1, len_msg_column
    bl modulo1_write

    ldr x4, =saved_columna
    ldr x4, [x4]
    mov x0, x4
    ldr x1, =ascii_buffer
    bl int_a_ascii
    bl modulo1_write_ascii_nl

    ldr x0, =msg_wstart
    mov x1, len_msg_wstart
    bl modulo1_write

    mov x0, x27
    ldr x1, =ascii_buffer
    bl int_a_ascii
    bl modulo1_write_ascii_nl

    ldr x0, =msg_wend
    mov x1, len_msg_wend
    bl modulo1_write

    ldr x4, =saved_linea_final
    ldr x4, [x4]
    mov x0, x4
    ldr x1, =ascii_buffer
    bl int_a_ascii
    bl modulo1_write_ascii_nl

    ldr x0, =msg_count
    mov x1, len_msg_count
    bl modulo1_write

    mov x0, x25
    ldr x1, =ascii_buffer
    bl int_a_ascii
    bl modulo1_write_ascii_nl

    ldr x0, =msg_ideal
    mov x1, len_msg_ideal
    bl modulo1_write

    mov x0, x29
    ldr x1, =ascii_buffer
    bl int_a_ascii
    bl modulo1_write_ascii_nl

    ldr x0, =msg_rmse
    mov x1, len_msg_rmse
    bl modulo1_write

    mov x0, x28
    ldr x1, =ascii_buffer
    bl int_a_ascii
    bl modulo1_write_ascii_nl

    ldr x0, =msg_status_ok
    mov x1, len_msg_status_ok
    bl modulo1_write

    // cerrar el archivo de salida antes de terminar
    ldr x4, =saved_output_fd
    ldr x0, [x4]
    mov x8, #57
    svc #0

    mov x0, #0
    mov x8, #93
    svc #0

// modulo1_write: escribe (puntero, longitud) al archivo resultado_rmse.txt
// (fd guardado en saved_output_fd). Solo .txt, sin stdout (el stdout es
// exclusivo del motor en vivo, segun acuerdo del equipo).
// Entrada: x0 = puntero al texto, x1 = longitud
// No usa x24-x29 (registros donde el caller mantiene sus valores vivos).
modulo1_write:
    mov x2, x1
    mov x1, x0
    ldr x4, =saved_output_fd
    ldr x0, [x4]
    mov x8, #64
    svc #0
    ret

// modulo1_write_ascii_nl: escribe el contenido de ascii_buffer (string
// terminado en NUL) seguido de un salto de linea, solo al archivo.
// No usa x24-x29.
modulo1_write_ascii_nl:
    str x30, [sp, #-16]!
    ldr x11, =ascii_buffer

modulo1_write_strlen:
    ldrb w12, [x11], #1
    cmp w12, #0
    bne modulo1_write_strlen

    sub x11, x11, #1
    ldr x12, =ascii_buffer
    sub x1, x11, x12           // longitud de la cadena

    ldr x0, =ascii_buffer
    bl modulo1_write

    ldr x0, =newline
    mov x1, #1
    bl modulo1_write

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

// modulo1_error_args: el archivo ya esta abierto en este punto (se abre
// antes de validar argc), por lo que el error tambien queda en el .txt.
modulo1_error_args:
    ldr x0, =msg_calc
    mov x1, len_msg_calc
    bl modulo1_write

    ldr x0, =msg_status_error
    mov x1, len_msg_status_error
    bl modulo1_write

    ldr x0, =msg_err_label
    mov x1, len_msg_err_label
    bl modulo1_write

    ldr x0, =err_args
    mov x1, len_err_args
    bl modulo1_write

    ldr x0, =msg_detail_label
    mov x1, len_msg_detail_label
    bl modulo1_write

    ldr x0, =detail_args
    mov x1, len_detail_args
    bl modulo1_write

    // cerrar el archivo de salida antes de terminar
    ldr x4, =saved_output_fd
    ldr x0, [x4]
    mov x8, #57
    svc #0

    mov x0, #1
    mov x8, #93
    svc #0

// modulo1_error_insufficient: ocurre DESPUES de abrir el archivo, por lo
// que aqui si se usa modulo1_write para que el error tambien quede
// registrado en resultado_rmse.txt.
modulo1_error_insufficient:
    mov sp, x26

    ldr x0, =msg_calc
    mov x1, len_msg_calc
    bl modulo1_write

    ldr x0, =msg_status_error
    mov x1, len_msg_status_error
    bl modulo1_write

    ldr x0, =msg_err_label
    mov x1, len_msg_err_label
    bl modulo1_write

    ldr x0, =err_insufficient
    mov x1, len_err_insufficient
    bl modulo1_write

    ldr x0, =msg_detail_label
    mov x1, len_msg_detail_label
    bl modulo1_write

    ldr x0, =detail_insufficient
    mov x1, len_detail_insufficient
    bl modulo1_write

    // cerrar el archivo de salida antes de terminar
    ldr x4, =saved_output_fd
    ldr x0, [x4]
    mov x8, #57
    svc #0

    mov x0, #1
    mov x8, #93
    svc #0