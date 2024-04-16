myStack SEGMENT PARA STACK
    STACK_AREA DB  100 DUP(?)
    STACK_LEN  EQU $-STACK_AREA
myStack ENDS

DATA SEGMENT PARA
    DIC          DB 'hello', 12 DUP(0)    ; 16字对齐字典
                 DB 'world', 12 DUP(0)
                 DB 'this', 13 DUP(0)
                 DB 'is', 15 DUP(0)
                 DB 'a', 16 DUP(0)
                 DB 'test', 13 DUP(0)
    WATER_MARK   DB 17 DUP(0)
    INPUT_BUFFER DB 20, ?, 20 DUP(?)
DATA ENDS

PRINT_DICT MACRO VAR_DIC_ADDRESS, WORD_NUMBER, WORD_ALIGN, LOOP_LABEL
               XOR  BX, BX
               XOR  SI, SI
               MOV  CX, WORD_NUMBER
               MOV  AH, 02H
    LOOP_LABEL:
               MOV  DL, VAR_DIC_ADDRESS[BX]
               INT  21H
               INC  BX
               TEST DL, DL
               JNZ  LOOP_LABEL
               OR   DL, 0DH
               INT  21H
               MOV  DL, 0AH
               INT  21H
               ADD  SI, WORD_ALIGN
               MOV  BX, SI
               LOOP LOOP_LABEL
ENDM


CODE SEGMENT PARA
                       ASSUME     CS: CODE, DS: DATA, SS: myStack

MAIN PROC
                       MOV        AX, myStack
                       MOV        SS, AX
                       MOV        SP, STACK_LEN
                       MOV        AX, DATA
                       MOV        DS, AX
                       MOV        ES, AX

                       MOV        DX, OFFSET INPUT_BUFFER
                       MOV        AH, 0AH
                       INT        21H
                       MOV        AL, BYTE PTR INPUT_BUFFER + 1
                       XOR        AH, AH
                       MOV        SI, OFFSET INPUT_BUFFER + 2
                       MOV        DI, OFFSET WATER_MARK
                       CALL       Memmove

                       MOV        AH, 02H
                       MOV        DL, 0DH
                       INT        21H
                       MOV        DL,0AH
                       INT        21H
                       MOV        DL, 0DH
                       INT        21H
                       MOV        DL,0AH
                       INT        21H
                       PRINT_DICT DIC, 7, 17, PRINT_DICT_1
                       MOV        DL, 0DH
                       INT        21H
                       MOV        DL,0AH
                       INT        21H

                       MOV        DX, OFFSET DIC
                       MOV        CX, 7
                       MOV        AX, 17
                       MOV        BX, OFFSET Stringcmp
                       CALL       QSORT

                       PRINT_DICT DIC, 7, 17, PRINT_DICT_2

    EXIT:              
                       MOV        AH, 4CH
                       INT        21H
MAIN ENDP


    ; receive two element address SI, DI as args and return AL
    ; AL is  0 iif *SI = *DI
    ; AL is  1 iif *SI > *DI
    ; AL is -1 iif *SI < *DI
Stringcmp PROC
                       PUSH       BX
                       PUSH       CX
                       MOV        BX, DS
                       MOV        CX, ES
                       CMP        BX, CX
                       JNZ        Stringcmp_START
                       CMP        SI, DI
                       MOV        AL, 0
                       JZ         Stringcmp_EXIT
    Stringcmp_START:   
                       PUSH       SI
                       PUSH       DI
                       PUSH       DS
                       PUSH       ES


                       CLD

    Stringcmp_LOOP:    
                       LODSB
                       SCASB
                       JA         Stringcmp_GT
                       JB         Stringcmp_LT
                       TEST       AL, AL
                       JZ         Stringcmp_EQ
                       JMP        Stringcmp_LOOP

    Stringcmp_GT:      
                       MOV        AL, 1
                       JMP        Stringcmp_RET
    Stringcmp_LT:      
                       OR         AL, 0FFH
                       JMP        Stringcmp_RET
    Stringcmp_EQ:      
                       XOR        AL, AL

    Stringcmp_RET:     
                       POP        ES
                       POP        DS
                       POP        DI
                       POP        SI
    Stringcmp_EXIT:    
                       POP        CX
                       POP        BX
                       RET
Stringcmp ENDP
    ; param: DS, ES, SI, DI, AX
    ; function: copy AX size of memmory from DS:SI to ES:DI
