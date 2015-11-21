@ SVC Constants
.set MAX_ALARMS,            0x08
.set MAX_CALLBACKS,         0x08
.set PSR_READ_SONARS,       0b11111111111111110000000000111111
.set DR_MOTORS,             0b11111101111110000000000000000000
.set PSR_FLAG,              0b00000000000000000000000000000001

@ GPT Constants
.set GPT_BASE,              0x53FA0000
.set GPT_CR,                0x00
.set GPT_PR,                0x04
.set GPT_SR,                0x08
.set GPT_IR,                0x0C
.set GPT_OCR1,              0x10
.set GPT_CR_VALUE,          0x00000041
.set TIME_SZ,               107

@ TZIC Constants
.set TZIC_BASE,             0x0FFFC000
.set TZIC_INTCTRL,          0x0
.set TZIC_INTSEC1,          0x84
.set TZIC_ENSET1,           0x104
.set TZIC_PRIOMASK,         0xC
.set TZIC_PRIORITY9,        0x424

@ CPSR
.set USER_MODE,             0x11
.set SUPERVISRO_MODE,       0x13


@ GPIO Definition
.set GPIO_BASE,             0x53F84000
.set GPIO_DR,               0x00
.set GPIO_GDIR,             0x04
.set GPIO_PSR,              0x08

@ Stacks
.set STACK_SIZE,            0x600

@ USER
.set USER_TEXT,             0x77802000


@@@ Start @@@
.org 0x0
.section .iv,"a"

_start:

interrupt_vector:
    b RESET_HANDLER

@Software Interrupt
.org 0x08
    b SVC_HANDLER


.org 0x18
    b IRQ_HANDLER


.data
@ Periféricos com clock de 107KHz
TIME_COUNTER: .word 0x0

@ SVC variables
N_CALLBACKS: .word 0x0
SHIFT_CALLBACKS: .word 0x0

@ Vetores para guardar os valores das callbacks. ponteiros,limiares e identificadores
CALLBACK_ID_VECTOR: .fill 4*MAX_CALLBACKS
CALLBACK_DIST_VECTOR: .fill 4*MAX_CALLBACKS
CALLBACK_POITERS_VECTOR: .fill 4*MAX_CALLBACKS

@ Vetores que armazenas um ponteriro para uma função e o tempo que deve serexecutado
N_ALARMS: .word 0x0
ALARMS_TIMER: .fill 4*MAX_ALARMS, 0
ALARMS_FUNCTIONS: .fill 4*MAX_ALARMS


@ Inicializa os stack-pointers
USER_STACK: .fill STACK_SIZE
SUPERVISOR_STACK: .fill STACK_SIZE
IRQ_STACK: .fill STACK_SIZE
FIQ_STACK: .fill STACK_SIZE

.text
@ Vetor de interrupcoes
.org 0x100

RESET_HANDLER:
    @ Zera o contador
    ldr r2, =TIME_COUNTER
    mov r0,#01
    str r0,[r2]

    msr CPSR_c, #0x13
    ldr sp, =SUPERVISOR_STACK
    msr CPSR_c, #0x11
    ldr sp, =USER_STACK
    msr CPSR_c, #0x12
    ldr sp, =IRQ_STACK

    @Set interrupt table base address on coprocessor 15.
    ldr r0, =interrupt_vector
    mcr p15, 0, r0, c12, c0, 0


