.global SYSCALL

.align 4
SYSCALL:
    cmp r7, #16
    beq READ_SONAR

    cmp r7, #17
    beq REG_PROX_CALLBACK

    cmp r7, #18
    beq SET_MOTOR_SPEED

    cmp r7, #19
    beq SET_MOTORS_SPEED

    cmp r7, #20
    beq GET_TIME

    cmp r7, #21
    beq SET_TIME

    cmp r7, #22
    beq SET_ALARM


.align 4
READ_SONAR:

.align 4
REG_PROX_CALLBACK:

.align 4
SET_MOTOR_SPEED:

.align 4
SET_MOTORS_SPEED:

    @passa o valor de r0 para um auxiliar e compara se e um valor valido de velocidade
    stmfd sp!, {r4-r11. lr}
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
    str r3, [r4]
    mov r0, #0

END:
    ldmfd sp!, {r4-r11, lr}
    movs pc, lr

@passa a posicao de memoria do contador e a carrega em r0
.align 4
GET_TIME:
    stmfd sp!, {r4-r11, lr}
    ldr r1, =TIME_COUNTER
    mov r0, [r1]
    ldmfd sp!, {r4-r11, lr}
    movs pc, lr

@pega o conteudo de r0, parametro, e coloca no tempo
.align 4
SET_TIME:
    stmfd sp!, {r4-r11, lr}
    ldr r1, =TIME_COUNTER
    str r0, [r1]
    ldmfd sp!, {r4-r11, lr}
    movs pc, lr


.align 4
SET_ALARM:
