TESTPC	SEGMENT
		ASSUME	CS:TESTPC,	DS:TESTPC,	ES:NOTHING,	SS:NOTHING
		ORG		100H
START:	JMP		BEGIN
; ДАННЫЕ
TypePC			db		'Type of PC:  ', 0dh, 0ah, '$'
SystemVersion 	db		'Version of System:  .  ', 0dh, 0ah, '$'
NumberOEM		db		'Serial number of OEM:   ', 0dh, 0ah, '$'
UserNumber		db		'Serial number of user:       ', 0dh, 0ah, '$'
; ПРОЦЕДУРЫ
;-----------------------------------------------------------
Print_message	PROC	near
		mov		ah,09h
		int		21h
		ret
Print_message	ENDP
TETR_TO_HEX		PROC	near
		and		al,0fh
		cmp		al,09
		jbe		NEXT
		add		al,07
NEXT:	add		al,30h
		ret
TETR_TO_HEX		ENDP
;---------------------------
BYTE_TO_HEX		PROC near
; байт в AL переводится в два символа шестн. числа в AX
		push	cx
		mov		al,ah
		call	TETR_TO_HEX
		xchg	al,ah
		mov		cl,4
		shr		al,cl
		call	TETR_TO_HEX ; в AL старшая цифра
		pop		cx 			; в AH младшая
		ret
BYTE_TO_HEX		ENDP
;--------------------------
WRD_TO_HEX		PROC	near
; первод в 16 с/с 16-ти разрядного числа
; в AX - число, DI - адрес последнего символа
		push	bx
		mov		bh,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		dec		di
		mov		al,bh
		xor		ah,ah
		call	BYTE_TO_HEX
		mov		[di],ah
		dec		di
		mov		[di],al
		pop		bx
		ret
WRD_TO_HEX		ENDP
;----------------------------
BYTE_TO_DEC		PROC	near
; перевод в 10 с/с, SI - адрес поля младшей цифры
		push	cx
		push	dx
		push	ax
		xor		ah,ah
		xor		dx,dx
		mov		cx,10
loop_bd:div		cx
		or 		dl,30h
		mov 	[si],dl
		dec 	si
		xor		dx,dx
		cmp		ax,10
		jae		loop_bd
		cmp		ax,00h
		je		end_l
		or		al,30h
		mov		[si],al
end_l:	pop		ax
		pop		dx
		pop		cx
		ret
BYTE_TO_DEC		ENDP
;---------------------------
; код
PC_TYPE 		PROC	near
		push 	es
		push	bx
		push	ax
		mov		bx,0f000h
		mov 	es,bx
		mov 	ax,es:[0fffeh]
		mov		ah,al
		call 	BYTE_TO_HEX
		lea		bx,TypePC
		mov		[bx+12],ax
		pop		ax
		pop		bx
		pop		es
		ret
PC_TYPE			ENDP
;---------------------------
SYSTEM_VERSION	PROC	near
		push	ax
		push 	si
		lea		si,SystemVersion
		add		si,19
		call	BYTE_TO_DEC
		add		si,3
		mov 	al,ah
		call	BYTE_TO_DEC
		pop 	si
		pop 	ax
		ret
SYSTEM_VERSION 	ENDP
;---------------------------
NUMBER_OEM		PROC	near
		push	ax
		push	bx
		push	si
		mov 	al,bh
		lea		si,NumberOEM
		add		si,24
		call	BYTE_TO_DEC
		pop		si
		pop		bx
		pop		ax
		ret
NUMBER_OEM		ENDP
;---------------------------
USER_NUMBER		PROC	near
		push	ax
		push	bx
		push	cx
		push	si
		mov		al,bl
		call	BYTE_TO_HEX
		lea		di,UserNumber
		add		di,23
		mov		[di],ax
		mov		ax,cx
		lea		di,UserNumber
		add		di,28
		call	WRD_TO_HEX
		pop		si
		pop		cx
		pop		bx
		pop		ax
		ret
USER_NUMBER		ENDP
;---------------------------
BEGIN:
		call 	PC_TYPE
		mov		ah,30h
		int		21h
		call	SYSTEM_VERSION
		call	NUMBER_OEM
		call	USER_NUMBER
		lea		dx,TypePC
		call	Print_message
		lea		dx,SystemVersion 
		call	Print_message
		lea		dx,NumberOEM
		call	Print_message
		lea		dx,UserNumber
		call	Print_message
		xor 	al,al
		mov		ah,4ch
		int		21h
TESTPC	ENDS
		END 	START	;конец модуля, START - точка входа