SET_GPT:
    @Send data do GPT hardware
    ldr	r1, =GPT_BASE

    @ Habilita o GPT
    ldr r0, =GPT_CR_VALUE
    str	r0, [r1, #GPT_CR]

    @ Set zero the prescaler
    ldr r0, =0
    str r0, [r1, #GPT_PR]

    @ Gera interrupções a cada 2*10^5 ciclos
    ldr r0, =TIME_SZ
    str r0, [r1, #GPT_OCR1]

    @Enabling Output Compare Channel 1 interrupt
    ldr r0, =1
    str r0, [r1, #GPT_IR]


@ Código TZIC
SET_TZIC:
    @ Liga o controlador de interrupcoes
    @ R1 <= TZIC_BASE
    ldr	r1, =TZIC_BASE

    @ Configura interrupcao 39 do GPT como nao segura
    mov	r0, #(1 << 7)
    str	r0, [r1, #TZIC_INTSEC1]

    @ Habilita interrupcao 39 (GPT)
    @ reg1 bit 7 (gpt)
    mov	r0, #(1 << 7)
    str	r0, [r1, #TZIC_ENSET1]

    @ Configure interrupt39 priority as 1
    @ reg9, byte 3
    ldr r0, [r1, #TZIC_PRIORITY9]
    bic r0, r0, #0xFF000000
    mov r2, #1
    orr r0, r0, r2, lsl #24
    str r0, [r1, #TZIC_PRIORITY9]

    @ Configure PRIOMASK as 0
    eor r0, r0, r0
    str r0, [r1, #TZIC_PRIOMASK]

    @ Habilita o controlador de interrupcoes
    mov	r0, #1
    str	r0, [r1, #TZIC_INTCTRL]

    @instrucao msr - habilita interrupcoes
    msr  CPSR_c, #0x13       @ SUPERVISOR mode, IRQ/FIQ enabled



@ Faz a definição de entrada e saida do GPIO_GDIR
SET_GPIO:

    @ Escreve o binario no registrador do GPIO para definir entrada e saida
    ldr r0, =GPIO_BASE
    ldr r1, =0b11111111111111000000000000111110
    str r1, [r0, #GPIO_GDIR]

    @ Muda para o modo usuário
    msr CPSR_c, #0x11
    @ Pula para o text do usuário
    ldr r1, =USER_TEXT
    mov pc, r1



@ Implementação o IRQ_HANDLER (Gerenciador de interrupções de hardware)
IRQ_HANDLER:
    stmfd sp!, {r4-r11, lr}

    @ Increment the counter
    ldr r2, =TIME_COUNTER           @Load the TIME_COUNTER adress on r2
    ldr r0, [r2]                    @load in r0 the value of r2 adress
    add r0, r0, #0x1                @increment in 1 TIME_COUNTER
    str r0, [r2]                    @store it in the r2 adress

    @ Percorre o vetor de callbacks
    @ JUST DO IT!
    @ 1o - Percorre o vetor dos sonares a serem chamados, invocando a syscall read_sonar
    @ 2o - Analisa o valor retornado pela syscall. Deu certo?
    @   Não - Continua percorrendo o vetor
    @   Sim - UEPA, pega e executa essa executa a função. PROBLEMA= Como executar essa função em modo usuario e depois que ela parar, voltar ao modo supervisor...?
    @Pronto :)

    @ Percorre o vetor de alarmes
    ldr r0, =ALARMS_TIMER
    ldr r1, =ALARMS_FUNCTIONS
    ldr r2, =TIME_COUNTER
    ldr r2, [r2]
    ldr r3, =0x0
    ldr r4, =0x0

    loop:
        cmp r4, #MAX_ALARMS
        bge end_alarms
        ldr r5, [r0, r3]
        cmp r6, r2
        ldrge r6, [r1, r3]
        bxge r6
        add r4, r4, #0x01
        b loop
    end_alarms:

    ldmfd sp!, {r4-r11, lr}

    @ Volta para o modo de processador anterior
    sub lr, lr, #4
    movs pc, lr



SVC_HANDLER:
    stmfd sp!, {lr}

    @ Muda o modo de operação para supervisor
    @msr CPSR_c, #0xD3

    cmp r7, #16
    bleq SYS_READ_SONAR

    cmp r7, #17
    bleq SYS_REG_PROX_CALLBACK

    cmp r7, #18
    bleq SYS_SET_MOTOR_SPEED

    cmp r7, #19
    bleq SYS_SET_MOTORS_SPEED

    cmp r7, #20
    bleq SYS_GET_TIME

    cmp r7, #21
    bleq SYS_SET_TIME

    cmp r7, #22
    bleq SYS_SET_ALARM

    ldmfd sp!, {lr}
    movs pc, lr


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

    @ Delay de 15ms ((107Khz * 1 ms)/3)
    @ldr r0, #535
    @delay_5
    @  sub r0, r0, #1
    @  cmp r0, #0
    @  bgt delay_15

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

    b SVC_END

erro_sonar:
    ldr r0, =-1
    b SVC_END


.align 4
SYS_REG_PROX_CALLBACK:
    stmfd sp!, {r4-r11, lr}

    @testa as condicoes de callbacks, registradores validos
    ldr r4, =N_CALLBACKS
    ldr r4, [r4]
    cmp r4, #MAX_CALLBACKS
    movgt r0, #-1
    bgt SVC_END

    cmp r2, #15
    movgt r0, #-2
    bgt SVC_END

    cmp r2, #0
    movlt r0, #-2
    blt SVC_END

    @carrega as posicoes que o comeco dos vetores estao na memoria
    ldr r3, =CALLBACK_ID_VECTOR
    ldr r4, =CALLBACK_DIST_VECTOR
    ldr r5, =CALLBACK_POITERS_VECTOR

    @salva o que foi passado pelo usuario, nas posicoes correspondentes decada vetor
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

    b SVC_END

.align 4
SYS_SET_MOTOR_SPEED:
    
    stmfd sp!, {r4-r11, lr}

    @ Verifica se os parametros passados sao validos
    @ velocidades
    cmp r1, #63
    movhi r0, #-2
    bhi SVC_END

    @ id dos motores
    cmp r0, #1
    movgt r0, #-1
    bgt SVC_END

    cmp r0, #0
    movlt r0, #-1
    blt SVC_END

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
    b SVC_END


.align 4
SYS_SET_MOTORS_SPEED:

    stmfd sp!, {r4-r11, lr}

    @compara se é um valor valido de velocidade
    cmp r0, #63
    movhi r0, #-1
    bhi SVC_END

    cmp r1, #63
    movhi r0, #-2
    bhi SVC_END

    @coloca o valor de r2 na posicao de memoria correspondente do motor r0
    mov r3, #0
    
    @desloca o valor 26 bits, para cair na faixa do motor 0, com 0 no valorde write (talvez bit de write)
    orr r3, r3, r1, lsl #26
    
    @soma o valor de r1, que ja vai ficar no local correto
    orr r3, r3, r0, lsl #19

    @passa endereco armazenar nos dados
    ldr r5, =GPIO_BASE
    ldr r4, [r5, #GPIO_DR]
    ldr r6, =DR_MOTORS
    bic r4, r4, r6
    orr r4, r4, r3
    str r4, [r5, #GPIO_DR]
    mov r0, #0

    b SVC_END

@ Retorna o valor do tempo do sistema
.align 4
SYS_GET_TIME:
    stmfd sp!, {r4-r11, lr}
    @ Passa a posicao de memoria do contador e a carrega em r0
    ldr r1, =TIME_COUNTER
    ldr r0, [r1]

    b SVC_END

@ Define o contador de tempo do sistema
.align 4
SYS_SET_TIME:
    stmfd sp!, {r4-r11, lr}
    @ Pega o conteudo de r0, parametro, e coloca no tempo
    ldr r1, =TIME_COUNTER
    str r0, [r1]

    b SVC_END

.align 4
SYS_SET_ALARM:

    stmfd sp!, {r4-r11, lr}

    @ Verifica se o valor de tempo passado é válido
    ldr r2, =TIME_COUNTER
    ldr r2, [r2]
    cmp r1, r2
    ldrle r0, =-2
    ble SVC_END

    @ Lê o número de alarmes já criados para saber em que posição colocar opróximo
    ldr r2, =N_ALARMS
    ldr r3, [r2]
    cmp r3, #8
    movgt r0, #-1
    bgt SVC_END

    @ Passou, então já incrementa o N_ALARMS
    add r3, r3, #1
    str r3, [r2]

    @ Como existem lugares a serem alocados no vetor, ele procura esse lugarno vetor do tempo (A primeira posição que possuir -1)
    ldr r2, =ALARMS_TIMER
    ldr r3, =0x0
    search_loop:
        ldr r4, [r2, r3]
        cmp r4, #-1
        addne r3, r3, #0x04
        cmp r3, r3
        bne search_loop

    @ Saindo do loop, a posição [r2,r3] contem a posição que deve sercolocada nos vetores
    @ Insere no vetor de tempo
    ldr r1, [r2,r3]
    @ Insere no vetor de função
    ldr r2, =ALARMS_FUNCTIONS
    ldr r0, [r2, r3]



SVC_END:
    ldmfd sp!, {r4-r11, lr}
    mov pc, lr
