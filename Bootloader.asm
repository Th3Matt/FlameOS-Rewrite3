[ org 0x7E00 ]
[ BITS 16 ]

SVO equ 0x2000 ; System variables offset
MMO equ 0x3000 ; Memory map offset

Boot:
	mov ax, 0
	mov ds, ax
	mov es, ax

	cli
	mov ss, ax
	mov sp, 0x7c00 ; this might corrupt the later stored memory map if the stack becomes too long, but let's hope it doesn't
	sti

	mov ds:[SVO+0x82], ebx
	mov ds:[SVO+0x86], ecx

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
		mov ecx, 0x18
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

		in al, 0x92
		test al, 2
		jz .A20GateCheckNoError
		jmp .A20GateDone

		;mov ax, 0xB800				; Error B - Unable to check A20.
		;mov es, ax
		;xor di, di
		;mov word es:[di], 0xCF42

		;jmp $

		.A20GateCheckNoError:
			cmp al, 0
			jg .A20GateDone

			mov ax, 0x2401
			int 0x15

			jnc .A20GateDone

			in al, 0x92
			or al, 2
			and al, 0xFE
			out 0x92, al

			jmp .A20GateDone ; The 'screw this shit, it'll probably work' approach

			mov ecx, 0x100000
			.checkLoop:
				in al, 0x92
				test al, 2
				jnz .A20GateDone
				loop .checkLoop

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
    	    mov dl, ds:[SVO]
        	
        	push ax
    	    mov ah, 0x42
    	    mov si, .diskReadPacket
			xor ecx, ecx
			mov ds:[si+12], ecx
			mov ecx, ds:[SVO+0x82]
			inc ecx
			push ecx
			mov ds:[si+8], ecx

	        int 0x13

	        mov ah, 0x42
			mov dword ds:[si], 0x002A0010
			xor ecx, ecx
			mov	word ds:[si+4], cx
			mov word ds:[si+6], 0x2000
			mov ds:[si+12], ecx
			pop ecx
			add ecx, 5
			mov ds:[si+8], ecx

	        int 0x13

    	    pop cx

        	jc .counter
        	
	        jmp .done
        
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

	jmp 0:0x8000

    
	.C: db 0x0

	.diskReadPacket:
		db 0x10			; Packet size
		db 0			; Reserved
		dw 0x5			; Sectors to read
		dd 0x00008000 	; Buffer
		dq 0			; Starting block number

times 512-($-$$) db 0
