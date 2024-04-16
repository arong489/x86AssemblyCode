myStack SEGMENT PARA STACK
    STACK_AERA DB  100H DUP(?)
    STACK_LEN  EQU $ - STACK_AERA
myStack ENDS

DATA SEGMENT PARA

    STRING1_1 DB  'HUANG RONG LIANG','$'
    STRING2_1 DB  17 DUP(' ')

    STRING2_2 DB  11 DUP(' ')
    STRING1_2 DB  'HUANG RONG LIANG','$'

    STRING1_3 DB  'HUANG RONG LIANG','$'
    STRING2_3 EQU $ - 7
              DB  11 DUP(' ')

    PREFIX    DB  'string', '$'
    NEW_LINE  DB  0DH, 0AH, '$'
DATA ENDS

CODE SEGMENT PARA
                  ASSUME CS: CODE, SS: myStack, DS: DATA


PRINT MACRO No, Address
                 MOV    DX, OFFSET PREFIX
                 MOV    AH, 09H
                 INT    21H
                 MOV    AH, 02H
                 MOV    DL, No
                 INT    21H
                 MOV    DL, ':'
                 INT    21H
                 MOV    DL, 20H
                 INT    21H
                 MOV    DX, OFFSET Address
                 MOV    AH, 09H
                 INT    21H
                 MOV    DX, OFFSET NEW_LINE
                 INT    21H
ENDM

MAIN PROC

                  MOV    AX, myStack
                  MOV    SS, AX
                  MOV    SP, STACK_LEN
                  MOV    AX, DATA
                  MOV    DS, AX
                  MOV    ES, AX
    ; Q1
                  PRINT  31H, STRING1_1

                  MOV    SI, OFFSET STRING1_1
                  MOV    DI, OFFSET STRING2_1
                  MOV    AX, 17
                  CALL   Memmove

                  PRINT  31H, STRING1_1
                  PRINT  32H, STRING2_1
                  MOV    DX, OFFSET NEW_LINE
                  INT    21H
    ;Q2
                  PRINT  31H, STRING1_2

                  MOV    SI, OFFSET STRING1_2
                  MOV    DI, OFFSET STRING2_2
                  MOV    AX, 17
                  CALL   Memmove

                  PRINT  31H, STRING1_2
                  PRINT  32H, STRING2_2
                  MOV    DX, OFFSET NEW_LINE
                  INT    21H
    ;Q3
                  PRINT  31H, STRING1_3

                  MOV    SI, OFFSET STRING1_3
                  MOV    DI, OFFSET STRING2_3
                  MOV    AX, 17
                  CALL   Memmove

                  PRINT  31H, STRING1_3
                  PRINT  32H, STRING2_3
                 


    EXIT:         
                  MOV    AH, 4CH
                  INT    21H
MAIN ENDP

    ; param: DS, ES, SI, DI, AX
    ; function: copy AX size of memmory from DS:SI to ES:DI
Memmove PROC
                  PUSHF
                  PUSH   BX
                  PUSH   CX
                  MOV    CX, DS
                  MOV    BX, ES
                  XOR    BX, CX
                  JNZ    Memmove_START
                  CMP    SI, DI
                  JZ     Memmove_EXIT
    Memmove_START:
                  PUSH   SI
                  PUSH   DI
                  PUSH   AX

                  CLD
                  MOV    CX, DI
                  SUB    CX, SI
                  JB     Memmove_MOVE                       ; d-s < 0, 正向复制
                  CMP    CX, AX
                  JAE    Memmove_MOVE                       ; d-s >= AX, 正向复制
                  ADD    DI, AX
                  ADD    SI, AX
                  DEC    DI
                  DEC    SI
                  STD
    Memmove_MOVE: 
                  MOV    CX, AX
                  REP    MOVSB

    Memmove_RET:  
                  POP    AX
                  POP    DI
                  POP    SI
    Memmove_EXIT: 
                  POP    CX
                  POP    BX
                  POPF
                  RET
Memmove ENDP

CODE ENDS
    END MAIN