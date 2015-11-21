@ Lab Constants
.set MAX_ALARMS,            0x08
.set MAX_CALLBACKS,         0x08
.set PSR_READ_SONARS,       0b11111111111111110000000000111111
.set DR_MOTORS,             0b00000000000000000001111110111111
.set PSR_FLAG,              0b00000000000000000000000000000001

.data
N_CALLBACKS: .word 0x0
SHIFT_CALLBACKS: .word 0x0

@criei esses vetores para guardar os valores das callbacks. ponteiros, limiares e identificadores
CALLBACK_ID_VECTOR: .fill 4*MAX_CALLBACKS
CALLBACK_DIST_VECTOR: .fill 4*MAX_CALLBACKS
CALLBACK_POITERS_VECTOR: .fill 4*MAX_CALLBACKS

@ Vetores que armazenas um ponteriro para uma função e o tempo que deve ser executado
N_ALARMS: .word 0x0
ALARMS_TIMER: .fill 4*MAX_ALARMS, 0
ALARMS_FUNCTIONS: .fill 4*MAX_ALARMS

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

    @ Faz um clear dos bits do sonar, do trigger e do FLAG no GDIR
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

    @ Delay de 15ms ((107Khz * 1 ms)/3)
    @ ldr r0, #535
    @ delay_15
    @   sub r0, r0, #1
    @   cmp r0, #0
    @   bgt delay_15

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
        bic r2, r1, #PSR_FLAG
        cmp r2, #0x01
        bne read_sonar_loop

    @ Pega os valores da leitura do sonar
    ldr r6, =PSR_FLAG
    bic r0, r1, r6
    mov r0, r0, lsr #6

    b END

erro_sonar:
    ldr r0, =-1
    b END


.align 4
SYS_REG_PROX_CALLBACK:
    stmfd sp!, {r4-r11, lr}

    @testa as condicoes de callbacks, registradores validos
    ldr r4, =N_CALLBACKS
    ldr r4, [r4]
    cmp r4, #MAX_CALLBACKS
    movgt r0, #-1
    bgt END

    cmp r2, #15
    movgt r0, #-2
    bgt END

    cmp r2, #0
    movlt r0, #-2
    blt END

    @carrega as posicoes que o comeco dos vetores estao na memoria
    ldr r3, =CALLBACK_ID_VECTOR
    ldr r4, =CALLBACK_DIST_VECTOR
    ldr r5, =CALLBACK_POITERS_VECTOR

    @salva o que foi passado pelo usuario, nas posicoes correspondentes de cada vetor
    ldr r6, =SHIFT_CALLBACKS

    str r0, [r3, r6]
    str r1, [r4, r6]
    str r2, [r5, r6]

    @coloca valor de retorno no r0
    mov r0, #0

    @adiciona valor para colocar valores nas posicoes corretas dos vetores
    @guarda novo valor do regitrador para deslocamento

    ldr r1, [r6]
    add r1, r1, #4
    str r1, [r6]

    @adiciona o contador de callbacks para posterior conferencia
    ldr r1, =N_CALLBACKS
    ldr r2, [r1]
    add r2, r2, #1
    str r2, [r1]

    b END

.align 4
SYS_SET_MOTOR_SPEED:
    stmfd sp!, {r4-r11, lr}

    @ Verifica se os parametros passados sao validos
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

    stmfd sp!, {r4-r11, lr}

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
    ldr r5, =GPIO_BASE
    ldr r4, [r5, #GPIO_DR]
    ldr r6, =DR_MOTORS
    bic r4, r4, r6
    orr r4, r4, r3
    str r4, [r5, #GPIO_DR]
    mov r0, #0

    b END

@ Retorna o valor do tempo do sistema
.align 4
SYS_GET_TIME:
    stmfd sp!, {r4-r11, lr}
    @ Passa a posicao de memoria do contador e a carrega em r0
    ldr r1, =TIME_COUNTER
    ldr r0, [r1]

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

    @ Verifica se o valor de tempo passado é válido
    ldr r2, =TIME_COUNTER
    ldr r2, [r2]
    cmp r1, r2
    ldrle r0, =-2
    ble END

    @ Lê o número de alarmes já criados para saber em que posição colocar o próximo
    ldr r2, =N_ALARMS
    ldr r3, [r2]
    cmp r3, #8
    movgt r0, #-1
    bgt END

    @ Passou, então já incrementa o N_ALARMS
    add r3, r3, #1
    str r3, [r2]

    @ Como existem lugares a serem alocados no vetor, ele procura esse lugar no vetor do tempo (A primeira posição que possuir -1)
    ldr r2, =ALARMS_TIMER
    ldr r3, =0x0
    search_loop:
        ldr r4, [r2, r3]
        cmp r4, #-1
        addne r3, r3, #0x04
        cmp r3, r3
        bne search_loop

    @ Saindo do loop, a posição [r2,r3] contem a posição que deve ser colocada nos vetores
    @ Insere no vetor de tempo
    ldr r1, [r2,r3]
    @ Insere no vetor de função
    ldr r2, =ALARMS_FUNCTIONS
    ldr r0, [r2, r3]




END:
    ldmfd sp!, {r4-r11, lr}
    mov pc, lr