Memmove PROC
                       PUSHF
                       PUSH       BX
                       PUSH       CX
                       MOV        CX, DS
                       MOV        BX, ES
                       XOR        BX, CX
                       JNZ        Memmove_START
                       CMP        SI, DI
                       JZ         Memmove_EXIT
    Memmove_START:     
                       PUSH       SI
                       PUSH       DI
                       PUSH       AX

                       CLD
                       MOV        CX, DI
                       SUB        CX, SI
                       JB         Memmove_MOVE                       ; d-s < 0, 正向复制
                       CMP        CX, AX
                       JAE        Memmove_MOVE                       ; d-s >= AX, 正向复制
                       ADD        DI, AX
                       ADD        SI, AX
                       DEC        DI
                       DEC        SI
                       STD
    Memmove_MOVE:      
                       MOV        CX, AX
                       REP        MOVSB

    Memmove_RET:       
                       POP        AX
                       POP        DI
                       POP        SI
    Memmove_EXIT:      
                       POP        CX
                       POP        BX
                       POPF
                       RET
Memmove ENDP


    ;param
    ;   DX: sequence header address
    ;   CX: element number
    ;   AX: element size
    ;   BX: compare function address
    ;function
    ;   sort the element in sequence
    ;return
    ;   none
    ;attention
    ;   the compare function at DI must be:
    ;       receive two element address SI, DI as args and return AL
    ;       AL is  0 iif *SI = *DI
    ;       AL is  1 iif *SI > *DI
    ;       AL is -1 iif *SI < *DI
QSORT PROC
                       PUSHF
                       PUSH       ES
                       PUSH       DS
                       POP        ES                                 ; load es with ds
                       PUSH       CX
                       PUSH       DX
                       PUSH       SI
                       PUSH       DI
                       PUSH       BX                                 ; store compare function address
                       PUSH       AX                                 ; store element size
                       PUSH       BP
                       MOV        BP, SP

                       MOV        SI, OFFSET QSORT_EXIT              ; store ret address
                       PUSH       SI
                       PUSH       DX                                 ; sequence header address
                       PUSH       CX                                 ; element number

    QSORT_TASK:        
                       POP        CX
                       POP        SI
                       CMP        CX, 1
                       JBE        QSORT_RET
                       PUSH       CX
                       MOV        DI, SI
                       ADD        DI, [BP + 2]
                       DEC        CX
    QSORT_PRETASK:     
                       TEST       CX, CX
                       JZ         QSORT_HANDLE_BEGIN
                       DEC        CX
                       CALL       [BP + 4]
                       CMP        AL, 0
                       JL         QSORT_HANDLE_BEGIN
                       ADD        DI, [BP + 2]
                       JMP        QSORT_PRETASK
    QSORT_HANDLE_BEGIN:
                       MOV        BX, DI
                       ADD        DI, [BP + 2]
    QSORT_HANDLE_LOOP: 
                       CMP        CX, 0
                       JZ         QSORT_POSTHANDLE
                       CALL       [BP + 4]
                       CMP        AL, 0
                       JL         QSORT_POSTWAP

                       PUSH       CX
                       MOV        CX, [BP + 2]
    QSORT_EXCHANGE:    
                       MOV        AL, BYTE PTR DS:[BX]
                       XCHG       AL, BYTE PTR DS:[DI]
                       MOV        DS:[BX], AL
                       INC        BX
                       INC        DI
                       LOOP       QSORT_EXCHANGE
                       POP        CX
                       DEC        CX
                       JMP        QSORT_HANDLE_LOOP
    QSORT_POSTWAP:     
                       ADD        DI, [BP + 2]
                       DEC        CX
                       JMP        QSORT_HANDLE_LOOP

    QSORT_POSTHANDLE:  
                       SUB        BX, [BP + 2]
                       MOV        CX, [BP + 2]
    QSORT_POSTXCHG:    
                       MOV        AL, BYTE PTR DS:[SI]
                       XCHG       AL, BYTE PTR DS:[BX]
                       MOV        DS:[SI], AL
                       INC        SI
                       INC        BX
                       LOOP       QSORT_POSTXCHG

                       MOV        AX, BX
                       SUB        AX, SI
                       XOR        DX, DX
                       MOV        CX, [BP + 2]
                       DIV        CX
                       SUB        SI, CX
                       POP        DX
                       SUB        DX, AX
                       DEC        DX
                       MOV        CX, QSORT_RET
                       PUSH       CX
                       PUSH       BX
                       PUSH       DX
                       MOV        CX, QSORT_RECURSE
                       PUSH       CX
                       PUSH       SI
                       PUSH       AX
                       JMP        QSORT_TASK
    QSORT_RECURSE:     
                       JMP        QSORT_TASK
    QSORT_RET:         
                       POP        AX
                       JMP        AX


    QSORT_EXIT:        
                       POP        BP
                       POP        AX
                       POP        BX
                       POP        DI
                       POP        SI
                       POP        DX
                       POP        CX
                       POP        ES
                       POPF
                       RET
QSORT ENDP

CODE ENDS
    END     MAIN