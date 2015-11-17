.global SYSCALL

.align 4
SYS_READ_SONAR:
    stmfd sp!, {r4-r11, lr}
    ldr r5, =GPIO_BASE

    @ Verifica se o valor passado é valido
    cmp r0, #0
    blt erro_sonar
    cmp r0, #16
    bge erro_sonar

    @ Faz um clear dos bits do sonar, do trigger e do  no GDIR
    ldr r2, [r5, #GPIO_DR]
    bic r2, r2,  #0b00000000000000000000000000111111

    @ Sonar_mux <= sonar_id
    @ r0 contem o sonar desejado
    @ Shifta os bits até a posicao [6]
    @ Faz um E com o r2

    ldr r1, =0x0
    lsl r1, [r0, #2]
    orr r2, r1, r2

    @ Delay de 15ms
    ldr r1, =TIME_COUNTER
    ldr r0, [r1]
    add r0, #15
delay1:
    ldr r4, [r1]
    cmp r0, r4
    bge delay1

    @ Faz um OR com r2 e 2 para setar o trigger = 1
    orr r2, r2, #0x02

    @ Delay de 15ms
    ldr r1, =TIME_COUNTER
    ldr r0, [r1]
    add r0, #15
delay2:
    ldr r4, [r1]
    cmp r0, r4
    bge delay2

    @ Desativa o trigger
    bic r2, r2, #0x02

read_sonar_loop:
    @ Delay 10 ms
    @ FALTA O DELAY
    @ Faz um check da flag (que esta em psr)
    ldr r1, [r5, #GPIO_PSR]
    @ Falta fazer um check desse 1 :)
    bic r2, r1, #0b11111111111111111111111111111110
    cmp r2, #0x01
    beq read_sonar_loop

    @ Pega os valores da leitura do sonar
    bic r2, r1, #0b11111111111111110000000000111111
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
    add r3, r3, r1,lsl #26
    @soma o valor de r1, que ja vai ficar no local correto
    add r3, r3, r2, #19

    @passa endereco armazenar nos dados
    ldr r5 =GPIO_BASE
    ldr r4, [r4, GPIO_DR]
    bic r4, r4, #0b00000000000000000001111110111111
    orr r4, r4, r3
    str r4, [r5, GPIO_DR]
    mov r0, #0

    b END

.align 4
SYS_REG_PROX_CALLBACK:

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
