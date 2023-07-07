[ BITS 32 ]
[ ORG 0x0 ]


INFO:
	.Entrypoint: 	dd Snake
	.Flags:         dd 00000000000000000000000000000001b

times 512-($-$$) db 0

Snake:
	push cs
	pop ds

	mov ebx, 0x31
	mov esi, File

	int 0x30

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

	.mainMenu:
        mov ebx, 0x20
        int 0x30

        mov ebx, 0x10
        int 0x30
        cmp eax, 0x0
        jz .mainMenu

        cmp eax, 0x15 ; Q
        jz .quit

        jmp .mainMenu

    jmp $

	.quit:
        mov ebx, 0x22
        int 0x30


Str: db .end-Str-1, "Snake v0.0.1"
	.end:
Str2: db .end-Str2-1, "Press q to quit"
	.end:

File: db "/Terminal.ub", 0


times 512*3-($-$$) db 0
