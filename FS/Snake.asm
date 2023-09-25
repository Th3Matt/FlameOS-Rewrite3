[ BITS 32 ]
[ ORG 0x0 ]


INFO:
	.Entrypoint: 	dd Snake
	.Flags:         dd 00000000000000000000000000000001b

times 512-($-$$) db 0

Vars.X equ 0
Vars.Y equ 1
Vars.lastClockRecord equ 2
Vars.direction equ 6
Vars.directionListWritePtr equ 7
Vars.directionListReadPtr equ 9
Vars.snakeLength equ 11
Vars.TailX equ 13
Vars.TailY equ 14
Vars.directionList equ 15

StartX equ 24
StartY equ 25
StartSize equ 3

Snake:
	push cs
	pop ds

	mov ebx, 0x31
	mov esi, File

	int 0x30

	cmp eax, 0
	jnz .error1

	mov es, si

	mov ecx, 1
    mov ebx, 0x30
    int 0x30
    mov fs, si

    .mainMenu.refresh:

	push es
	mov bx, gs
	mov es, bx

	mov ecx, 800*600
	xor eax, eax
	not eax
	xor edi, edi
	rep stosd

	pop es

	xor eax, eax
	mov ecx, eax
	mov edi, (800*4/2)+(800*(600-5*2)*4/2)-(5*2*(Str.end-Str)*4/2)
	not eax
	mov esi, Str+1
	xor edx, edx
	mov dl, ds:[esi-1]
	mov ebx, 6

	int 0x30 ; Print line 1

	mov edi, (800*4/2)+(800*4*(600-5*2)/2)+(800*4*5*2)-(5*2*(Str2.end-Str2)*4/2)
	mov esi, Str2+1
	xor edx, edx
	mov dl, ds:[esi-1]

	int 0x30 ; Print line 2
	mov edi, (800*4/2)+(800*4*(600-5*2)/2)+(800*4*5*2*2)-(5*2*(Str3.end-Str3)*4/2)
	mov esi, Str3+1
	xor edx, edx
	mov dl, ds:[esi-1]

	int 0x30 ; Print line 2

	.mainMenu:
        mov ebx, 0x20
        int 0x30

        mov ebx, 0x10
        int 0x30
        cmp eax, 0x0
        jz .mainMenu

        cmp eax, 0x15 ; Q
        jz .quit

        cmp eax, 0x29 ; Space
        jz .start

        jmp .mainMenu

    .mainMenu.fromGame:
        mov ebx, 0x20
        int 0x30

		mov ebx, 0x10
        int 0x30
        cmp eax, 0x0
        jz .mainMenu.refresh

        jmp .mainMenu.fromGame

    .error1:
		push es
		mov bx, gs
		mov es, bx

		xor edi, edi
		mov ecx, 800*600
		xor eax, eax
		rep stosd

		push es

		xor eax, eax
		mov ecx, eax
		xor edi, edi
		not eax
		mov esi, ErrorStr+1
		xor edx, edx
		mov dl, ds:[esi-1]
		mov ebx, 6

		int 0x30

		.error1.wait:
			mov ebx, 0x20
			int 0x30

			mov ebx, 0x20
			int 0x30

			mov ebx, 0x10
			int 0x30
			cmp eax, 0x0
			jz .error1.wait

			cmp eax, 0x15 ; Q
			jz .quit

			jmp .error1.wait
		xor edi, edi

	.quit:
        mov ebx, 0x22
        int 0x30

	.start:
		push es
		mov bx, gs
		mov es, bx

		xor edi, edi
		mov ecx, 800*600
		xor eax, eax
		rep stosd

		pop es

		mov byte fs:[Vars.X], StartX
		mov byte fs:[Vars.Y], StartY

		mov byte fs:[Vars.TailX], StartX
		mov byte fs:[Vars.TailY], StartY

		xor ebx, ebx
		mov word fs:[Vars.directionListWritePtr], bx
		mov word fs:[Vars.directionListReadPtr], bx

		mov word fs:[Vars.snakeLength], StartSize

		mov ebx, 0x40
		int 0x30

		add eax, 4
		mov fs:[Vars.lastClockRecord], eax

	.loop:
		movzx esi, byte fs:[Vars.direction]

		mov edx, 0x00FFFFFF
		xor ebx, ebx

		movzx di, byte fs:[Vars.Y]
		shl edi, 16
		movzx di, byte fs:[Vars.X]

		call DrawInTiles

		.loop.short:

        mov ebx, 0x20
        int 0x30

		mov ebx, 0x40
		int 0x30

		mov ebx, fs:[Vars.lastClockRecord]

		cmp eax, ebx
		jz .loop.short

		add eax, 4
		mov fs:[Vars.lastClockRecord], eax

		xor eax, eax
		mov al, fs:[Vars.direction]

		test al, 00000010b
		jnz .loop.coordAdd

		.loop.coordSub:

		test al, 00000001b
		jnz .loop.coordSub.X
		.loop.coordSub.Y:
			cmp byte fs:[Vars.Y], 0
			jle .loop.coord.done
			dec byte fs:[Vars.Y]
			jmp .loop.coord.done

		.loop.coordSub.X:
			cmp byte fs:[Vars.X], 0
			jle .loop.coord.done
			dec byte fs:[Vars.X]
			jmp .loop.coord.done

		.loop.coordAdd:

		test al, 00000001b
		jnz .loop.coordAdd.X
		.loop.coordAdd.Y:
			cmp byte fs:[Vars.Y], 36
			jge .loop.coord.done
			inc byte fs:[Vars.Y]
			jmp .loop.coord.done

		.loop.coordAdd.X:
			cmp byte fs:[Vars.X], 49
			jge .loop.coord.done
			inc byte fs:[Vars.X]
			jmp .loop.coord.done

		.loop.coord.done:

		mov si, fs:[Vars.directionListWritePtr]
		dec si
		mov dl, fs:[si+Vars.directionList]

		shl dl, 2

		add al, dl

		movzx si, ds:[eax+TurnTable]

		mov edx, 0x00FFFFFF
		xor ebx, ebx

		call DrawInTiles

		mov esi, 6

		mov edx, 0x00FFFFFF
		xor ebx, ebx

		movzx di, byte fs:[Vars.TailY]
		shl edi, 16
		movzx di, byte fs:[Vars.TailX]

		call DrawInTiles

		mov si, fs:[Vars.directionListReadPtr]
		push di
		mov di, fs:[Vars.directionListWritePtr]
		sub di, si
		cmp di, fs:[Vars.snakeLength]
		pop di
		jl .loop.tail.coord.done
		xor eax, eax
		mov al, fs:[si+Vars.directionList]
		inc word fs:[Vars.directionListReadPtr]

		test al, 00000010b
		jnz .loop.tail.coordAdd

		.loop.tail.coordSub:

		test al, 00000001b
		jnz .loop.tail.coordSub.X
		.loop.tail.coordSub.Y:
			cmp byte fs:[Vars.TailY], 0
			jle .loop.tail.coord.done
			dec byte fs:[Vars.TailY]
			jmp .loop.tail.coord.done

		.loop.tail.coordSub.X:
			cmp byte fs:[Vars.TailX], 0
			jle .loop.tail.coord.done
			dec byte fs:[Vars.TailX]
			jmp .loop.tail.coord.done

		.loop.tail.coordAdd:

		test al, 00000001b
		jnz .loop.tail.coordAdd.X
		.loop.tail.coordAdd.Y:
			cmp byte fs:[Vars.TailY], 36
			jge .loop.tail.coord.done
			inc byte fs:[Vars.TailY]
			jmp .loop.tail.coord.done

		.loop.tail.coordAdd.X:
			cmp byte fs:[Vars.TailX], 49
			jge .loop.tail.coord.done
			inc byte fs:[Vars.TailX]
			jmp .loop.tail.coord.done

		.loop.tail.coord.done:

		inc si
		movzx si, byte fs:[si+Vars.directionList]
		add esi, 12

		mov edx, 0x00FFFFFF
		xor ebx, ebx

		movzx di, byte fs:[Vars.TailY]
		shl edi, 16
		movzx di, byte fs:[Vars.TailX]

		call DrawInTiles

		mov al, fs:[Vars.direction]

		mov si, fs:[Vars.directionListWritePtr]
		mov fs:[si+Vars.directionList], al

		cmp si, 0x73B
		jge .loop.ptr.overflow

		inc word fs:[Vars.directionListWritePtr]
		jmp .loop.move

		 .loop.ptr.overflow:
			mov word fs:[Vars.directionListWritePtr], 0

		.loop.move:

		mov ebx, 0x10
		int 0x30
		cmp eax, 0x0
		jz .loop

		cmp eax, 0x15 ; Q
		jz .mainMenu.fromGame

		cmp eax, 0x1D ; W
		jnz .loop.move.notUp

		mov fs:[Vars.direction], byte 0
		jmp .loop.move.done

		.loop.move.notUp:

		cmp eax, 0x1C ; A
		jnz .loop.move.notLeft

		mov fs:[Vars.direction], byte 1
		jmp .loop.move.done

		.loop.move.notLeft:

		cmp eax, 0x1B ; S
		jnz .loop.move.notDown

		mov fs:[Vars.direction], byte 2
		jmp .loop.move.done

		.loop.move.notDown:

		cmp eax, 0x23 ; D
		jnz .loop.move.done

		mov fs:[Vars.direction], byte 3
		jmp .loop.move.done
		.loop.move.done:

		jmp .loop


