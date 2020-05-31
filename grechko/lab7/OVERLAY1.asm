OVERLAY1		SEGMENT
   				ASSUME CS:OVERLAY1, DS:NOTHING, SS:NOTHING, ES:NOTHING
				
MAIN_OVL1		PROC	FAR
			push	AX
			push	DX
			push	DS
			push	DI
			
			mov		DX, CS
			mov		DS,	AX
			
			lea		DX, FILE_INFO
			call	WRITE_STRING
			
			lea		DI, ADDRESS
			add		DI, 13
			mov		AX, CX
			call	WRD_TO_HEX
			
			lea		DX,	ADDRESS
			call	WRITE_STRING
			
			pop		DI
			pop		DS
			pop		DX
			pop		AX
				retf
MAIN_OVL1		ENDP
;-----------------------------------------------------------
FILE_INFO	DB	'OVERLAY #1 IS LOAD', 0Dh, 0Ah, '$'
ADDRESS 	DB	'ADDRESS :     ', 0Dh, 0Ah, '$'
;-----------------------------------------------------------
WRITE_STRING	PROC	NEAR
			push 	AX

			mov 	AH, 09h
			int 	21h

			pop 	AX
				ret
WRITE_STRING	ENDP
;-----------------------------------------------------------
TETR_TO_HEX		PROC	NEAR
			and		AL, 0Fh
			cmp		AL,	09
			jbe		next_
			add		AL, 07
next_:		add		AL, 30h
				ret
TETR_TO_HEX		ENDP
;-----------------------------------------------------------
BYTE_TO_HEX		PROC 	NEAR
			push	CX
			mov		AH, AL
			call	TETR_TO_HEX
			xchg	AL, AH
			mov		CL, 4
			shr		AL, CL
			call	TETR_TO_HEX
			pop		CX
				ret
BYTE_TO_HEX		ENDP
;-----------------------------------------------------------
WRD_TO_HEX		PROC	NEAR
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
;-----------------------------------------------------------
OVERLAY1		ENDS
END				MAIN_OVL1