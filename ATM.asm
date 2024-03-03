;ATM MACHINE CHECKER
;The user enters in decimal his card number (16 bits) which means from 0 to 65535, and his password (4 bits), from 0 to 15.
;If the data of the user matches with one of the 20 customers in the database --> output 1 ELSE 0


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; this maro is copied from emu8086.inc ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; this macro prints a char in AL and advances
; the current cursor position:
PUTC    MACRO   char
        PUSH    AX
        MOV     AL, char
        MOV     AH, 0Eh
        INT     10h     
        POP     AX
ENDM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
org 000
jmp start1

msg0 db "Welcome to ATM",0Dh,0Ah,'$'
msg1 db 0Dh,0Ah,"Enter card number: $"
msg2 db 0Dh,0Ah,"Enter the password: $" 
msg3 db 0Dh,0Ah,"1 (ALLOWED)$"
msg4 db 0Dh,0Ah,"0 (DENIED)$"
msg5 db 0Dh,0Ah,"Incorrect Card Number$ "
msg6 db 0Dh,0Ah,"Incorrect Password$" 
msg7 db 0Dh,0Ah,"press 1 to exit or other key to check another card:$" 
msg8 db 0Dh,0Ah,"password out of range!,please enter again$"

num1 dw ?
num2 db ? 
count dw 0


CARD dw 5566,5577,1234,1357,7798,8820,9934,7744,5621,6644,1389,1534,4378,7755,6699,4469,3468,8811,4334,2398
PASS db 0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,1,2,3,4 

 
     
start1:
 
mov dx,offset msg0
mov ah, 9
int 21h


start2:

lea dx,msg1    ;msg1"Enter card number:"
mov ah, 09h   
int 21h

call scan_num

; store card number:
mov num1, cx 


start3:
; new line:
putc 0Dh
putc 0Ah 


lea dx, msg2  ;msg2"Enter the password:"
mov ah, 09h
int 21h  



call scan_num


; store password:
mov num2, cl

;to check if password is out of range
cmp num2,15
ja  wrong

; new line:
putc 0Dh
putc 0Ah 


mov cx,20
mov bx,0
mov count,0

check:       
    mov dx,num1    
    cmp dx,CARD[bx]
    je  check2
    inc bx 
    inc bx
    inc count
    loop check 
    jmp  incorrect1
check2:
    mov dl,num2
    mov bx,count  
    cmp dl,PASS[bx] 
    je  allowed
    jmp incorrect2
    
allowed:
      lea dx, msg3
      mov ah, 09h   
      int 21h 
      jmp finish
      
incorrect1:
      lea dx,msg5
      mov ah, 09h   
      int 21h
       
      jmp denied
      
incorrect2:
      lea dx, msg6
      mov ah, 09h   
      int 21h
      jmp denied
      
      
denied: 
      lea dx, msg4
      mov ah, 09h   
      int 21h 
      jmp finish

wrong:
      lea dx, msg8  ;msg8"password out of range!,please enter again"
      mov ah, 09h   
      int 21h 
      jmp start3
       

finish:

    ; new line:
    putc 0Dh
    putc 0Ah 

    lea dx,msg7
    mov ah,09h 
    int 21h 
    call SCAN_NUM
    cmp cx,1
    jne start2
    je  exit
    
exit:
    mov ah,4ch 
    int 21h
     

              
; gets the multi-digit SIGNED number from the keyboard,
; and stores the result in CX register:
SCAN_NUM        PROC    NEAR
        PUSH    DX
        PUSH    AX
        PUSH    SI
        
        MOV     CX, 0

        ; reset flag:
        MOV     CS:make_minus, 0

next_digit:

        ; get char from keyboard
        ; into AL:
        MOV     AH, 00h
        INT     16h
        ; and print it:
        MOV     AH, 0Eh
        INT     10h

        ; check for MINUS:
        CMP     AL, '-'
        JE      set_minus

        ; check for ENTER key:
        CMP     AL, 0Dh  ; carriage return?
        JNE     not_cr
        JMP     stop_input
not_cr:


        CMP     AL, 8                   ; 'BACKSPACE' pressed?
        JNE     backspace_checked
        MOV     DX, 0                   ; remove last digit by
        MOV     AX, CX                  ; division:
        DIV     CS:ten                  ; AX = DX:AX / 10 (DX-rem).
        MOV     CX, AX
        PUTC    ' '                     ; clear position.
        PUTC    8                       ; backspace again.
        JMP     next_digit
backspace_checked:


        ; allow only digits:
        CMP     AL, '0'
        JAE     ok_AE_0
        JMP     remove_not_digit
ok_AE_0:        
        CMP     AL, '9'
        JBE     ok_digit
remove_not_digit:       
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered not digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for next input.       
ok_digit:


        ; multiply CX by 10 (first time the result is zero)
        PUSH    AX
        MOV     AX, CX
        MUL     CS:ten                  ; DX:AX = AX*10
        MOV     CX, AX
        POP     AX

        ; check if the number is too big
        ; (result should be 16 bits)
        CMP     DX, 0
        JNE     too_big

        ; convert from ASCII code:
        SUB     AL, 30h

        ; add AL to CX:
        MOV     AH, 0
        MOV     DX, CX      ; backup, in case the result will be too big.
        ADD     CX, AX
        JC      too_big2    ; jump if the number is too big.

        JMP     next_digit

set_minus:
        MOV     CS:make_minus, 1
        JMP     next_digit

too_big2:
        MOV     CX, DX      ; restore the backuped value before add.
        MOV     DX, 0       ; DX was zero before backup!
too_big:
        MOV     AX, CX
        DIV     CS:ten  ; reverse last DX:AX = AX*10, make AX = DX:AX / 10
        MOV     CX, AX
        PUTC    8       ; backspace.
        PUTC    ' '     ; clear last entered digit.
        PUTC    8       ; backspace again.        
        JMP     next_digit ; wait for Enter/Backspace.
        
        
stop_input:
        ; check flag:
        CMP     CS:make_minus, 0
        JE      not_minus
        NEG     CX
not_minus:

        POP     SI
        POP     AX
        POP     DX
        RET
make_minus      DB      ?       ; used as a flag.
SCAN_NUM        ENDP




ten             DW      10      ; used as multiplier/divider by SCAN_NUM

