[ BITS 32 ]
[ ORG 0x0 ]


INFO:
	.Entrypoint: 	dd Clock
	.Flags:         dd 00000000000000000000000000000000b

times 512-($-$$) db 0

Clock:
    mov ebx, 0x40
    int 0x30

    push eax

    mov ecx, 1
    mov ebx, 0x30
    int 0x30
    mov ds, si
    push cs
    pop fs

    pop eax

    mov [0], eax

    xor ebx, ebx
    mov esi, 4
    mov ecx, 4

    .loop:
        mov eax, [ecx-1]

        shr al, 4
        and eax, 0fh

        mov al, fs:[eax+HexTable]

        mov [4], al

        mov eax, [ecx-1]

        and eax, 0fh

        mov al, fs:[eax+HexTable]

        mov [5], al

        xor eax, eax
        not eax

        push ecx
        xor ecx, ecx
        mov edi, 2

        int 0x30

        pop ecx

        loop .loop

    mov ebx, 0x3
    int 0x30

    mov ebx, 0x22
    int 0x30

HexTable: db '0123456789ABCDEF'

times 512*2-($-Clock) db 0
