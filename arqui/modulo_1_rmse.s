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
//   RMSE     = raiz_entera(MSE)
//
// Salida (STATUS=OK):
//   Se escribe unicamente al archivo resultado_rmse.txt (creado/truncado
//   en el directorio de trabajo actual). Sin stdout: stdout es exclusivo
//   del motor en vivo (Componente A), segun acuerdo del equipo.
//   El formato de los campos (CALC=, STATUS=, ERROR=, etc.) sigue
//   exactamente el contrato definido en el enunciado, por lo que NO se
//   traduce: solo se tradujeron los nombres internos de etiquetas y
//   variables, no el texto que se imprime.
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
//   Para el tramo posterior se usan x24-x29 (utils.s no los toca).
//   int_a_ascii SI preserva x19/x20 (hace stp/ldp), por lo que es seguro
//   llamarla con datos guardados en otros registros.

.data

IDEAL:
    .quad 55          // valor ideal de referencia (ajustar segun documentacion del grupo)

nombre_archivo_salida:
    .asciz "resultado_rmse.txt"

texto_calc:
    .ascii "CALC=RMSE\n"
    len_texto_calc = . - texto_calc

texto_columna:
    .ascii "COLUMN="
    len_texto_columna = . - texto_columna

texto_inicio_ventana:
    .ascii "WINDOW_START="
    len_texto_inicio_ventana = . - texto_inicio_ventana

texto_fin_ventana:
    .ascii "WINDOW_END="
    len_texto_fin_ventana = . - texto_fin_ventana

texto_cantidad:
    .ascii "COUNT="
    len_texto_cantidad = . - texto_cantidad

texto_ideal:
    .ascii "IDEAL="
    len_texto_ideal = . - texto_ideal

texto_rmse:
    .ascii "RMSE="
    len_texto_rmse = . - texto_rmse

texto_estado_ok:
    .ascii "STATUS=OK\n"
    len_texto_estado_ok = . - texto_estado_ok

texto_estado_error:
    .ascii "STATUS=ERROR\n"
    len_texto_estado_error = . - texto_estado_error

texto_etiqueta_error:
    .ascii "ERROR="
    len_texto_etiqueta_error = . - texto_etiqueta_error

texto_etiqueta_detalle:
    .ascii "DETAIL="
    len_texto_etiqueta_detalle = . - texto_etiqueta_detalle

error_args:
    .ascii "INVALID_ARGS\n"
    len_error_args = . - error_args

detalle_args:
    .ascii "EXPECTED_4_ARGS\n"
    len_detalle_args = . - detalle_args

error_datos_insuficientes:
    .ascii "INSUFFICIENT_DATA\n"
    len_error_datos_insuficientes = . - error_datos_insuficientes

detalle_datos_insuficientes:
    .ascii "RMSE_REQUIRES_AT_LEAST_2_VALUES\n"
    len_detalle_datos_insuficientes = . - detalle_datos_insuficientes

salto_linea:
    .ascii "\n"

.bss

buffer_ascii:
    .skip 32

// almacenamiento temporal de los argumentos de entrada, guardados
// ANTES de llamar a read_column_to_stack (que destruye x19-x23)
guardado_linea_inicial:
    .skip 8
guardado_linea_final:
    .skip 8
guardado_columna:
    .skip 8
// fd del archivo de salida resultado_rmse.txt (se abre una vez al inicio)
guardado_fd_salida:
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
    ldr x1, =nombre_archivo_salida
    mov x2, #577
    mov x3, #0644
    mov x8, #56
    svc #0

    ldr x4, =guardado_fd_salida
    str x0, [x4]              // guardar fd del archivo de salida

    ldr x0, [sp]              // x0 = argc

    cmp x0, #5
    bne rmse_error_args

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
    ldr x4, =guardado_linea_inicial
    str x12, [x4]
    ldr x4, =guardado_linea_final
    str x13, [x4]
    ldr x4, =guardado_columna
    str x11, [x4]

    bl read_column_to_stack
    // x0 = inicio datos (mas reciente), x1 = limite superior,
    // x2 = N, x3 = posicion restore

    mov x24, x0               // x24 = puntero inicio datos en stack
    mov x25, x2               // x25 = N
    mov x26, x3               // x26 = posicion para restaurar stack

    cmp x25, #2
    blt rmse_error_datos_insuficientes

    // recargar argumentos guardados
    ldr x4, =guardado_linea_inicial
    ldr x27, [x4]              // x27 = linea_inicial (para salida)

    // ---- calcular suma de ERROR2_i ----
    ldr x4, =IDEAL
    ldr x29, [x4]              // x29 = IDEAL (registro estable, int_a_ascii no lo toca)

    mov x4, #0                // x4 = acumulador suma(ERROR2_i)
    mov x5, x24                // x5 = puntero recorrido
    mov x6, #0                // x6 = contador de elementos recorridos

