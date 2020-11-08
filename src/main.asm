; When a key is pressed the key number
; is placed in R0.

; For this program, the keys are numbered
; as:

;	+----+----+----+
;	| 11 | 10 |  9 |	row3
;	+----+----+----+
;	|  8 |  7 |  6 |	row2
;	+----+----|----+
;	|  5 |  4 |  3 |	row1
;	+----+----+----+
;	|  2 |  1 |  0 |	row0
;	+----+----+----+
;	 col2 col1 col0

; The pressed key number will be stored in
; R0. Therefore, R0 is initially cleared.
; Each key is scanned, and if it is not
; pressed R0 is incremented. In that way,
; when the pressed key is found, R0 will
; contain the key's number.

; The general purpose flag, F0, is used
; by the column-scan subroutine to indicate
; whether or not a pressed key was found
; in that column.
; If, after returning from colScan, F0 is
; set, this means the key was found.


; --- Mapeamento de Hardware (8051) ---
    RS      equ     P1.3    ;Reg Select ligado em P1.3
    EN      equ     P1.2    ;Enable ligado em P1.2


org 0000h
	MOV R0, #7Fh
	LJMP CLEAR_RAM

org 0030h
START:
	ACALL SET_OPERATIONS
	ACALL INITIALIZE_CHARACTERS
	ACALL INITIALIZE_POINTERS
	LJMP MAIN

MAIN:
	ACALL lcd_init
	LJMP ROTINA

ADDITION:
	SETB P2.7
	MOV 5AH, #01H
	RET

SUBTRACTION:
	SETB P2.7
	MOV 5AH, #02H
	RET

PRODUCT:
	SETB P2.7
	MOV 5AH, #03H
	RET

DIVISION:
	SETB P2.7
	MOV 5AH, #04H
	RET	

FIND_OP:
	JNB P2.0, ADDITION
	JB P2.7, finish
	JNB P2.1, SUBTRACTION
	JB P2.7, finish
	JNB P2.2, PRODUCT
	JB P2.7, finish
	JNB P2.3, DIVISION
	JB P2.7, finish
	RET

ROTINA:
	CLR C
;	CJNE P2, #0FH, FIND_OP
	ACALL FIND_OP
	ACALL WHICH_NUMBER
	ACALL leituraTeclado
	JNB F0, ROTINA   ;if F0 is clear, jump to ROTINA
	ACALL CHOOSE_LINE
	ACALL posicionaCursor	
	MOV A, #40h
	ADD A, R0
	MOV R0, A
	MOV A, @R0        
	ACALL sendCharacter
	CLR F0
	JMP ROTINA

WHICH_NUMBER:
	MOV C, P3.0
	ORL C, P2.7
	MOV P3.0, C
	CLR P2.7
	RET

CHOOSE_LINE:
	JNB P3.0, FIRST_LINE
	JB P3.0, SECOND_LINE
	RET

FIRST_LINE:
	MOV A, 51H
	RET

SECOND_LINE:
	MOV A, 50H
	RET

leituraTeclado:
	MOV R0, #0			; clear R0 - the first key is key0

	; scan row0
	MOV P0, #0FFh	
	CLR P0.0			; clear row0
	CALL colScan		; call column-scan subroutine
	JB F0, finish		; | if F0 is set, jump to end of program 
						; | (because the pressed key was found and its number is in  R0)
	; scan row1
	SETB P0.0			; set row0
	CLR P0.1			; clear row1
	CALL colScan		; call column-scan subroutine
	JB F0, finish		; | if F0 is set, jump to end of program 
						; | (because the pressed key was found and its number is in  R0)
	; scan row2
	SETB P0.1			; set row1
	CLR P0.2			; clear row2
	CALL colScan		; call column-scan subroutine
	JB F0, finish		; | if F0 is set, jump to end of program 
						; | (because the pressed key was found and its number is in  R0)
	; scan row3
	SETB P0.2			; set row2
	CLR P0.3			; clear row3
	CALL colScan		; call column-scan subroutine
	JB F0, finish		; | if F0 is set, jump to end of program 
						; | (because the pressed key was found and its number is in  R0)
finish:
	RET

; column-scan subroutine
colScan:
	JNB P0.4, gotKey	; if col0 is cleared - key found
	INC R0				; otherwise move to next key
	JNB P0.5, gotKey	; if col1 is cleared - key found
	INC R0				; otherwise move to next key
	JNB P0.6, gotKey	; if col2 is cleared - key found
	INC R0				; otherwise move to next key
	RET					; return from subroutine - key not found

