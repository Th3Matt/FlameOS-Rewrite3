[ BITS 32 ]
[ ORG 0x0 ]


INFO:
	.Entrypoint: 	dd Clock
	.Flags:         dd 00000000000000000000000000000000b
	.Check:         dd "FlOS"

times 512-($-$$) db 0

Clock:
    mov ebx, 0x40
    int 0x30
    mov edx, eax

    mov ebx, 7
    xor eax, eax
    mov ecx, eax
    not eax

    int 0x30

    mov ebx, 0x3
    int 0x30

    mov ebx, 0x22
    int 0x30


times 512*2-($-Clock) db 0
