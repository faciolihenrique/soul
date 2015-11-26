@ Constantes usadas em SVC
.set PSR_READ_SONARS,       0b11111111111111110000000000111111
.set DR_MOTORS,             0b11111101111110000000000000000000
.set PSR_FLAG,              0b11111111111111111111111111111110
.set PSR_READ_SONAR,        0b11111111111111100000000000111111

@ Constantes GPT
.set GPT_BASE,              0x53FA0000
.set GPT_CR,                0x00
.set GPT_PR,                0x04
.set GPT_SR,                0x08
.set GPT_IR,                0x0C
.set GPT_OCR1,              0x10
.set GPT_CR_VALUE,          0x00000041

@ Periféricos com clock de 107KHz
.set TIME_SZ,               107

@ Constantes da TZIC
.set TZIC_BASE,             0x0FFFC000
.set TZIC_INTCTRL,          0x0
.set TZIC_INTSEC1,          0x84
.set TZIC_ENSET1,           0x104
.set TZIC_PRIOMASK,         0xC
.set TZIC_PRIORITY9,        0x424

@ Modos de Execução
.set USER_MODE,		        0x10
.set USER_NO_INTERRUPTION,  0xD0
.set SYSTEM_MODE,           0xDF
.set IRQ_MODE,              0x12
.set IRQ_NO_INTERRUPT,	    0xD2
.set SUPERVISOR_MODE,       0x13
.set SUPERVISOR_NO_I,       0xD3

@ Constantes do GPIO
.set GPIO_BASE,             0x53F84000
.set GPIO_DR,               0x00
.set GPIO_GDIR,             0x04
.set GPIO_PSR,              0x08

@ Alarmes e Callbacks
.set MAX_ALARMS,            0x08
.set MAX_CALLBACKS,         0x08

@ Tamanhos das pilhas
.set STACK_SIZE,            1024

@ User data
.set USER_TEXT,             0x77803000


.data
@ Inicializa os SP em cada modo de execução
.fill STACK_SIZE
USER_STACK:
.fill STACK_SIZE
SUPERVISOR_STACK:
.fill STACK_SIZE
IRQ_STACK:
.fill STACK_SIZE

@ Variavel para armazenar o tempo de sistema
TIME_COUNTER: .word 0x0

@ Váriaveis que armazenam inforamções de callbacks
CALLBACK_ACTIVE: .word 0x0
N_CALLBACKS: .word 0x0
CALLBACK_ID_VECTOR: .fill 4*#MAX_CALLBACKS
CALLBACK_DIST_VECTOR: .fill 4*#MAX_CALLBACKS
CALLBACK_POINTERS_VECTOR: .fill 4*#MAX_CALLBACKS

@ Variáveis que armazenam informações de alarmes
N_ALARMS: .word 0x0
ALARMS_TIMER: 4*#MAX_ALARMS
ALARMS_FUNCTIONS: 4*#MAX_ALARMS


@@@ START @@@
.org 0x0
.section .iv,"a"

_start:

interrupt_vector:
    b RESET_HANDLER

@ 0x08 é a interrupção SVC
.org 0x08
    b SVC_HANDLER

@ 0x18 é a interrupção IRQ
.org 0x18
    b IRQ_HANDLER

.text
@ Vetor de interrupcoes
.org 0x100

