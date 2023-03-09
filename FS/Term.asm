[ BITS 32 ]
[ ORG 0x0 ]


INFO:
	.Entrypoint: 	dd 0x200

times 512-($-$$) db 0

Terminal:
    mov ebx, 1
    int 0x30

    dec ebx
    mov ax, 0x0+4
    mov ds, ax

    xor eax, eax
    not eax

    mov esi, Text+1
    xor ecx, ecx
    mov cl, [esi-1]
    mov edi, ecx

    xor ecx, ecx
    xor edx, edx

    int 0x30

    jmp $

Text: db .end-Text, "This is a program."
    .end:

times 512*3-($-Terminal) db 0
