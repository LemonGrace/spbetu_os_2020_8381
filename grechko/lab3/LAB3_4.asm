MCB_4		SEGMENT
			ASSUME	CS:MCB_4,	DS:MCB_4,	ES:NOTHING,	SS:NOTHING
			ORG		100H
START:		JMP		BEGIN
; §¡ÕÕò©
MEMORY_AVL		db		'Available memory :        b', 0dh, 0ah, '$'
MEMORY_EXT	    db		'Extended  memory :        Kb', 0dh, 0ah, '$'
MCB_LIST		db		'MCB (memory control box) :', 0dh, 0ah, '$'
MCB_TYPE		db		'[ type :   h ]$'
MCB_PSP		    db		'[ address (PSP) :     h ]$'
MCB_SIZE	    db		'[ size :        b ]$'
MCB_TAIL		db		'                    ', 0dh, 0ah, '$'
MEMORY_FAIL		db		'Memory allocation failed!', 0dh, 0ah, '$'

; Ýâ×¥©§èâò
;-----------------------------------------------------------
WRITE_STRING	PROC	near
			mov		AH, 09h
			int		21h
			ret
WRITE_STRING	ENDP
;---------------------------
TETR_TO_HEX		PROC	near
			and		AL, 0fh
			cmp		AL, 09
			jbe		NEXT
			add		AL, 07
NEXT:		add		AL, 30h
			ret
TETR_TO_HEX		ENDP
;---------------------------
BYTE_TO_HEX		PROC 	near
; ¢ ½å ë AL Ø¨á¨ëÖ¦·åãÞ ë ¦ë  ã·ÒëÖÐ  õ¨ãåÔ. û·ãÐ  ë AX
			push	CX
			mov		AH, AL
			call	TETR_TO_HEX
			xchg	AL, AH
			mov		CL, 4
			shr		AL, CL
			call	TETR_TO_HEX ; ë AL ãå áõ Þ ¤·ªá 
			pop		CX 			; ë AH ÒÐ ¦õ Þ
			ret
BYTE_TO_HEX		ENDP
;--------------------------
WRD_TO_HEX		PROC	near
; Ø¨áëÖ¦ ë 16 ã/ã 16-å· á óáÞ¦ÔÖ¬Ö û·ãÐ 
; ë AX - û·ãÐÖ, DI -  ¦á¨ã ØÖãÐ¨¦Ô¨¬Ö ã·ÒëÖÐ 
			push	BX
			mov		BH, AH
			call	BYTE_TO_HEX
			mov		[DI], AH
			dec		DI
			mov		[DI], AL
			dec		DI
			mov		AL, BH
			call	BYTE_TO_HEX
			mov		[DI], AH
			dec		DI
			mov		[DI], AL
			pop		BX
			ret
WRD_TO_HEX		ENDP
;--------------------------
BYTE_TO_DEC 	PROC 	near
; Ø¨á¨ëÖ¦ ë 10 ã/ã, SI -  ¦á¨ã ØÖÐÞ ÒÐ ¦õ¨½ ¤·ªáñ
            push    CX
            push    DX
            xor     AH, AH
            xor     DX, DX
            mov     CX, 10
LOOP_BD:    div     CX
          	or      DL, 30h
			mov     [SI], DL
			dec     SI
			xor     DX, DX
			cmp     AX, 10
			jae     LOOP_BD
			cmp     AL, 00h
			je      END_BD
			or      AL, 30h
			mov     [SI], AL
END_BD:		pop     DX
			pop 	CX
          	ret
BYTE_TO_DEC    	ENDP
;--------------------------
; Ø¨á¨ëÖ¦ ë 10 ã/ã, SI -  ¦á¨ã ØÖÐÞ ÒÐ ¦õ¨½ ¤·ªáñ
WRD_TO_DEC		PROC	near
			push	CX
			push	DX
			push	AX
			
			mov		CX, 10
LOOP_WD:	div		CX
			or		DL,	30h
			mov		[SI], DL
			dec		SI
			xor		DX, DX
			cmp		AX, 10
			jae		LOOP_WD
			cmp		AX, 00h
			jbe		END_WD
			or		AL, 30h
			mov		[SI], AL
END_WD:		pop		AX
			pop		DX
			pop		CX
			ret
