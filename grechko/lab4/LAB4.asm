;-----------------------------------------------------------
DATA			SEGMENT
			MSG_LOAD   		DB 		'my interrupt has been loaded  ', 0Dh, 0Ah, '$'
			MSG_UNL			DB 		'my interrupt unloaded         ', 0Dh, 0Ah, '$'
			MSG_ALR			DB 		'my interrupt is already loaded', 0Dh, 0Ah, '$'
			FLAG_UNLOAD 	DB 		0
			FLAG_LOAD 		DB 		0
DATA	        ENDS
;-----------------------------------------------------------
STACK			SEGMENT
							DW		256	DUP(?)
STACK			ENDS
;-----------------------------------------------------------
CODE			SEGMENT
				ASSUME CS:CODE, DS:DATA, SS:STACK
					
			KEEP_PSP 		DW 		0
			KEEP_CS 		DW 		0 
			KEEP_IP 		DW 		0
			KEEP_ES			DW		0
			KEEP_BX			DW		0
			KEEP_SS			DW		0
			KEEP_SP			DW		0
			
			COUNTER 		DB 		0
			INTERRUPT_ID 	DW 		0000FF00h
			INTERRUPT_STACK	DB		256 DUP(?)
;-----------------------------------------------------------
INTERRUPT 		PROC 	FAR
			mov		KEEP_SS, SS
			mov		KEEP_SP, SP
			
			mov		AX,	CS
			mov		SS, AX
			mov		SP, OFFSET INTERRUPT_STACK + 256
			
			push 	AX
			push 	ES
			
			inc 	COUNTER
			cmp 	COUNTER, 10
			jne 	begin_
			mov 	COUNTER, 0
begin_: 	mov 	AL, COUNTER
			or 		AL, 30h
			call 	GET_CURSOR
			call 	SET_CURSOR
			call 	OUTPUT_AL
			call 	RET_CURSOR
			
			pop 	ES
			pop 	AX
			mov 	AL, 20h
			out  	20h, AL
			
			mov		SS, KEEP_SS
			mov		SP,	KEEP_SP
			iret			
INTERRUPT  		ENDP  
;-----------------------------------------------------------
SET_CURSOR		PROC	NEAR
			mov 	AH,	02h
			mov 	BH,	0
			mov 	DH,	24
			mov		DL,	40 
			int 	10h 
			ret
SET_CURSOR		ENDP
;-----------------------------------------------------------
GET_CURSOR		PROC	NEAR
			push 	AX
			push 	BX
			push	DX

			mov 	AH, 03h
			mov 	BH, 0
			int 	10h 
			mov		ES,	DX
			
			pop		DX
			pop 	BX
			pop 	AX
			ret
GET_CURSOR		ENDP
;-----------------------------------------------------------
RET_CURSOR		PROC	NEAR
			mov 	ah, 2h
			mov 	bh, 0
			mov		dx,	es
			int 	10h 
			ret
RET_CURSOR		ENDP
;-----------------------------------------------------------
IS_UNLOAD 		PROC	NEAR
			push 	ES
			push 	AX
			
			mov		AX, KEEP_PSP
			mov		ES, AX
			sub		AX, AX
			cmp		byte ptr ES:[82h], '/'
			jne		false_
			cmp		byte ptr ES:[83h], 'u'
			jne		false_
			cmp		byte ptr ES:[84h], 'n'
			jne		false_
			mov		FLAG_UNLOAD, 1h
			
false_:   	pop 	AX
			pop 	ES
   		 	ret
IS_UNLOAD 		ENDP
;-----------------------------------------------------------
OUTPUT_AL 		PROC 	NEAR
			push 	AX
			push 	BX
			push 	CX

			mov 	AH, 09h
			mov 	BH, 0
			mov 	CX, 1
			int 	10h

			pop 	CX
			pop 	BX
			pop 	AX
			ret
OUTPUT_AL 		ENDP
;-----------------------------------------------------------
IS_LOAD 		PROC	 NEAR
			push 	ES
			mov 	AX, 351Ch
			int  	21h
			mov  	DX, ES:[BX - 2]
			pop 	ES
			cmp 	DX, INTERRUPT_ID
			jne 	return_
			mov 	FLAG_LOAD, 1h
return_:	ret
IS_LOAD 		ENDP
;-----------------------------------------------------------
WRITE_STRING   PROC		NEAR
        	push 	AX
			
        	mov 	AH, 09h
        	int 	21h
			
        	pop 	AX
        	ret
WRITE_STRING   ENDP
;-----------------------------------------------------------
LOAD_INTERRUPT	PROC	NEAR
			mov 	AX, 351Ch 
			int 	21h
			mov  	KEEP_IP, BX 
			mov  	KEEP_CS, ES 
			mov 	word ptr KEEP_BX, BX
			mov 	word ptr KEEP_ES, ES

			push 	DS
			lea		DX, INTERRUPT
			mov 	AX, SEG INTERRUPT
			mov 	DS, AX
			mov 	AX, 251Ch
			int 	21h 
			pop 	DS
			
			lea 	DX, MSG_LOAD
			call 	WRITE_STRING
			
			lea 	DX, exit_
			sub 	DX, KEEP_PSP
			
			mov 	CL, 4
			shr 	DX, CL
			mov 	AH, 31h
			int 	21h
			ret
LOAD_INTERRUPT  ENDP
;-----------------------------------------------------------
UNLOAD_INTERRUPT PROC	 NEAR
			push 	DS
			
			mov 	AX, 351Ch
			int  	21h
			mov 	DX, word ptr ES:KEEP_BX
			mov 	AX, word ptr ES:KEEP_ES
			mov 	KEEP_IP, DX
			mov 	KEEP_CS, AX
			
			CLI
			mov  	DX, KEEP_IP
			mov  	AX, KEEP_CS
			mov  	DS, AX
			mov  	AH, 25h
			mov  	AL, 1Ch
			int  	21h
			STI
			
			pop		DS
			
			mov		ES, ES:KEEP_PSP
			mov		AH,	49h
			int		21h
			mov		FLAG_UNLOAD, 0	
				
			ret
UNLOAD_INTERRUPT ENDP
;-----------------------------------------------------------
MAIN   			PROC 	 FAR
			mov 	AX, DS
			mov 	AX, DATA		  
			mov 	DS, AX
			mov 	AX, ES
			mov 	KEEP_PSP, AX

			call	IS_LOAD
			cmp 	FLAG_LOAD, 1h
			je 		unload_
			call 	LOAD_INTERRUPT
			
unload_:	call 	IS_UNLOAD		
			cmp 	FLAG_UNLOAD, 1h
			jne 	already_	
			call 	UNLOAD_INTERRUPT
			lea 	DX, MSG_UNL
			call 	WRITE_STRING
			jmp		exit_ 
			
already_:	lea 	DX, MSG_ALR
			call 	WRITE_STRING
			
exit_:		mov 	AH, 4Ch                        
			int  	21h
MAIN      		ENDP
CODE			ENDS
END				MAIN
		  
