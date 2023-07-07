[ BITS 32 ]
[ ORG 0x0 ]


INFO:
	.Entrypoint: 	dd Terminal
	.Flags:         dd 00000000000000000000000000000000b

times 512-($-$$) db 0

Terminal:
    mov ecx, 1
    mov ebx, 0x30
    int 0x30
    mov fs, si

    dec ebx
    mov ax, 0x0+4
    mov ds, ax

    mov ebx, 0x20
    int 0x30

    mov ebx, 0x10
    int 0x30

    xor eax, eax
    not eax

    mov esi, StartupText+1
    xor ecx, ecx
    mov cl, [esi-1]
    mov edi, ecx

    xor ebx, ebx
    xor ecx, ecx

    int 0x30

    mov ebx, 0x3
    int 0x30

    .prompt:
        xor eax, eax
        not eax

        mov esi, Prompt+1
        xor ecx, ecx
        mov cl, [esi-1]
        mov edi, ecx

        xor ebx, ebx
        xor ecx, ecx

        int 0x30
        mov edi, 0
        mov byte fs:[3], '/'

    .loop:
        mov ebx, 0x20
        int 0x30

        mov ebx, 0x10
        int 0x30
        cmp eax, 0x0
        jz .loop

        cmp eax, 0xF0
        je .release

        test byte fs:[0], 00000001b
        jz .loop.skipAdd

        add eax, 0xFF ; lookup in the second table

        .loop.skipAdd:
        mov eax, [eax+ScancodeDecoder]
        and eax, 0xff

        cmp eax, 0x1A
        je .shift

        cmp eax, 0x8
        je .deleteChar

        cmp eax, 0x4
        je .enter

        cmp eax, 0
        jz .loop

        xor esi, esi
        mov si, fs:[1]
        inc word fs:[1]
        mov fs:[esi+4], al

        mov esi, eax
        mov eax, 0x00FFFFFF
        mov ebx, 0x2
        xor ecx, ecx

        int 0x30

        inc edx
        inc edi

        jmp .loop

    .shift:
        or byte fs:[0], 00000001b

        jmp .loop

    .release:
        mov ebx, 0x20
        int 0x30

        mov ebx, 0x10
        int 0x30

        mov eax, [eax+ScancodeDecoder]
        and eax, 0xff

        cmp eax, 0x1A
        je .unshift

        jmp .loop

    .unshift:
        and byte fs:[0], 11111110b

        jmp .loop

    .deleteChar:
        cmp edi, 0
        jz .loop
        dec edi
        mov ebx, 4
        mov eax, 1
        int 0x30

        xor esi, esi
        dec word fs:[1]
        mov si, fs:[1]
        mov byte fs:[esi+4], 0

        xor esi, esi
        mov eax, 0x00FFFFFF
        mov ebx, 0x2
        xor ecx, ecx

        int 0x30

        mov ebx, 4
        mov eax, 1
        int 0x30

        jmp .loop

    .enter:
        mov ebx, 0x3
        int 0x30

        push ds
        mov si, fs
        mov ds, si

        mov esi, 3
        cmp word ds:[1], 0
        jz .enter.cleanup

        inc esi
        call .checkCommands
        jz .enter.cleanup
        dec esi

        mov ebx, 0x21
        int 0x30 ; attempt to run program

        cmp eax, 0 ; check if error occurred
        jz .enter.cleanup

        pop ds
        xor eax, eax
        not eax

        mov esi, FileNotFound+1
        xor ecx, ecx
        mov cl, [esi-1]
        mov edi, ecx

        xor ebx, ebx
        xor ecx, ecx

        int 0x30 ; print file not found

        mov ebx, 0x3
        int 0x30

        push ds
        mov si, fs
        mov ds, si

        .enter.cleanup:
            xor edi, edi
            inc edi
            mov ecx, 0xffe
            xor eax, eax

            push es
            push fs
            pop es

            rep stosb

            pop es

        pop ds

        jmp .prompt

    .checkCommands:
        push es
        push cs
        pop es
        mov edi, ExitCommand

        call CompareString
        jnz .checkCommands.1

        mov ebx, 0x22
        int 0x30

        .checkCommands.1:

        .checkCommands.end:
        pop es
        ret

    jmp $

CompareString: ; ds:esi - string 1 address, es:edi - string 2 address. Output: ZF set if equal.
    push eax
    push esi
    push edi

    .loop:
        lodsb
        cmp al, 0
        jz .zero

        cmp al, es:[edi]
        jne .notEqual

        inc edi
        jmp .loop

    .zero:
        cmp al, es:[edi]

    .notEqual:
        pop edi
        pop esi
        pop eax

        ret

StartupText: db .end-StartupText-1, "FlameShell v1.0 started."
    .end:

Prompt: db .end-Prompt-1, "FlameShell | "
    .end:

FileNotFound: db .end-FileNotFound-1, "FlameShell: File not found."
    .end:

ExitCommand: db "exit", 0

ScancodeDecoder:
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db "~"
    db 0, 0, 0, 0x1A, 0, 0
    db "q1"
    db 0, 0, 0
    db "zsaw2"
    db 0, 0
    db "cxde43"
    db 0, 0
    db " vftr5"
    db 0, 0
    db "nbhgy6"
    db 0, 0, 0
    db "mju78"
    db 0, 0
    db ",kio09"
    db 0, 0
    db "./l;p-"
    db 0, 0, 0
    db '"'
    db 0
    db "[="
    db 0, 0, 0, 0, 4
    db "]\"
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0
    db "1"
    db 0
    db "47"
    db 0, 0, 0
    db "0.2568"
    db 0
    db "/"
    db 0, 4
    db "3"
    db 0
    db "+9*"
    db 0, 0, 0, 0, 0
    db "-"

    times 0xFF-($-ScancodeDecoder) db 0

ScancodeDecoder2:
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    db "~"
    db 0, 0, 0, 0x1A, 0, 0
    db "Q1"
    db 0, 0, 0
    db "ZSAW2"
    db 0, 0
    db "CXDE43"
    db 0, 0
    db " VFTR5"
    db 0, 0
    db "NBHGY6"
    db 0, 0, 0
    db "MJU78"
    db 0, 0
    db ",KIO09"
    db 0, 0
    db "./L;P-"
    db 0, 0, 0
    db '"'
    db 0
    db "[="
    db 0, 0, 0, 0, 4
    db "]\"
    db 0, 0, 0, 0, 0, 0, 0, 0, 0, 8, 0, 0
    db "1"
    db 0
    db "47"
    db 0, 0, 0
    db "0.2568"
    db 0
    db "/"
    db 0, 4
    db "3"
    db 0
    db "+9*"
    db 0, 0, 0, 0, 0
    db "-"

    times 0xFF-($-ScancodeDecoder2) db 0

times 512*3-($-Terminal) db 0
