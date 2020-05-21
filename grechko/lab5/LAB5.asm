CODE			SEGMENT
			INTERRUPT_STACK	DB		256	DUP(?)

			KEEP_PSP 		DW 		0
			KEEP_SS			DW		0
			KEEP_SP			DW		0
			INTERRUPT_VEC		DD		0
			
			REQUEST_2		DB		3h
			REQUEST_4   	DB 		5h
			REQUEST_6		DB		7h
			REQUEST_8   	DB 		9h

			INTERRUPT_ID 	DW 		000FF00h
			ASSUME CS:CODE, DS:DATA, SS:STACK
;-----------------------------------------------------------
INTERRUPT 		PROC	FAR	
			mov		KEEP_SS, SS
			mov		KEEP_SP, SP
			mov		DX, CS
			mov		SS, DX
			mov		SP,	OFFSET INTERRUPT_STACK + 256	
			push 	DX
			push	AX
			in 		AL, 60h
			cmp		AL,	REQUEST_2
			je		req_2
			cmp		AL,	REQUEST_4
			je		req_4
			cmp		AL,	REQUEST_6
			je		req_6
			cmp		AL,	REQUEST_8
			je		req_8
			pop		AX
			mov		SS, KEEP_SS
			mov		SP,	KEEP_SP
			jmp	 	dword ptr CS:[INTERRUPT_VEC]
req_2:		mov 	CL, '@'
			jmp		request__
req_4:		mov 	CL, '$'
			jmp		request__
req_6:		mov 	CL, '^'
			jmp		request__
req_8:		mov 	CL, '*'
request__:	in 		AL, 61h 
			mov 	AH, AL 
			or 		AL, 80h 
			out 	61h, AL
			xchg 	AH, AL 
			out 	61h, AL
			mov 	AL, 20h
			out 	20h, AL
			mov 	AH, 05h
			mov 	CH, 00h
			int 	16h
			or 		AL, AL
			jnz 	skip__
			jmp 	return__
skip__: 	push 	ES
			push 	SI
			mov 	AX, 0040h
			mov 	ES, AX
			mov 	SI, 001Ah
			mov 	AX, ES:[SI] 
			mov 	SI, 001Ch
			mov 	ES:[SI], AX
			pop 	SI
			pop 	ES
return__:	pop 	AX
			mov 	AL, 20h
			out 	20h, AL
			
			pop		DX
			mov		SS, KEEP_SS
			mov		SP,	KEEP_SP
			iret 
interrupt_end_:			
INTERRUPT  		ENDP  
;-----------------------------------------------------------
IS_UNLOAD 		PROC	NEAR
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
   		 	ret
IS_UNLOAD 		ENDP
;-----------------------------------------------------------
IS_LOAD 		PROC	 NEAR
			push 	ES
			mov 	AX, 3509h
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
			push	AX
			mov 	AX, 3509h 
			int 	21h
			mov		word ptr INTERRUPT_VEC, BX
			mov		word ptr INTERRUPT_VEC + 2,ES
			pop 	AX


			push 	DS
			lea		DX, INTERRUPT
			mov 	AX, SEG INTERRUPT
			mov 	DS, AX
			mov 	AX, 2509h
			int 	21h 
			pop 	DS
			
			
			lea 	DX, MSG_LOAD
			call 	WRITE_STRING
			
			lea		DX, interrupt_end_
		    mov 	CL, 4h
		    shr 	DX, CL
		    inc 	DX
		    mov 	AX, CS
		    sub 	AX, KEEP_PSP
		    add 	DX, AX
		    xor 	AX, AX
		    mov 	AH, 31h
			
			int 	21h
			ret
LOAD_INTERRUPT  ENDP
;-----------------------------------------------------------
UNLOAD_INTERRUPT PROC	 NEAR
			push 	DS
			
			mov 	AX, 3509h
			int  	21h
			mov 	DX, word ptr ES:INTERRUPT_VEC
			mov 	AX, word ptr ES:INTERRUPT_VEC + 2
			mov 	word ptr INTERRUPT_VEC, DX
			mov 	word ptr INTERRUPT_VEC + 2, AX
			
			CLI
			mov  	DX, word ptr INTERRUPT_VEC
			mov  	AX, word ptr INTERRUPT_VEC + 2
			mov  	DS, AX
			mov  	AH, 25h
			mov  	AL, 09h
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
MAIN   			PROC 	FAR
			push	DS
			mov		AX,	0
			push	AX
			
			mov 	AX, DATA		  
			mov 	DS, AX
			mov 	KEEP_PSP, ES

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
CODE			ENDS
END				MAIN
		  
