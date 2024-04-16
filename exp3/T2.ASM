myStack SEGMENT PARA STACK
    STACK_AERA DB  100 DUP(?)
    STACK_LEN  EQU $-STACK_AERA
myStack ENDS

DATA SEGMENT PARA
    String1       DB  'HUANG RONG LIANG', 0
    SUBFIX        EQU $ - 1
    String2Buffer DB  100, ?
    String2       DB  100 DUP('$')
DATA ENDS

CODE SEGMENT PARA
                    ASSUME CS: CODE, SS: myStack, DS: DATA


MAIN PROC FAR
                    MOV    AX, DATA
                    MOV    DS, AX
                    MOV    ES, AX
                    MOV    AX, myStack
                    MOV    SS, AX
                    MOV    SP, STACK_LEN

                    MOV    DX, OFFSET String2Buffer
                    MOV    AH, 0AH
                    INT    21H
                    MOV    DL, 0DH
                    MOV    AH, 02H
                    INT    21H
                    MOV    DL, 0AH
                    INT    21H

                    MOV    AL, BYTE PTR String2Buffer + 1
                    XOR    AH, AH
                    MOV    BX, OFFSET String2
                    ADD    BX, AX
                    MOV    [BX], 0

                    MOV    SI, OFFSET String1
                    MOV    DI, OFFSET String2

                    CALL   Stringcmp

                    MOV    BYTE PTR SUBFIX, '$'
                    MOV    DX, SI
                    MOV    AH, 09H
                    INT    21H

                    MOV    DL, 3DH
                    ADD    DL, AL
                    MOV    AH, 02H
                    INT    21H

                    MOV    [BX], '$'
                    MOV    DX, DI
                    MOV    AH, 09H
                    INT    21H


    EXIT:           
                    MOV    AH, 4CH
                    INT    21H
MAIN ENDP

    ;param: DS:SI, ES:DI
    ;return: AL = 0 iif string1 eqauls to string2
    ;       AL = 1 iif string1 is greater than string2
    ;       AL =-1 iif string1 is less than string2
Stringcmp PROC
                    PUSHF
                    PUSH   BX
                    PUSH   CX
                    MOV    BX, DS
                    MOV    CX, ES
                    CMP    BX, CX
                    JNZ    Stringcmp_START
                    CMP    SI, DI
                    MOV    AL, 0
                    JZ     Stringcmp_EXIT
    Stringcmp_START:
                    PUSH   SI
                    PUSH   DI
                    PUSH   DS
                    PUSH   ES


                    CLD

    Stringcmp_LOOP: 
                    LODSB
                    SCASB
                    JA     Stringcmp_GT
                    JB     Stringcmp_LT
                    TEST   AL, AL
                    JZ     Stringcmp_EQ
                    JMP    Stringcmp_LOOP

    Stringcmp_GT:   
                    MOV    AL, 1
                    JMP    Stringcmp_RET
    Stringcmp_LT:   
                    OR     AL, 0FFH
                    JMP    Stringcmp_RET
    Stringcmp_EQ:   
                    XOR    AL, AL

    Stringcmp_RET:  
                    POP    ES
                    POP    DS
                    POP    DI
                    POP    SI
    Stringcmp_EXIT: 
                    POP    CX
                    POP    BX
                    POPF
                    RET
Stringcmp ENDP

CODE ENDS
    END MAIN