gotKey:
	SETB F0				; key found - set F0
	CJNE R0, #0AH, VALIDACAO_DO_CHARACTER
	ACALL clearDisplay
	CLR F0
	RET					; and return from subroutine

VALIDACAO_DO_CHARACTER:
	JC CHARACTER_IS_NUM
	JNC EQUAL_OP
	LJMP ROTINA
	
EQUAL_OP:
	CLR F0
	CLR P3.0
	LJMP ROTINA

CHARACTER_IS_NUM:
	CLR C
	JB P3.0, GUARDA_NUM2
	JNB P3.0, GUARDA_NUM1
	CALL CALLS_LONG_DELAY
	CALL CALLS_LONG_DELAY
	CALL CALLS_LONG_DELAY
	CALL CALLS_LONG_DELAY
	CALL CALLS_LONG_DELAY
	CALL CALLS_LONG_DELAY
	LJMP ROTINA

GUARDA_NUM1:
	INC 51H
	MOV A, R0

	SETB RS0
	SETB RS1

	ACALL SORT_FIRST_NUMBER_START
	INC 54H
	MOV 58H, 54H
	MOV @R0, A
;	DEC R0

	DEC 56H

	CLR RS0
	CLR RS1

	RET

GUARDA_NUM2:
	INC 50H
	MOV A, R0

	SETB RS0
	SETB RS1

	ACALL SORT_SECOND_NUMBER_START
	INC 55H
	MOV 59H, 55H
	MOV @R1, A
;	DEC R1

	DEC 57H

	CLR RS0
	CLR RS1

	RET


; initialise the display
; see instruction set for details
lcd_init:

	CLR RS		; clear RS - indicates that instructions are being sent to the module

; function set	
	CLR P1.7		; |
	CLR P1.6		; |
	SETB P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear	
					; function set sent for first time - tells module to go into 4-bit mode
; Why is function set high nibble sent twice? See 4-bit operation on pages 39 and 42 of HD44780.pdf.

	SETB EN		; |
	CLR EN		; | negative edge on E
					; same function set high nibble sent a second time

	SETB P1.7		; low nibble set (only P1.7 needed to be changed)

	SETB EN		; |
	CLR EN		; | negative edge on E
				; function set low nibble sent
	CALL delay		; wait for BF to clear


; entry mode set
; set to increment with no shift
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	SETB P1.6		; |
	SETB P1.5		; |low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear


; display on/off control
; the display is turned on, the cursor is turned on and blinking is turned on
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	SETB P1.7		; |
	SETB P1.6		; |
	SETB P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear
	RET


sendCharacter:
	SETB RS  		; setb RS - indicates that data is being sent to module
	MOV C, ACC.7		; |
	MOV P1.7, C			; |
	MOV C, ACC.6		; |
	MOV P1.6, C			; |
	MOV C, ACC.5		; |
	MOV P1.5, C			; |
	MOV C, ACC.4		; |
	MOV P1.4, C			; | high nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	MOV C, ACC.3		; |
	MOV P1.7, C			; |
	MOV C, ACC.2		; |
	MOV P1.6, C			; |
	MOV C, ACC.1		; |
	MOV P1.5, C			; |
	MOV C, ACC.0		; |
	MOV P1.4, C			; | low nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	CALL delay			; wait for BF to clear
	CALL delay			; wait for BF to clear
	RET

;Posiciona o cursor na linha e coluna desejada.
;Escreva no Acumulador o valor de endereço da linha e coluna.
;|--------------------------------------------------------------------------------------|
;|linha 1 | 00 | 01 | 02 | 03 | 04 |05 | 06 | 07 | 08 | 09 |0A | 0B | 0C | 0D | 0E | 0F |
;|linha 2 | 40 | 41 | 42 | 43 | 44 |45 | 46 | 47 | 48 | 49 |4A | 4B | 4C | 4D | 4E | 4F |
;|--------------------------------------------------------------------------------------|
posicionaCursor:
	CLR RS	
	SETB P1.7		    ; |
	MOV C, ACC.6		; |
	MOV P1.6, C			; |
	MOV C, ACC.5		; |
	MOV P1.5, C			; |
	MOV C, ACC.4		; |
	MOV P1.4, C			; | high nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E

	MOV C, ACC.3		; |
	MOV P1.7, C			; |
	MOV C, ACC.2		; |
	MOV P1.6, C			; |
	MOV C, ACC.1		; |
	MOV P1.5, C			; |
	MOV C, ACC.0		; |
	MOV P1.4, C			; | low nibble set

	SETB EN			; |
	CLR EN			; | negative edge on E
	
	CALL delay			; wait for BF to clear
	CALL delay			; wait for BF to clear
	RET


