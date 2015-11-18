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

@ Vetor de interrupcoes
.org 0x100

.text
SVC_HANDLER:
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

RESET_HANDLER:
    @ Zera o contador
    ldr r2, =TIME_COUNTER
    mov r0,#0
    str r0,[r2]

    @Set interrupt table base address on coprocessor 15.
    ldr r0, =interrupt_vector
    mcr p15, 0, r0, c12, c0, 0


@ GPT Constants
.set GPT_BASE,              0x53FA0000
.set GPT_CR,                0x00
.set GPT_PR,                0x04
.set GPT_SR,                0x08
.set GPT_IR,                0x0C
.set GPT_OCR1,              0x10
.set GPT_CR_VALUE,          0x00000041
.set TIME_SZ                107

@ Código GPT
SET_GPT:
    @Send data do GPT hardware
    @ Load the first adress of GPT on r1
    ldr	r1, =GPT_BASE

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


@ TZIC Constants
.set TZIC_BASE,             0x0FFFC000
.set TZIC_INTCTRL,          0x0
.set TZIC_INTSEC1,          0x84
.set TZIC_ENSET1,           0x104
.set TZIC_PRIOMASK,         0xC
.set TZIC_PRIORITY9,        0x424

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


@ GPIO Definition
.set GPIO_BASE,             0x53F84000
.set GPIO_DR,               0x00
.set GPIO_GDIR,             0x04
.set GPIO_PSR,              0x08

@ Faz a definição de entrada e saida do GPIO_GDIR
SET_GPIO:

    @ escreve o binario no registrador do GPIO para definir o que e entrada e saida
    ldr r0, =GPIO_BASE
    ldr r1, =0b11111111111111000000000000111110
    str r1, [r0, #GPIO_GDIR]


@ Implementação o IRQ_HANDLER (Gerenciador de interrupções de hardware)
IRQ_HANDLER:
    stmfd sp!, {r4-r11, lr}

    @ Increment the counter
    ldr r2, =TIME_COUNTER           @Load the TIME_COUNTER adress on r2
    ldr r0, [r2]                    @load in r0 the value of r2 adress
    add r0, r0, #0x1                @increment in 1 TIME_COUNTER
    str r0, [r2]                    @store it in the r2 adress

    ldmfd sp!, {r4-r11, lr}

    @ Subtract lr of 4
    sub lr, lr, #4
    movs pc, lr
