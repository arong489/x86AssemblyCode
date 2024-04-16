STACK1 SEGMENT     PARA STACK
    STACK_AREA   DW  100H DUP(?)
    STACK_BOTTOM EQU $ - STACK_AREA
STACK1 ENDS


DATA1 SEGMENT     PARA
    NUMBER DB 0, ?, ?, 0, ? , ?
    RESULT DB 0DH, 0AH, 5 DUP(?), 20H, '$'
DATA1 ENDS


CODE1 SEGMENT     PARA
                     ASSUME CS:CODE1, DS:DATA1, SS:STACK1
    ; 主程序
MAIN PROC        FAR
                     MOV    AX, STACK1
                     MOV    SS, AX
                     MOV    SP, STACK_BOTTOM
                     MOV    AX, DATA1
                     MOV    DS, AX                           ; INIT SS SP DS
                
                     MOV    DX, OFFSET NUMBER
                     MOV    AX, 2
                     CALL   GETNUM

                     MOV    DX, 3
                     MOV    AX, 3
                     CALL   GETNUM

                     MOV    AX, WORD PTR NUMBER + 1
                     MOV    BX, WORD PTR NUMBER + 4
                     MUL    BX                               ; 结果已经在AX中了
                     CALL   PRINTNUM

    EXIT:            MOV    AH, 4CH
                     INT    21H
MAIN ENDP

    ; GETNUM(AX, DX)
    ; AX代表10进制字符串长度
    ; DX数值内存区地址，返回结果: 数值长度, (小顶端)数值
GETNUM PROC
                     TEST   AX, AX
                     JZ     GET_NUM_END_EXIT
    ; save registers
                     PUSH   AX
                     PUSH   CX
                     PUSH   DX
                     PUSH   SI
                     PUSH   BP

                     MOV    BP, SP
                     MOV    CX, AX
                     MOV    AH, 01H
    INPUT_FILTER:    
                     INT    21H
                     XOR    AL, 30H                          ;转成数值
                     CMP    AL, 10
                     JA     INPUT_FILTER

                     MOV    SI, DX
                     MOV    [SI + 1], AL
                     XOR    AH, AH
                     INC    AH
                     MOV    [SI], AH

                     DEC    CX
                     JZ     GET_NUM_END

    LOOP_GET_NUM:    
                     MOV    SI, [BP + 4]
                     PUSH   CX
                     MOV    CL, [SI]
                     XOR    CH, CH
                     INC    SI
                     XOR    AH, AH
    LOOP_MUL:        
                     MOV    AL, [SI]
    ;获取进位
                     XOR    DH, DH
                     MOV    DL, AH
                     XOR    AH, AH

                     SHL    AX, 1
                     ADD    DX, AX

                     SHL    AX, 1
                     SHL    AX, 1
                     ADD    AX, DX
                     MOV    [SI], AL

                     INC    SI
                     LOOP   LOOP_MUL
                     POP    CX

    ;结算扩长
                     TEST   AH, AH
                     JZ     GET_NUM_ADD
                     MOV    [SI], AH
                     MOV    SI, [BP + 4]
                     MOV    DL, [SI]
                     INC    DL
                     MOV    [SI], DL

    GET_NUM_ADD:     
                     MOV    SI, [BP + 4]
                     INC    SI
                     MOV    AH, 01H
                     INT    21H
                     XOR    AL, 30H                          ;获得输入的字符转数值
                     MOV    AH, [SI]
                     ADD    AH, AL
                     MOV    [SI], AH
                     JNC    ITERATION
    CARRY:           
                     INC    SI
                     MOV    AL, [SI]
                     ADC    AL, 0
                     MOV    [SI], AL
                     JC     CARRY
                     MOV    AX, SI
                     MOV    SI, [BP + 4]
                     SUB    AX, SI
                     MOV    [SI], AL
    ITERATION:       
                     LOOP   LOOP_GET_NUM
    GET_NUM_END:     
                     POP    BP
                     POP    SI
                     POP    DX
                     POP    CX
                     POP    AX
    GET_NUM_END_EXIT:
                     RET
GETNUM ENDP

    ; PRINTNUM(AX) 打印一个数的十进制形式, 该数在AX中
PRINTNUM PROC
                     PUSH   BX
                     PUSH   CX
                     PUSH   DX
                     PUSH   DI

                     MOV    CX, 5
                     MOV    DI, OFFSET RESULT+6
                     MOV    BX, 10
    LP1:             XOR    DX, DX
                     DIV    BX
                     OR     DL, 30H
                     MOV    [DI], DL
                     DEC    DI
                     LOOP   LP1

    PRINT_RES:       MOV    DX, OFFSET RESULT
                     MOV    AH, 9                            ; 用完后AX会变
                     INT    21H

    RETURN2:         POP    DI
                     POP    DX
                     POP    CX
                     POP    BX
                     RET
PRINTNUM ENDP

CODE1 ENDS

                END         MAIN