RESET_HANDLER:
    @ Zera o contador
    ldr r2, =TIME_COUNTER
    mov r0,#01
    str r0,[r2]

    @ Zera os callbacks
    ldr r0, CALLBACK_ID_VECTOR
    ldr r1, =0x10
    ldr r2, =0x0
    ldr r3, =0x0
    callback_zero:
        str r1, [r0, r1]
        add r2, r2, #0x04
        add r3, r3, #0x01
        cmp r3, #MAX_CALLBACKS
        blt callback_zero

    @ Zera o número de alarmes
    ldr r0, ALARMS_TIMER
    ldr r1, =0
    ldr r2, =0x0
    ldr r3, =0x0
    alarm_zero:
        str r1, [r0, r1]
        add r2, r2, #0x04
        add r3, r3, #0x01
        cmp r3, #MAX_ALARMS
        blt alarm_zero


    @ Iniciliza a pilha de cada um dos modos
    msr CPSR_c, #SUPERVISOR_MODE
    ldr sp, =SUPERVISOR_STACK
    msr CPSR_c, #SYS_MODE
    ldr sp, =USER_STACK
    msr CPSR_c, #IRQ_NO_INTERRUPT
    ldr sp, =IRQ_STACK

    @Set interrupt table base address on coprocessor 15.
    ldr r0, =interrupt_vector
    mcr p15, 0, r0, c12, c0, 0


