[ org 0x7C00 ]
[ BITS 16 ]

SVO equ 0x2000 ; System variables offset
MMO equ 0x3000 ; Memory map offset

jmp 0:0x7C05

Boot:
	mov ax, 0
	mov ds, ax
	mov es, ax
	
	cli
	mov ss, ax
	mov sp, 0x2000
	sti

	mov ds:[SVO], dl
	mov ah, 0x48
	mov si, 0x500
	mov word ds:[si], 42h
	mov word ds:[si+0x1E], 0

	int 0x13

	jnc .diskInfoCheckDone

	mov ax, 0xB800
	mov es, ax
	xor di, di
	mov word es:[di], (0xCF<<8)+"0"	; Error 0 - Unable to get boot disk info.

	jmp $

	.diskInfoCheckDone:

	;jmp .A20

	mov di, MMO+3

	.getMemoryMap:
		xor ebx, ebx
		mov eax, 0xE820
		mov edx, 'PAMS'
		mov ecx, 0x10
		mov word es:[di+20], 1

		int 0x15

		jnc .getMemoryMap.MMTest

		.getMemoryMap.error:
			mov ax, 0xB800
			mov es, ax
			xor di, di
			mov word es:[di], 0xCF41	; Error A - Unable to get memory map.

			jmp $

		.getMemoryMap.MMTest:
			mov es:[di-3], cl

		.getMemoryMap.MMTest.1:

			add di, cx
			mov word es:[di+20], 1

			cmp eax, 'PAMS'
			jne .getMemoryMap.error

			mov edx, eax
			mov eax, 0xE820

			int 0x15
			jc .getMemoryMap.MMDone

			cmp ebx, 0
			jz .getMemoryMap.MMDone
			jmp .getMemoryMap.MMTest.1

		.getMemoryMap.MMDone:
			mov es:[di-2], di
	.A20:
		mov ax, 0x2402
		int 0x15

		jnc .A20GateCheckNoError

		mov ax, 0xB800				; Error B - Unable to check A20.
		mov es, ax
		xor di, di
		mov word es:[di], 0xCF42

		jmp $

		.A20GateCheckNoError:
			cmp al, 0
			jg .A20GateDone

			mov ax, 0x2401
			int 0x15

			jnc .A20GateDone

			mov ax, 0xB800			; Error C - Unable to enable A20.
			mov es, ax
			xor di, di
			mov word es:[di], 0xCF43

			jmp $

		.A20GateDone:
	.diskLoad:
    	.reset:
    	    xor ax, ax
        
        	int 0x13
        
    	.load:
	        mov cx, 0x02
    	    mov dh, 0
    	    mov dl, ds:[SVO]
        	
        	mov al, 48
        	push ax
    	    mov ah, 0x02
    	    mov bx, 0x2000
    	    mov es, bx
    	    xor bx, bx

	        int 0x13
    	    pop cx

        	jc .counter
        	
	        cmp al, cl
	        je .done
        
	    .counter:
	        cmp byte [.C], 3
	        jge .err
	        add byte [.C], 1
	        jmp .reset
    
	    .err:
	        mov ax, 0xB800			; Error D - Drive read timeout.
			mov es, ax
			xor di, di
			mov word es:[di], 0xCF44

			jmp $

		.done:

	jmp 0x2000:0

    
	.C: db 0x0
times 446-($-$$) db 0

PartitionTable:
	.partition1:
		db 0x80 ;Bootable
		db 0xFF ;Filler values, I don't care enough to populate those fields
		db 0xFF
		db 0xFF
		db 0xC8 ;I'm pretty sure this partition ID is (mostly) unused
		db 0xFF
		db 0xFF
		db 0xFF
		dd 0x00000001
		dd 0x00000800+1

times 510-($-$$) db 0

dw 0xAA55