;Retorna o cursor para primeira posição sem limpar o display
retornaCursor:
	CLR RS	
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CLR P1.7		; |
	CLR P1.6		; |
	SETB P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear
	RET


;Limpa o display
clearDisplay:
	CLR P3.0
	MOV 51H, 4EH
	MOV 50H, 4FH
	CLR RS	
	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	CLR P1.4		; | high nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CLR P1.7		; |
	CLR P1.6		; |
	CLR P1.5		; |
	SETB P1.4		; | low nibble set

	SETB EN		; |
	CLR EN		; | negative edge on E

	CALL delay		; wait for BF to clear
	RET


delay:
	MOV R7, #50
	DJNZ R7, $
	RET

CALLS_LONG_DELAY:
	MOV R5, #255h
	ACALL LONG_DELAY
	RET

LONG_DELAY:
	ACALL delay
	DJNZ R7, LONG_DELAY
	RET

CLEAR_RAM:
	MOV @R0, #00h
	DJNZ R0, CLEAR_RAM
	LJMP START

SET_OPERATIONS:
	SETB P2.0
	SETB P2.1
	SETB P2.2
	SETB P2.3
	CLR P2.4
	CLR P2.5
	CLR P2.6
	CLR P2.7

	RET

INITIALIZE_CHARACTERS:
	; put data in RAM
	MOV 40H, #'0' 
	MOV 41H, #'1'
	MOV 42H, #'2'
	MOV 43H, #'3'
	MOV 44H, #'4'
	MOV 45H, #'5'
	MOV 46H, #'6'
	MOV 47H, #'7'
	MOV 48H, #'8'
	MOV 49H, #'9'
	MOV 4AH, #'C'
	MOV 4BH, #'B'

	RET

INITIALIZE_POINTERS:
	;LCD Cursor Position
	MOV 4EH,	#01h 	;backup first line
	MOV 4FH,	#40h 	;backup second line
	MOV 50H, 	#40H	;position second line
	MOV 51H,	#01h	;position first line
	MOV 52H,	#6FH	;Backup position of the start of the first number
	MOV 53H,	#7FH	;Backup position of the start of the second number
	MOV 54h,	#00h	;Backup Number of digits of the first number
	MOV 55h,	#00h	;Backup Number of digits of the second number
	MOV 56h,	#6FH	;First Number Cursor	
	MOV 57h,	#7FH	;Second Number Cursor
	MOV 58H,	54H		;Number of Digits in First Number
	MOV 59H,	55h		;Number of Digits in Second Number
	SETB RS0
	SETB RS1

	MOV R0,		52H   ;First number digits
	MOV R1,		53H   ;Second number digits
	
	CLR RS0
	CLR RS1

	CLR P3.0 			;Checks whether it is the first
						;or the second number being typed

	RET

SORT_FIRST_NUMBER_START:
	MOV B, R0
	MOV R5, B
	MOV R6, A
	MOV A, 58H
	JZ FINISH2
	ACALL SORT_FIRST_NUMBER
	MOV B, R5
	MOV R0, B
	MOV A, R6
	RET

SORT_FIRST_NUMBER:
	MOV A, 52H
	SUBB A, 58H
	MOV R0, A
	INC A
	MOV R1, A
	MOV A, @R1
	MOV @R0, A
	DJNZ 58H, SORT_FIRST_NUMBER
	RET

SORT_SECOND_NUMBER_START:
	MOV B, R0
	MOV R5, B
	MOV R6, A
	MOV A, 59H
	JZ FINISH2
	ACALL SORT_SECOND_NUMBER
	MOV B, R5
	MOV R0, B
	MOV A, R6
	RET

SORT_SECOND_NUMBER:
	MOV A, 53H
	SUBB A, 59H
	MOV R0, A
	INC A
	MOV R1, A
	MOV A, @R1
	MOV @R0, A
	DJNZ 59H, SORT_SECOND_NUMBER
	RET

FINISH2:
	MOV B, R5
	MOV R0, B
	MOV A, R6
	RET
	