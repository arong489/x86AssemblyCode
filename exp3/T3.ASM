myStack SEGMENT PARA STACK
    STACK_AREA DB  100 DUP(?)
    STACK_LEN  EQU $-STACK_AREA
myStack ENDS

DATA SEGMENT PARA
    BUFFER     DB  255, ?
    STRIGN     DB  255 DUP(?)
    OUTPUT     DB  6 DUP('$')
    OUTPUT_END EQU $
DATA ENDS

CODE SEGMENT PARA
                   ASSUME         CS: CODE, DS: DATA, SS: myStack

PRINT_REGISTER MACRO reg
        PUSH    AX
        PUSH    BX
        PUSH    DX
        PUSH    DI

        MOV     AX, reg
        MOV     BX, 10
        MOV     DI, OUTPUT_END
        DEC     DI
    PRINT_DIV_LOOP:
        XOR     DX, DX
        DIV     BX
        OR      DL, 30H
        DEC     DI
        MOV     [DI], DL
        TEST    AX, AX
        JNZ     PRINT_DIV_LOOP

        MOV     DX, DI
        MOV     AH, 09H
        INT     21H

        POP     DI
        POP     DX
        POP     BX
        POP     AX
ENDM

MAIN PROC
                   MOV            AX, DATA
                   MOV            DS, AX
                   MOV            AX, myStack
                   MOV            SS, AX
                   MOV            SP, STACK_LEN

                   MOV            DX, OFFSET BUFFER
                   MOV            AH, 0AH
                   INT            21H
                   MOV            DL, 0DH
                   MOV            AH, 02H
                   INT            21H
                   MOV            DL, 0AH
                   INT            21H

                   MOV            DL, BYTE PTR BUFFER + 1
                   XOR            DH, DH
                   PUSH           DX
                   PUSH           DS
                   MOV            DX,   OFFSET STRIGN
                   PUSH           DX

                   MOV            AL, 't'
                   CALL           FIND
                   ADD            SP, 6

                   PRINT_REGISTER AX


    EXIT:          
                   MOV            AH, 4CH
                   INT            21H
MAIN ENDP


    ;param: AL, STACK[string length, SEGMENT address,string address]
    ;return: AX----how many times 'AL' appear in string
FIND PROC NEAR
                   PUSH           BP
                   MOV            BP,SP
                   PUSH           CX
                   PUSH           ES
                   PUSH           DI
                   PUSH           DX

                   XOR            DX, DX
                   MOV            CX, [BP + 8]                       ;get length
                   MOV            ES, [BP + 6]
                   MOV            DI, [BP + 4]                       ;get address
    FIND_BODY:     
                   SCASB
                   JNZ            FIND_ITE
                   INC            DX
    FIND_ITE:      
                   LOOP           FIND_BODY

                   MOV            AX, DX

                   POP            DX
                   POP            DI
                   POP            ES
                   POP            CX
                   POP            BP
                   RET
FIND ENDP

CODE ENDS
END MAIN