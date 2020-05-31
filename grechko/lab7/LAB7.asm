;-----------------------------------------------------------
STACK		SEGMENT
						DW	256	DUP(?)
STACK		ENDS
;-----------------------------------------------------------
DATA		SEGMENT	
		ERR_4A00h_07_		DB		'ERROR_4A00H: CODE 7. (СONTROL MEMORY BLOCK WAS DESTROYED)', 0Dh, 0Ah, '$'
		ERR_4A00h_08_		DB		'ERROR_4A00H: CODE 8. (NOT ENOUGHT MEMORY)', 0Dh, 0Ah, '$'
		ERR_4A00h_09_		DB		'ERROR_4A00H: CODE 9. (INVALID ADDRESS OF MEMORY BLOCK)', 0Dh, 0Ah, '$'
		
		ERR_4B03h_01_		DB		'ERROR_4B03H: CODE 1. (NOT-EXISTENT FUNCTION)', 0Dh, 0Ah, '$'
		ERR_4B03h_02_		DB		'ERROR_4B03H: CODE 2. (FILE NOT FOUND)', 0Dh, 0Ah, '$'
		ERR_4B03h_03_		DB		'ERROR_4B03H: CODE 3. (PATH NOT FOUND)', 0Dh, 0Ah, '$'
		ERR_4B03h_04_		DB		'ERROR_4B03H: CODE 4. (TOO MANY OPENED FILES)', 0Dh, 0Ah, '$'
		ERR_4B03h_05_		DB		'ERROR_4B03H: CODE 5. (NO ACSESS)', 0Dh, 0Ah, '$'
		ERR_4B03h_08_		DB		'ERROR_4B03H: CODE 8. (NOT ENOUGHT MEMORY)', 0Dh, 0Ah, '$'
		ERR_4B03h_10_		DB		'ERROR_4B03H: CODE 10. (INCORRECT ENVIRONMENT)', 0Dh, 0Ah, '$'
		
		ERR_4E00h_02_		DB		'ERROR_4E00H: CODE 2. (FILE NOT FOUND)', 0Dh, 0Ah, '$'
		ERR_4E00h_03_		DB		'ERROR_4E00H: CODE 3. (PATH NOT	FOUND)', 0Dh, 0Ah, '$'
		
		IS_4A00h_ERR		DB		0
		
		PATH_NAME			DB		64	DUP(?)
		DTA					DB		43	DUP(?)
		
		OVERLAY_NAME_1		DB		'OVERLAY1.OVL$'
		OVERLAY_NAME_2		DB		'OVERLAY2.OVL$'
		OVERLAY_PARAMETERS	DW		0,0
		OVERLAY_ADDRESS		DD		0
DATA		ENDS
;-----------------------------------------------------------
CODE		SEGMENT
			.386
   			ASSUME CS:CODE,DS:DATA,SS:STACK
;-----------------------------------------------------------
WRITE_STRING    PROC		NEAR
			push 	AX
			
		    mov 	AH, 09h
		    int 	21h
			
		    pop 	AX
		    	ret
WRITE_STRING    ENDP
;-----------------------------------------------------------
ERR_4A00H       PROC
			mov		IS_4A00h_ERR, 1h
			
			cmp		AX,	7
			jne		next_8__
			lea		DX,	ERR_4A00h_07_
			jmp		err_ret__
			
next_8__:	cmp		AX,	8
			jne     next_9__
			lea		DX,	ERR_4A00h_08_
			jmp		err_ret__
			
next_9__:	cmp		AX,	9
			lea		DX,	ERR_4A00h_09_	
			
err_ret__:	call	WRITE_STRING
				ret
ERR_4A00H	    ENDP
;-----------------------------------------------------------
ERR_4B03H		PROC
			cmp		AX, 1
			jne		next_2_
			lea		dx,	ERR_4B03h_01_
			jmp		error_ret_
			
next_2_:	cmp		AX,	2
			jne		next_3_
			lea		dx,	ERR_4B03h_02_
			jmp		error_ret_
					
next_3_:	cmp		AX,	3
			jne		next_3_
			lea		dx,	ERR_4B03h_03_
			jmp		error_ret_				
			
next_4_:	cmp		AX,	4
			jne		next_3_
			lea		dx,	ERR_4B03h_04_
			jmp		error_ret_	
						
next_5_:	cmp		AX,	5
			jne		next_3_
			lea		dx,	ERR_4B03h_05_
			jmp		error_ret_	
			
next_8_:	cmp		AX,	8
			jne		next_3_
			lea		dx,	ERR_4B03h_08_
			jmp		error_ret_	
						
next_10_:	cmp		AX,	10
			jne		call_ret_
			lea		dx,	ERR_4B03h_10_	
					
