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
	mov di, MMO

	push dword 0

	.getMemoryMap:
		mov eax, 0xE820
		mov edx, 'SMAP'
		xor ebx, ebx
		mov ecx, 0x100

		;int 0x15

		jnc .MMTest

		mov ax, 0xB800
		mov es, ax
		xor di, di
		mov byte es:[di], 0x41	; Error A - Unable to get memory map.
		mov byte es:[di+1], ah

		jmp $

		.MMTest:
			pop eax
			add eax, ecx
			cmp ebx, 0
			jz .MMDone
			mov di, bx
			jmp .getMemoryMap

		.MMDone:
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
        	
        	mov al, 40
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

times 510-($-$$) db 0

dw 0xAA55