SET_GPT:
    ldr	r1, =GPT_BASE

    @ Habilita o GPT
    ldr r0, =GPT_CR_VALUE
    str	r0, [r1, #GPT_CR]

    @ Set zero the prescaler
    ldr r0, =0
    str r0, [r1, #GPT_PR]

    @ Gera interrupções
    ldr r0, =TIME_SZ
    str r0, [r1, #GPT_OCR1]

    @ Ativa as interrupções no channel 1
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

    @ Instrucao msr - habilita interrupcoes
    msr  CPSR_c, #SUPERVISOR_MODE       @ SUPERVISOR mode, IRQ/FIQ enabled



@ Faz a definição de entrada e saida do GPIO_GDIR
SET_GPIO:
    @ Escreve o binario no registrador do GPIO para definir entrada e saida
    ldr r0, =GPIO_BASE
    ldr r1, =0b11111111111111000000000000111110
    str r1, [r0, #GPIO_GDIR]

    @ Muda para o modo usuário
    msr CPSR_c, #USER_MODE

    @ Pula para o código do usuário
    ldr r1, =USER_TEXT
    mov pc, r1



@ Implementação o IRQ_HANDLER (Gerenciador de interrupções de hardware)
IRQ_HANDLER:
    stmfd sp!, {r0-r12, lr}

    @ Define o GPT_SR para avisar sobre a interrupção
    ldr	r1, =GPT_BASE
    ldr r0, =1
    str r0, [r1, #GPT_SR]

timer:
    @ Tempo de Sistema
    ldr r2, =TIME_COUNTER           @Load the TIME_COUNTER adress on r2
    ldr r0, [r2]                    @load in r0 the value of r2 adress
    add r0, r0, #0x1                @increment in 1 TIME_COUNTER
    str r0, [r2]                    @store it in the r2 adress

    @ Faz o check de interrupções
    ldr r1, =CALLBACK_ACTIVE
    ldr r1, [r1]
    cmp r1, #0x01
    beq end_irq

@ Percorrer o vetor de alarmes
irq_alarms:

    ldr r0, =ALARMS_TIMER
    ldr r1, =ALARMS_FUNCTIONS
    ldr r2, =TIME_COUNTER
    ldr r2, [r2]
    ldr r3, =0x0
    ldr r4, =0x0
    ldr r7, =0x0
    ldr r8, =N_ALARMS
    ldr r9, [r8]

loop_irq_alarms:
    @ Verificação do número de alarmes a serem percorridos
    cmp r9, #0
    beq irq_callback

    @ Carrega em r5 o valor da atual posição do vetor de tempo
    ldr r5, [r0, r3]

    @ Compara para saber se deve executar ele ou não
    cmp r5, #0
    addeq r3, r3, #0x04
	beq loop_irq_alarms

    @ Se o valor em r5 for != de 0, subtrai um alarme e segue a execução
    sub r9, r9, #0x01

    @ Verifica se já chegou no tempo desejado
    cmp r2, r5

    @ Limpa a posição de execução e carrega em r6 o end da função
    ldrge r5, =0x0
    strge r5, [r0, r3]

    ldrge r6, [r1, r3]

    @ Faz a chamada da função
    @ Salva o estado da execução neste ponto
    stmfd sp!, {r0-r11, lr}

	mrs r0, SPSR
	stmfd sp!, {r0}

	ldr r1, =CALLBACK_ACTIVE
    ldr r2, =0x1
    str r2, [r1]

	msr CPSR_c, #USER_MODE
    blxge r6

	mov r7, #23
	svc 0x0
return_from_alarm_svc:

    ldr r1, =CALLBACK_ACTIVE
    ldr r2, =0x0
    str r2, [r1]

	ldmfd sp!, {r0}
	msr SPSR, r0

    ldmfd sp!, {r0-r11, lr}

    @ Remove a função executada do contador de funçoes ativas
    ldrge r10, [r8]
    subge r10, r10, #0x01
    strge r10, [r8]

    add r3, r3, #0x04
    b loop_irq_alarms


@ Percorrer o vetor de callbacks
irq_callback:

    ldr r4, =CALLBACK_ID_VECTOR
    ldr r5, =CALLBACK_DIST_VECTOR
    ldr r6, =CALLBACK_POINTERS_VECTOR
    ldr r3, =0x0
    ldr r8, =N_CALLBACKS
    ldr r8, [r8]

loop_irq_callbacks:
    cmp r8, #0
    beq end_irq

    @ Carrega a posição do sonar em r0
    ldr r0, [r4, r3]

    @ Compara com 0x10 para saber se há uma callback nesse endereço ou não
    cmp r0, #0x10
    addeq r3, r3, #0x04
    beq loop_irq_callbacks

    @ Algum valor != de 0xA0 foi encontrada na memoria
    sub r8, r8, #0x01

    @ Verifica a leitura do sonar
    @ Identifica que nao deve ser executada os alarmes e callback no IRQ
    stmfd sp!, {r1-r11, lr}

    ldr r1, =CALLBACK_ACTIVE
    ldr r2, =0x1
    str r2, [r1]

    mrs r9, SPSR
	stmfd sp!, {r9}

    mov r7, #16
    svc 0x0

	ldmfd sp!, {r9}
	msr SPSR, r9

	ldr r1, =CALLBACK_ACTIVE
    ldr r2, =0x0
    str r2, [r1]
    ldmfd sp!, {r1-r11, lr}

    @ Verifica se já chegou no limiar desejado desejado
    @ Carrega em r0 o endereço de chamada
    ldr r1, [r5, r3]
    cmp r0, r1
    ldrle r0, [r6, r3]

    @ Faz a chamada da função
    stmfd sp!, {r0-r11, lr}

    ldr r1, =CALLBACK_ACTIVE
    ldr r2, =0x1
    str r2, [r1]

    mrs r10, SPSR
	stmfd sp!, {r9}

	msr CPSR_c, #USER_MODE
    blxle r0
    mov r7, #24
	svc 0x0
return_from_callback_svc:

	ldr r1, =CALLBACK_ACTIVE
    ldr r2, =0x0
    str r2, [r1]

	ldmfd sp!, {r9}
	msr SPSR, r10

    ldmfd sp!, {r0-r11, lr}

    add r3, r3, #0x04
    b loop_irq_callbacks


end_irq:
    ldmfd sp!,{r0-r12, lr}

    sub lr, lr, #4
    movs pc, lr



SVC_HANDLER:

    cmp r7, #16
    beq SYS_READ_SONAR

    cmp r7, #17
    beq SYS_SET_CALLBACK

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

    cmp r7, #23
    beq RETURN_ALARM_FUNCTION

    cmp r7, #24
    beq RETURN_CALLBACK_FUNCTION


.align 4
SYS_READ_SONAR:
    stmfd sp!, {r4-r11, lr}

    ldr r5, =CALLBACK_ACTIVE
    ldr r6, =0x1
    str r6, [r1]

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
    ldr r0, =8000
    delay_15:
        sub r0, r0, #1
        cmp r0, #0
        bgt delay_15

    @ Faz um OR com r2 e 2 para setar o trigger = 1
    orr r2, r2, #0x02
    str r2, [r5, #GPIO_DR]

    @ Delay de 5ms * ((107Khz * 1 ms))
    ldr r0, =2000
    delay_5:
        sub r0, r0, #1
        cmp r0, #0
        bgt delay_5

    @ Desativa o trigger após os 15ms
    bic r2, r2, #0x02
    str r2, [r5, #GPIO_DR]

    @ Loop para verifica a cada 10ms se o flag foi modificada
    read_sonar_loop:
        @ Delay de 10ms ((107Khz * 1 ms)/3)
        ldr r0, =5000
        delay_10:
            sub r0, r0, #1
            cmp r0, #0
            bgt delay_10

        @ Faz um check da flag (que esta em psr)
        @ Verifica se o valor do flag está 1
        ldr r1, [r5, #GPIO_DR]
        ldr r2, =PSR_FLAG
        bic r2, r1, r2
        cmp r2, #0x01
        bne read_sonar_loop

    @ Pega os valores da leitura do sonar
    ldr r6, =PSR_READ_SONAR
    bic r0, r1, r6
    movh r0, r0, lsr #6

    b end_read_sonar

erro_sonar:
    ldr r0, =-1

end_read_sonar:
    ldr r5, =CALLBACK_ACTIVE
    ldr r6, =0x0
    str r6, [r1]

    ldmfd sp!, {r4-r11, lr}
    movs pc, lr



.align 4
SYS_SET_MOTOR_SPEED:

    stmfd sp!, {r4-r11, lr}

    @verifica se os parametros passados sao validos
    cmp r1, #63
    movhi r0, #-2
    bhi end_motor

    @ id dos motores
    cmp r0, #1
    movgt r0, #-1
    bgt end_motor

    cmp r0, #0
    movlt r0, #-1
    blt end_motor

    @prepara para colocar as informações no motor
    ldr r5, =GPIO_BASE
    ldr r4, [r5, #GPIO_DR]
    mov r3, #0

    @caso o motor seja o 0
    addeq r3, r3, r1, lsl #26
    biceq r4, r4, #0b00000000000000000000000000111111
    orreq r4, r4, r3
    streq r4, [r5, #GPIO_DR]

    @caso o motor seja o 1
    addgt r3, r3, r1, lsl #19
    bicgt r4, r4, #0b00000000000000000001111110000000
    orrgt r4, r4, r3
    strgt r4, [r5, #GPIO_DR]

    mov r0, #0
    b end_motor

end_motor:
    ldmfd sp!, {r4-r11, lr}
    movs pc, lr



.align 4
SYS_SET_MOTORS_SPEED:

    stmfd sp!, {r4-r11, lr}

    @ Compara se é um valor valido de velocidade
    cmp r0, #63
    movhi r0, #-1
    bhi end_motors

    cmp r1, #63
    movhi r0, #-2
    bhi end_motors

    @ Coloca o valor de r2 na posicao de memoria correspondente do motor r0
    mov r3, #0

    @ Desloca o valor 26 bits, para cair na faixa do motor 0, com 0 no valor de write do motor 0
    orr r3, r3, r1, lsl #26

    @ Faz um OR com valor de r1, que ja vai ficar no local correto
    orr r3, r3, r0, lsl #19

    @ Armazena os valores em GPIO
    ldr r5, =GPIO_BASE
    ldr r4, [r5, #GPIO_DR]
    ldr r6, =DR_MOTORS
    bic r4, r4, r6
    orr r4, r4, r3
    str r4, [r5, #GPIO_DR]
    mov r0, #0

    b end_motors

end_motors:
    ldmfd sp!, {r4-r11, lr}
    movs pc, lr



@ Retorna o valor do tempo do sistema
.align 4
SYS_GET_TIME:
    stmfd sp!, {r4-r11, lr}

    @ Carrega em r0 o valor da memória do contador
    ldr r0, =TIME_COUNTER
    ldr r0, [r0]

    ldmfd sp!, {r4-r11, lr}
    movs pc, lr


@ Define o contador de tempo do sistema
.align 4
SYS_SET_TIME:
    stmfd sp!, {r4-r11, lr}

    @ Substitui o tempo do sistema
    ldr r1, =TIME_COUNTER
    str r0, [r1]

    ldmfd sp!, {r4-r11, lr}
    movs pc, lr

.align 4
SYS_SET_ALARM:

    stmfd sp!, {r4-r11, lr}

    @ Verifica se o valor de tempo passado é válido
    ldr r2, =TIME_COUNTER
    ldr r2, [r2]
    cmp r1, r2
    ldrle r0, =-2
    ble end_alarm


    @ Lê o número de alarmes já criados para saber em que posição colocar opróximo
    ldr r2, =N_ALARMS
    ldr r3, [r2]
    cmp r3, #MAX_ALARMS
    movgt r0, #-1
    bgt end_alarm


    @ Passou, então já incrementa o N_ALARMS
    add r3, r3, #1
    str r3, [r2]

    @ Como existem lugares a serem alocados no vetor, ele procura esse lugar no vetor do tempo (A primeira posição que possuir -1)
    ldr r2, =ALARMS_TIMER
    ldr r3, =0x0
    search_loop:
        ldr r4, [r2, r3]
        cmp r4, #0
	beq end_search_alarm
        add r3, r3, #0x04
        cmp r3, #32
        blt search_loop
    end_search_alarm:

    @ Saindo do loop, a posição [r2,r3] contem a posição que deve sercolocada nos vetores
    @ Insere no vetor de tempo
    str r1, [r2, r3]

    @ Insere no vetor de função
    ldr r2, =ALARMS_FUNCTIONS
    str r0, [r2, r3]

end_alarm:
    ldmfd sp!, {r4-r11, lr}
    movs pc, lr


.align 4
SYS_SET_CALLBACK:

    stmfd sp!, {r4-r11, lr}

    @ Verifica se o identificador de sonar é válido
    cmp r0, #15
    ldrhi r0, =-2
    bhi end_callback

    @ Verifica o número de callbacks do sistema
    ldr r4, =N_CALLBACKS
    ldr r3, [r4]
    cmp r3, #MAX_CALLBACKS
    ldrge r0, =-1
    bge end_callback

    @ Passou, então já incrementa o N_CALLBACKS
    add r3, r3, #1
    str r3, [r4]

    @ Como existem lugares a serem alocados no vetor, ele procura esse lugar no vetor de limiar (A primeira posição que possuir 0)
    ldr r3, =CALLBACK_ID_VECTOR
    ldr r4, =0x0
    search_callbacks_loop:
        ldr r5, [r3, r4]
        cmp r5, #0x10
	    beq end_search_callbacks
        add r4, r4, #0x04
        cmp r4, #32
        blt search_callbacks_loop
    end_search_callbacks:

    @ Saindo do loop, a posição [r2,r3] contem a posição que devesercolocada nos vetores
    @ Insere no vetor de tempo
    str r0, [r3, r4]

    @ Insere no vetor de função
    ldr r3, =CALLBACK_DIST_VECTOR
    str r1, [r3, r4]
    ldr r3, =CALLBACK_POINTERS_VECTOR
    str r2, [r3, r4]

end_callback:
    ldmfd sp!, {r4-r11, lr}
    movs pc, lr


.align 4
RETURN_ALARM_FUNCTION:
    msr CPSR_c, IRQ_MODE
    b return_from_callback_svc

.align 4
RETURN_CALLBACK_FUNCTION:
    msr CPSR_c, IRQ_MODE
    b return_from_callback_svc