error_ret_:	call	WRITE_STRING	
				ret
ERR_4B03H		ENDP
;-----------------------------------------------------------
GET_MEMORY		PROC	NEAR	
			push	AX
			push	BX
			push	CX
			
			lea		AX, ending_	
			mov 	BX, ES
			sub 	AX, BX
			mov 	CX, 0004h		
			shl 	AX, CL
			mov 	BX, AX
	
			mov 	AX, 4A00h		
			int 	21h	
			
			jnc		mem_ret__
			call	ERR_4A00H

mem_ret__:	pop		CX
			pop 	BX
			pop		AX
				ret
GET_MEMORY		ENDP
;-----------------------------------------------------------
GET_PATH		PROC
			push	DX
			push	DI
			push	SI
			push	ES
			
			xor		DI, DI
			mov		ES, ES:[2Ch]
			
next_:		mov		DL, ES:[DI]
			cmp		DL, 0h
			je		last_
			inc		DI
			jmp		next_

last_:		inc		DI
			mov		DL, ES:[DI]
			cmp		DL, 0h
			jne		next_
			
			add		DI, 3h
			mov		SI,	0
			
write_:		mov		DL,	ES:[DI]
			cmp		DL, 0h
			je		delete_
			mov		PATH_NAME[SI], DL
			inc		DI
			inc		SI
			jmp		write_
			
delete_:	dec		SI
			cmp		PATH_NAME[SI], '\'
			jne		delete_	
			
			mov		DI, -1
			
add_name_:	inc		DI
			inc		SI
			mov		DL, [BX + DI]
			cmp		DL, '$'
			je		path_ret_
			mov		PATH_NAME[SI], DL
			jmp		add_name_ 
			
path_ret_:	mov		PATH_NAME[SI], '$'
			pop		ES
			pop		SI
			pop		DI
			pop		DX
				ret
GET_PATH		ENDP
;-----------------------------------------------------------
GET_SIZE		PROC
			push	AX
			push	BX
			push	CX
			push	DX
			push	BP
			
			mov		AH, 1Ah
			lea		DX,	DTA
			int 	21h
			
			mov		AX,	4E00h
			lea		DX,	PATH_NAME
			mov		CX,	0
			int		21h
			
			jc		error_
			
			lea		SI,	DTA
			add		SI,	1Ah
			mov		BX,	[SI]
			mov		CL,	4
			shr		BX,	CL
			mov		AX,	[SI + 2]
			mov		CL, 12
			shl		AX,	CL
			add		BX, AX
			add		BX,	2
			
			mov		AX, 4800h
			int		21h
			
			jc		size_ret_
			
			mov		OVERLAY_PARAMETERS,	AX
			mov		OVERLAY_PARAMETERS + 2, AX
			jmp		size_ret_
		
		
error_:		cmp		AX,	2
			jne		next_3__
			lea		DX,	ERR_4E00h_02_
			jmp		err_ret_
			
next_3__:	cmp		AX,	3
			jne		size_ret_
			lea		DX,	ERR_4E00h_03_
			
err_ret_: 	call 	WRITE_STRING		
size_ret_:	pop		BP
			pop		DX
			pop		CX
			pop		DX
			pop		AX
			ret
GET_SIZE		ENDP
;-----------------------------------------------------------
CALL_OVERLAY	PROC
			push	AX
			push	DX
			push	ES
			
			lea		DX,	PATH_NAME
			push	DS
			pop		ES
			lea		BX,	OVERLAY_PARAMETERS
			
			mov		AX,	4B03h
			int		21h
			
			jc		error__
			
			mov		AX,	OVERLAY_PARAMETERS
			mov		word ptr OVERLAY_ADDRESS + 2, AX
			call	OVERLAY_ADDRESS
			mov		ES,	AX
			mov		AX,	4900h
			int		21h
			jmp		call_ret_
			
error__:	call	ERR_4B03H
call_ret_:	pop		ES
			pop		DX
			pop		AX
			ret
CALL_OVERLAY	ENDP
;-----------------------------------------------------------
MAIN			PROC
			mov		AX,	DATA
			mov		DS,	AX
			
			call	GET_MEMORY
			
			cmp		IS_4A00h_ERR, 1h
			je		end_
			
			; overlay 1
			lea		BX,	OVERLAY_NAME_1
			call	GET_PATH
			call	GET_SIZE
			call	CALL_OVERLAY
			
			; overlay 2
			lea		BX, OVERLAY_NAME_2
			call	GET_PATH
			call	GET_SIZE
			call	CALL_OVERLAY
			
end_:		mov		AX,	4C00h
			int		21h			
MAIN			ENDP
ending_:
CODE		ENDS
END			MAIN