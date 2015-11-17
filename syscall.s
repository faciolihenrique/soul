.global SYSCALL

.align 4
SYSCALL:
    cmp r7, #16
    beq SYS_READ_SONAR

    cmp r7, #17
    beq SYS_REG_PROX_CALLBACK

    cmp r7, #18
    beq SYS_SET_MOTOR_SPEED

    cmp r7, #19
    beq SYS_SET_MOTORS_SPEED

    cmp r7, #20
    beq SYS_GET_TIME

    cmp r7, #21
    beq SYS_SET_TIME

    cmp r7, #22
    beq SYS_SET_ALARM


.align 4
SYS_READ_SONAR:
    stmfd sp!, {r4-r11, lr}
    ldr r3, =GPIO_BASE

    @ Verifica se o valor passado é valido
    cmp r0, #0
    blt erro_sonar
    cmp r0, #16
    bge erro_sonar


    @ Faz um clear dos bits do sonar, do trigger e do  no GDIR
    ldr r2, [r3, #GPIO_GDIR]
    bic r2, r2, #0b00000000000000000000000000111110

    @ Sonar_mux <= sonar_id
    @ Shifta os bits até a posicao [6]
    @ Faz um E com o r2

    ldr r1, =0x0
    lsl r1, [r0, #5]
    and r2, r1, r2
    @ ESTOU COM PROBLEMA PARA CONTAR O TEMPO (15ms)
    @ Faz um E com r2 e 2 para setar o trigger = 1
    and r2, r2, #0x02

    @ Deveria esperar 15 ms
    @ Desativa o trigger
    eor r2, r2, #0x02

read_sonar_loop:
    @ Delay 10 ms
    @ Faz um check da flag (que esta em psr)
    ldr r1, [r3, #GPIO_PSR]
    @ Falta fazer um check desse 1 :)
    bic r2, r1, #0x01
    beq r2, #0x01

    @ Armazena os valores da leitura do sonar
    bic r2, r1, #0b00000000000000011111111111000000
    lsr r2, [r2, #6]

    mov r0, r2

    b END

erro_sonar:
    ldr r0, =-1
    b END

.align 4
SYS_REG_PROX_CALLBACK:

.align 4
SYS_SET_MOTOR_SPEED:

.align 4
SYS_SET_MOTORS_SPEED:

    stmfd sp!, {r4-r11. lr}

    @ Passa o valor de r0 para um auxiliar e compara se é um valor valido de velocidade
    mov r2, r0
    cmp r0, #63
    mov r0, #-1
    bgt END

    cmp r1, #63
    mov r0, #-2
    bgt END

    @coloca o valor de r2 na posicao de memoria correspondente do motor r0
    mov r3, #0
    @desloca o valor 7 bits, para cair na faixa do motor 0, com 0 no valor de write (talvez bit de write)
    add r3, r3, r2,lsl #7
    @soma o valor de r1, que ja vai ficar no local correto
    add r3, r3, r1

    @passa endereco armazenar nos dados
    ldr r4, =GPIO_BASE
    str r3, [r4, GPIO_DR] @VIRAS, coloquei o gpio_dr só para o codigo ficar mais legivel :) -- APAGUE ESTE COMENTARIO DEPOIS DE LIDO <3
    mov r0, #0

    b END


@ Retorna o valor do tempo do sistema
.align 4
SYS_GET_TIME:
    stmfd sp!, {r4-r11, lr}
    @ Passa a posicao de memoria do contador e a carrega em r0
    ldr r1, =TIME_COUNTER
    mov r0, [r1]

    b END

@ Define o contador de tempo do sistema
.align 4
SYS_SET_TIME:
    stmfd sp!, {r4-r11, lr}
    @ Pega o conteudo de r0, parametro, e coloca no tempo
    ldr r1, =TIME_COUNTER
    str r0, [r1]

    b END

.align 4
SYS_SET_ALARM:



END:
    ldmfd sp!, {r4-r11, lr}
    movs pc, lr
