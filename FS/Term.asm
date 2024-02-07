[ BITS 32 ]
[ ORG 0x0 ]


INFO:
	.Entrypoint: 	dd Terminal
	.Flags:         dd 00000000000000000000000000000000b

times 512-($-$$) db 0

Vars.flags equ 0
Vars.historyLength equ 1
Vars.historyRead equ 2
Vars.textLength equ 3
Vars.text equ 4

MAX_TEXT_LEN equ 50

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

    mov esi, StartupText

    xor ebx, ebx
    xor ecx, ecx

    int 0x30

    mov ebx, 0x3
    int 0x30

    .prompt:
        mov byte fs:[Vars.historyRead], 0

        xor eax, eax
        not eax

        mov esi, Prompt

        xor ebx, ebx
        xor ecx, ecx

        int 0x30
        mov edi, 0
        ;mov byte fs:[Vars.text], '/'

    .loop:
        mov ebx, 0x20
        int 0x30

        mov ebx, 0x10
        int 0x30
        cmp eax, 0x0
        jz .loop

        cmp eax, 0xF0
        je .release

        cmp eax, 0x63
        je .upHistory

        cmp eax, 0x60
        je .downHistory

        test byte fs:[Vars.flags], 00000001b
        jz .loop.skipAdd

        add eax, 0xFF ; lookup in the second table

        .loop.skipAdd:
        mov eax, [eax+ScancodeDecoder]
        and eax, 0xff

        cmp eax, 0x1A
        je .shift

        cmp eax, 0x8
        je .delete

        cmp eax, 0x4
        je .enter

        cmp eax, 0
        jz .loop

        xor esi, esi
        movzx si, byte fs:[Vars.textLength]
        cmp si, MAX_TEXT_LEN
        jge .loop

        inc byte fs:[Vars.textLength]
        mov fs:[esi+Vars.text], al

        mov esi, eax
        mov eax, 0x00FFFFFF
        mov ebx, 0x2
        xor ecx, ecx

        int 0x30

        inc edx
        inc edi

        jmp .loop

    .downHistory:
        cmp byte fs:[Vars.historyRead], 0
        jz .loop

        call .clear

        movzx eax, byte fs:[Vars.historyLength]
        movzx ebx, byte fs:[Vars.historyRead]
        cmp eax, ebx
        jz .downHistory.overflow

        inc byte fs:[Vars.historyRead]

        jmp .downHistory.done

        .downHistory.overflow:

        mov byte fs:[Vars.historyRead], 0

        .downHistory.done:

        call .drawSelected

        push esi
        call .getCurrentTextField
        movzx edi, byte fs:[esi+Vars.textLength]
        pop esi

        jmp .loop

    .upHistory:
        cmp byte fs:[Vars.historyLength], 0
        jz .loop

        cmp byte fs:[Vars.historyRead], 1
        je .loop
        call .clear

        cmp byte fs:[Vars.historyRead], 0
        jnz .upHistory.not_underflow

        mov bl, byte fs:[Vars.historyLength]
        mov byte fs:[Vars.historyRead], bl

        jmp .upHistory.draw

        .upHistory.not_underflow:
        dec byte fs:[Vars.historyRead]

        .upHistory.draw:

        call .drawSelected

        push esi
        call .getCurrentTextField
        movzx edi, byte fs:[esi+Vars.textLength]
        pop esi

        jmp .loop

    .drawSelected:
        call .getCurrentTextField

        add esi, Vars.textLength
        movzx ecx, byte fs:[esi]
        xor eax, eax

        cmp ecx, 0
        jnz .drawSelected.loop

        ret

        .drawSelected.loop:
            inc eax
            pusha

            movzx esi, byte fs:[esi+eax]
            mov eax, 0x00FFFFFF
            mov ebx, 0x2
            xor ecx, ecx

            int 0x30

            popa

            cmp eax, ecx
            jl .drawSelected.loop

        ret

    .clear:
        call .getCurrentTextField

        movzx ecx, byte fs:[esi+Vars.textLength]

        cmp ecx, 0
        jz .clear.loop.done

        .clear.loop:
            call .deleteChar

            loop .clear.loop

        .clear.loop.done:
        ret

    .shift:
        or byte fs:[Vars.flags], 00000001b

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
        and byte fs:[Vars.flags], 11111110b

        jmp .loop

    .delete:
        cmp edi, 0
        jz .loop

        dec edi

        call .getCurrentTextField

        dec byte fs:[esi+Vars.textLength]
        push edi
        movzx edi, byte fs:[esi+Vars.textLength]
        add esi, edi
        pop edi
        mov byte fs:[esi+Vars.text], 0

        call .deleteChar

        jmp .loop

    .deleteChar:
        pusha
        mov ebx, 4
        mov eax, 1
        int 0x30

        xor esi, esi
        mov eax, 0x00FFFFFF
        mov ebx, 0x2
        xor ecx, ecx

        int 0x30

        mov ebx, 4
        mov eax, 1
        int 0x30

        popa

        ret

    .getCurrentTextField:
        push eax
        movzx esi, byte fs:[Vars.historyRead]
        mov eax, MAX_TEXT_LEN+1

        push edx
        mul esi
        pop edx

        mov esi, eax

        pop eax
        ret

    .enter:
        mov ebx, 0x3
        int 0x30

        push ds
        mov si, fs
        mov ds, si

        call .getCurrentTextField
        add esi, Vars.textLength
        cmp byte ds:[esi], 0
        jz .enter.cleanup.2
        inc esi

        call .checkCommands
        jz .enter.cleanup

        mov ebx, 0x21
        int 0x30 ; attempt to run program

        cmp eax, 0 ; check if error occurred
        jz .enter.cleanup

        pop ds

        cmp eax, 1
        jne .enter.noPermission

        .enter.noFile:

            xor eax, eax
            not eax

            mov esi, FileNotFound

            xor ebx, ebx
            xor ecx, ecx

            int 0x30 ; print file not found

            jmp .enter.errorPrinted

        .enter.noPermission:

            xor eax, eax
            not eax

            mov esi, PermissionDenied

            xor ebx, ebx
            xor ecx, ecx

            int 0x30 ; print permision denied

        .enter.errorPrinted:

            push ds
            mov si, fs
            mov ds, si

        .enter.cleanup:
            push es
            mov si, fs
            mov es, si

            inc byte fs:[Vars.historyLength]
            movzx edi, byte fs:[Vars.historyLength]
            mov eax, MAX_TEXT_LEN+1

            push edx
            mul edi
            pop edx
            mov edi, eax
            add edi, Vars.textLength

            call .getCurrentTextField
            add esi, Vars.textLength
            movzx ecx, byte fs:[esi]
            inc ecx

            rep movsb

            pop es

            .enter.cleanup.2:

            mov edi, Vars.textLength
            mov ecx, MAX_TEXT_LEN+1
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

StartupText: db .end-StartupText-1, "FlameShell v1.1 started."
    .end:

Prompt: db .end-Prompt-1, "FlameShell | "
    .end:

FileNotFound: db .end-FileNotFound-1, "FlameShell: File not found.", 10
    .end:

PermissionDenied: db .end-PermissionDenied-1, "FlameShell: Permission denied.", 10
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