TurnTable:
	.a:
		.aa:
			db 4
		.ab:
			db 10
		.ac:
			db 4
		.ad:
			db 11
	.b:
		.ba:
			db 9
		.bb:
			db 5
		.bc:
			db 11
		.bd:
			db 5
	.c:
		.ca:
			db 4
		.cb:
			db 8
		.cc:
			db 4
		.cd:
			db 9
	.d:
		.da:
			db 8
		.db:
			db 5
		.dc:
			db 10
		.dd:
			db 5

DrawInTiles:; es:esi - sprite, di - x, edi>>16 - y, edx - foreground color, ebx - background color
	push edi
	push esi
	xor esi, esi
	mov si, di
	shl esi, 3 ; times 8 - tile size
	shr edi, 16

	push eax
	push edx

	mov eax, 800*4*2
	mul edi

	add esi, eax

	pop edx
	pop eax

	mov edi, esi
	pop esi
	shl esi, 3

	call DrawSprite

	pop edi

	ret

DrawSprite: ; es:esi - sprite, gs:edi - screen, edx - foreground color, ebx - background color
	push 8
	push 8

	.loop:
		xor eax, eax
		mov al, [es:esi]
		rol al, 1

		.loop.loop:
			test al, 00000001b
			jz .loop.loop.dont

			push ebx
			mov ebx, edx
			call DrawBlock
			pop ebx

			jmp .loop.loop.done

			.loop.loop.dont:

			call DrawBlock

			.loop.loop.done:

			inc edi
			rol al, 1
			pop ecx
			dec ecx
			push ecx
			jnz .loop.loop

		add edi, (400-4)*2
		inc esi
		pop ecx
		pop ecx
		dec ecx
		push ecx
		push 8
		jnz .loop

	pop ecx
	pop ecx

	ret

DrawBlock:
	push edi
	shl edi, 1+2

	mov gs:[edi], ebx
	mov gs:[edi+4], ebx

	add edi, (800)*4

	mov gs:[edi], ebx
	mov gs:[edi+4], ebx

	pop edi
	ret

Str: db .end-Str-1, "Snake v0.0.1"
	.end:
Str2: db .end-Str2-1, "Press Space to start, q to quit"
	.end:
Str3: db .end-Str3-1, "WASD to move."
	.end:
ErrorStr: db .end-ErrorStr-1, "Error: data file missing."
	.end:

File: db "/SnakeData.dat", 0


times 512*3-($-Snake) db 0
