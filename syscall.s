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
REG_PROX_CALLBACK:

.align 4
SET_MOTOR_SPEED:


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