rmse_ciclo_suma:
    cmp x6, x25
    bge rmse_ciclo_suma_fin

    ldr x7, [x5]              // Y_i
    sub x7, x7, x29            // ERROR_i = Y_i - IDEAL
    mul x7, x7, x7            // ERROR2_i
    add x4, x4, x7            // acumular

    add x5, x5, #16           // siguiente dato (cada dato ocupa 16 bytes en el stack)
    add x6, x6, #1
    b rmse_ciclo_suma

rmse_ciclo_suma_fin:
    // MSE = suma / N  (division entera truncada)
    udiv x10, x4, x25          // x10 = MSE (valores no negativos, division simple)

    // restaurar stack usado por read_column_to_stack (ya no necesitamos
    // los datos apuntados por x24)
    mov sp, x26

    // RMSE = raiz_entera(MSE)
    mov x0, x10
    bl raiz_entera
    mov x28, x0                // x28 = RMSE

    // ---- escribir salida OK a resultado_rmse.txt ----
    ldr x0, =texto_calc
    mov x1, len_texto_calc
    bl rmse_escribir

    ldr x0, =texto_columna
    mov x1, len_texto_columna
    bl rmse_escribir

    ldr x4, =guardado_columna
    ldr x4, [x4]
    mov x0, x4
    ldr x1, =buffer_ascii
    bl int_a_ascii
    bl rmse_escribir_ascii_nl

    ldr x0, =texto_inicio_ventana
    mov x1, len_texto_inicio_ventana
    bl rmse_escribir

    mov x0, x27
    ldr x1, =buffer_ascii
    bl int_a_ascii
    bl rmse_escribir_ascii_nl

    ldr x0, =texto_fin_ventana
    mov x1, len_texto_fin_ventana
    bl rmse_escribir

    ldr x4, =guardado_linea_final
    ldr x4, [x4]
    mov x0, x4
    ldr x1, =buffer_ascii
    bl int_a_ascii
    bl rmse_escribir_ascii_nl

    ldr x0, =texto_cantidad
    mov x1, len_texto_cantidad
    bl rmse_escribir

    mov x0, x25
    ldr x1, =buffer_ascii
    bl int_a_ascii
    bl rmse_escribir_ascii_nl

    ldr x0, =texto_ideal
    mov x1, len_texto_ideal
    bl rmse_escribir

    mov x0, x29
    ldr x1, =buffer_ascii
    bl int_a_ascii
    bl rmse_escribir_ascii_nl

    ldr x0, =texto_rmse
    mov x1, len_texto_rmse
    bl rmse_escribir

    mov x0, x28
    ldr x1, =buffer_ascii
    bl int_a_ascii
    bl rmse_escribir_ascii_nl

    ldr x0, =texto_estado_ok
    mov x1, len_texto_estado_ok
    bl rmse_escribir

    // cerrar el archivo de salida antes de terminar
    ldr x4, =guardado_fd_salida
    ldr x0, [x4]
    mov x8, #57
    svc #0

    mov x0, #0
    mov x8, #93
    svc #0

// rmse_escribir: escribe (puntero, longitud) al archivo resultado_rmse.txt
// (fd guardado en guardado_fd_salida). Solo .txt, sin stdout (el stdout
// es exclusivo del motor en vivo, segun acuerdo del equipo).
// Entrada: x0 = puntero al texto, x1 = longitud
// No usa x24-x29 (registros donde el caller mantiene sus valores vivos).
rmse_escribir:
    mov x2, x1
    mov x1, x0
    ldr x4, =guardado_fd_salida
    ldr x0, [x4]
    mov x8, #64
    svc #0
    ret

// rmse_escribir_ascii_nl: escribe el contenido de buffer_ascii (string
// terminado en NUL) seguido de un salto de linea, solo al archivo.
// No usa x24-x29.
rmse_escribir_ascii_nl:
    str x30, [sp, #-16]!
    ldr x11, =buffer_ascii

rmse_calcular_longitud:
    ldrb w12, [x11], #1
    cmp w12, #0
    bne rmse_calcular_longitud

    sub x11, x11, #1
    ldr x12, =buffer_ascii
    sub x1, x11, x12           // longitud de la cadena

    ldr x0, =buffer_ascii
    bl rmse_escribir

    ldr x0, =salto_linea
    mov x1, #1
    bl rmse_escribir

    ldr x30, [sp], #16
    ret

// raiz_entera: raiz cuadrada entera truncada
// Mismo algoritmo dado en clase, convertido a subrutina (bl/ret en vez
// de _start/svc exit) para poder llamarlo desde dentro del modulo.
// x0 = numero de entrada, x0 = resultado
raiz_entera:
    mov x1, x0        // x1 = numero del que se busca raiz (se preserva)
    mov x4, #1        // x4 = iterador (candidato a raiz)

raiz_entera_ciclo:
    mul x2, x4, x4    // x2 = x4 * x4
    cmp x2, x1        // x2 > x1 ?
    bgt raiz_entera_fin
    add x4, x4, #1
    b raiz_entera_ciclo

raiz_entera_fin:
    // el add anterior siempre nos deja una posicion arriba del
    // resultado correcto, por eso restamos uno
    sub x0, x4, #1
    ret

// ---- manejo de errores ----

// rmse_error_args: el archivo ya esta abierto en este punto (se abre
// antes de validar argc), por lo que el error tambien queda en el .txt.
rmse_error_args:
    ldr x0, =texto_calc
    mov x1, len_texto_calc
    bl rmse_escribir

    ldr x0, =texto_estado_error
    mov x1, len_texto_estado_error
    bl rmse_escribir

    ldr x0, =texto_etiqueta_error
    mov x1, len_texto_etiqueta_error
    bl rmse_escribir

    ldr x0, =error_args
    mov x1, len_error_args
    bl rmse_escribir

    ldr x0, =texto_etiqueta_detalle
    mov x1, len_texto_etiqueta_detalle
    bl rmse_escribir

    ldr x0, =detalle_args
    mov x1, len_detalle_args
    bl rmse_escribir

    // cerrar el archivo de salida antes de terminar
    ldr x4, =guardado_fd_salida
    ldr x0, [x4]
    mov x8, #57
    svc #0

    mov x0, #1
    mov x8, #93
    svc #0

// rmse_error_datos_insuficientes: ocurre DESPUES de abrir el archivo,
// por lo que aqui si se usa rmse_escribir para que el error tambien
// quede registrado en resultado_rmse.txt.
rmse_error_datos_insuficientes:
    mov sp, x26

    ldr x0, =texto_calc
    mov x1, len_texto_calc
    bl rmse_escribir

    ldr x0, =texto_estado_error
    mov x1, len_texto_estado_error
    bl rmse_escribir

    ldr x0, =texto_etiqueta_error
    mov x1, len_texto_etiqueta_error
    bl rmse_escribir

    ldr x0, =error_datos_insuficientes
    mov x1, len_error_datos_insuficientes
    bl rmse_escribir

    ldr x0, =texto_etiqueta_detalle
    mov x1, len_texto_etiqueta_detalle
    bl rmse_escribir

    ldr x0, =detalle_datos_insuficientes
    mov x1, len_detalle_datos_insuficientes
    bl rmse_escribir

    // cerrar el archivo de salida antes de terminar
    ldr x4, =guardado_fd_salida
    ldr x0, [x4]
    mov x8, #57
    svc #0

    mov x0, #1
    mov x8, #93
    svc #0