WRD_TO_DEC		ENDP
;--------------------------
; ÖØá¨¦¨Ð¨Ô·¨ ÆÖÐ·û¨ãåë  ¦ÖãåçØÔÖ½ Ø ÒÞå·
DEF_MEMORY_AVL	PROC	near
			push	AX
			push	BX
			push	CX
			push	DX
			
			mov		BX, 0FFFFh
			mov		AH, 4Ah
			int		21h
			mov		AX, BX
			mov 	CX,	10h
			mul		CX
			lea		SI,	MEMORY_AVL + 24
			call	WRD_TO_DEC
			lea		DX, MEMORY_AVL
			call	WRITE_STRING
			; ó ØáÖã Ø ÒÞå·
		    mov		BX, 1000h
		    mov		AH, 48h
			int		21h
			jnc		ALL_FAIL
			lea		DX,	MEMORY_FAIL
			call	WRITE_STRING
			; ÖãëÖ¢Öé¦¨Ô·¨ Ø ÒÞå·
			lea 	AX, EXIT
		    mov		BX, 10h
		    sub 	DX, DX
		    div 	BX
		    inc 	AX
		    mov 	BX, AX
		    mov 	AL, 0
		    mov 	AH, 4Ah
		    int 	21h
ALL_FAIL:	pop		DX
			pop		CX
			pop		BX
			pop		AX
			ret
DEF_MEMORY_AVL	ENDP
;--------------------------
; ÖØá¨¦¨Ð¨Ô·¨ ÆÖÐ·û¨ãåë  á ãõ·á¨ÔÔÖ½ Ø ÒÞå·
DEF_MEMORY_EXT	PROC	near
			push	AX
			push	BX
			push	SI
			push	DX
			
			mov		AL, 30h
			out		70h, AL
			in		AL, 71h
			mov		BL, AL
			mov		Al, 31h
			out		70h, AL
			in		AL,	71h
			mov		AH,	AL
			mov		AL,	BL
			sub		DX,	DX
			lea		SI, MEMORY_EXT + 24
			call	WRD_TO_DEC
			lea		DX,	MEMORY_EXT
			call	WRITE_STRING
			
			pop		DX
			pop		SI
			pop		BX
			pop		AX
			ret
DEF_MEMORY_EXT	ENDP
;--------------------------
; ÖØá¨¦¨Ð¨Ô·¨ ÆÖÐ·û¨ãåë  á ãõ·á¨ÔÔÖ½ Ø ÒÞå·
DEF_MCB			PROC	near
			push	AX
			push	BX
			push	CX
			push	DX
			lea		DX, MCB_TAIL
			call	WRITE_STRING
			lea 	DX,	MCB_LIST
			call	WRITE_STRING
			mov		AH, 52h
			int		21h
			mov		ES, ES:[BX - 2]
			mov		BX, 1
WHILE_MCB:	sub		AX, AX
			sub		CX, CX
			sub		DI, DI
			sub		SI, SI
			mov		AL, ES:[0000h]
			call 	BYTE_TO_HEX
			lea		DI, MCB_TYPE + 9
			mov		[DI], AX
			cmp		AX, 4135h
			je 		DEF_BX
CONTINUE_1:	lea		DI, MCB_PSP + 21
			mov		AX, ES:[0001h]
			call 	WRD_TO_HEX
			mov		AX, ES:[0003h]
			mov 	CX, 10h
	    	mul 	CX
	    	lea		SI,	MCB_SIZE + 14
			call 	WRD_TO_DEC
			lea		DX, MCB_TYPE
			call 	WRITE_STRING
			lea 	DX, MCB_PSP
			call 	WRITE_STRING
			lea 	DX, MCB_SIZE
			call 	WRITE_STRING
			lea		SI, MCB_TAIL + 4
			jmp		LOOP_TAIL
CONTINUE_2:	lea		DX,	MCB_TAIL
			call 	WRITE_STRING
			cmp		BX, 0
			jz		END_MCB
			xor 	AX, AX
	    	mov 	AX, ES
	    	add 	AX, ES:[0003h]
	    	inc 	AX
	    	mov 	ES, AX
			jmp 	WHILE_MCB
END_MCB:	pop		DX
			pop		CX
			pop		BX
			pop		AX
			ret
DEF_BX:		mov		BX,0
			jmp 	CONTINUE_1
LOOP_TAIL:	push 	SI
			push 	CX
			push 	BX
			push 	AX
			mov		BX, 0008h
			mov		CX, 4
WHILE_T:	mov		AX, ES:[bx]
			mov		[SI], AX
			add 	BX, 2h
			add		SI, 2h
			loop 	WHILE_T
			pop		AX
	    	pop		BX
	    	pop		CX
			pop		SI
			jmp		CONTINUE_2
DEF_MCB			ENDP
;--------------------------
; Ø¨û åí á¨óçÐíå åÖë · ëñµÖ¦ ë DOS
BEGIN:		call	DEF_MEMORY_AVL
        	call	DEF_MEMORY_EXT
			call	DEF_MCB
			mov		AH, 4Ch
			int		21h
			ret
EXIT: 	
MCB_4			ENDS
END 	START










