@ Lab Constants
.set MAX_ALARMS,            0x08
.set MAX_CALLBACKS,         0x08

.data
N_ALARMS: .word 0x0
ALARMS_VECTOR:

.text

@ SYS_READ_SONAR
@ Syscall que lê o valor de um sonar
@  -r0 : id do sonar (numero de 0 até 16)
@ retorna o valor medido pelo sonars
@ retorna -1 se o valor do sonar estiver incorreto
.align 4
SYS_READ_SONAR:

    stmfd sp!, {r4-r11, lr}
    @ Carrega a base do GPIO
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
    mov r1, r0, lsl #2
    orr r2, r1, r2
    str r2, [r5, #GPIO_DR]

    @ Delay de 15ms
    ldr r1, =TIME_COUNTER
    ldr r0, [r1]
    add r0, #15
    delay_1:
        ldr r4, [r1]
        cmp r0, r4
        bge delay_1

    @ Faz um OR com r2 e 2 para setar o trigger = 1
    orr r2, r2, #0x02
    str r2, [r5, #GPIO_DR]

    @ Delay de 5ms
    ldr r1, =TIME_COUNTER
    ldr r0, [r1]
    add r0, #5
    delay_2:
        ldr r4, [r1]
        cmp r0, r4
        bge delay_2

    @ Desativa o trigger após os 15ms
    bic r2, r2, #0x02
    str r2, [r5, #GPIO_DR]

    @Loop para verifica a cada 10ms se o flag foi modificada
    read_sonar_loop:
        @ Delay de 10ms
        ldr r1, =TIME_COUNTER
        ldr r0, [r1]
        add r0, #10
        delay_3:
            ldr r4, [r1]
            cmp r0, r4
            bge delay_3
        @ Faz um check da flag (que esta em psr)
        @ Verifica se o valor do flag está 1
        ldr r1, [r5, #GPIO_PSR]
        bic r2, r1, #0b11111111111111111111111111111110
        cmp r2, #0x01
        bne read_sonar_loop

    @ Pega os valores da leitura do sonar
    bic r0, r1, #0b11111111111111110000000000111111
    mov r0, r0, lsr #6

    b END

erro_sonar:
    ldr r0, =-1
    b END


.align 4
SYS_REG_PROX_CALLBACK:


.align 4
SYS_SET_MOTOR_SPEED:
    stmfd sp!, {r4-r11. lr}

    @ Verifica se os parametros passados são válidos
    @ velocidades
    cmp r1, #63
    movhi r0, #-2
    bhi END

    @ id dos motores
    cmp r0, #1
    movgt r0, #-1
    bgt END

    cmp r0, #0
    movlt r0, #-1
    blt END

    @ Prepara para colocar as informações no motor
    ldr r5, =GPIO_BASE
    ldr r4, [r5, #GPIO_DR]
    mov r3, #0

    @ Caso o motor seja o 0
    addeq r3, r3, r1, lsl #26
    biceq r4, r4, #0b00000000000000000000000000111111
    orreq r4, r4, r3
    streq r4, [r5, #GPIO_DR]

    @ Caso o motor seja o 1
    addgt r3, r3, r1, lsl #19
    bicgt r4, r4, #0b00000000000000000001111110000000
    orrgt r4, r4, r3
    strgt r4, [r5, #GPIO_DR]

    mov r0, #0
    b END


.align 4
SYS_SET_MOTORS_SPEED:

    stmfd sp!, {r4-r11. lr}

    @compara se é um valor valido de velocidade
    cmp r0, #63
    movhi r0, #-1
    bhi END

    cmp r1, #63
    movhi r0, #-2
    bhi END

    @coloca o valor de r2 na posicao de memoria correspondente do motor r0
    mov r3, #0
    @desloca o valor 26 bits, para cair na faixa do motor 0, com 0 no valor de write (talvez bit de write)
    add r3, r3, r1,lsl #26
    @soma o valor de r1, que ja vai ficar no local correto
    add r3, r3, r2,lsl #19

    @passa endereco armazenar nos dados
    ldr r5 =GPIO_BASE
    ldr r4, [r5, GPIO_DR]
    bic r4, r4, #0b00000000000000000001111110111111
    orr r4, r4, r3
    str r4, [r5, GPIO_DR]
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

    stmfd sp!, {r4-r11, lr}

    @ Primeiramente lê o número de alarmes já criados para saber em que posição colocar o próximo
    ldr r2, =N_ALARMS
    ldr r3, [r2]
    cmp r3, #8
    bgt erro_alarm



erro_alarm:
    mv r0, #-1

END:
    ldmfd sp!, {r4-r11, lr}
    movs pc, lr
