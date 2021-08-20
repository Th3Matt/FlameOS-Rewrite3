	            ;			Raw Descriptor	Descriptor+RPL  Description
		            ;---------------------00       -      00         -   NULL
    mov edi, GDTLoc
    mov dword [di], 0
    add di, 4
    mov dword [di], 0
    add di, 4
                    ;---------------------08 	   -      08         -   Kernel Stack
		            ;500 - 1fff
    mov ax, 0x1fff
    mov [di], ax

    add di, 2

    mov ax, 0x500
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    mov [di], ecx

    add di, 4
                    ;---------------------10       -      10         -   System Variables
                    ;2000 - 2fff
    mov ax, 0x2fff
    mov [di], ax

    add di, 2

    mov ax, 0x2000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    mov [di], ecx

    add di, 4
                    ;---------------------18       -      18         -   BIOS Memory Map
                    ;3000 - 3fff
    mov ax, 0x3fff
    mov [di], ax

    add di, 2

    mov ax, 0x3000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    mov [di], ecx

    add di, 4
                    ;---------------------20       -      20         -   IDT (64 entries)
                    ;5000 - 5fff
    mov ax, 0x5fff
    mov [di], ax

    add di, 2

    mov ax, 0x5000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010000b
    shl ecx, 8
    mov ch, 10010010b
    mov [di], ecx

    add di, 4
                    ;---------------------28       -      28         -   Kernel Code
                    ;20000 - 20fff
    mov ax, 0xfff
    mov [di], ax

    add di, 2

    xor ax, ax
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01010010b
    shl ecx, 8
    mov ch, 10011010b
    mov cl, 2
    mov [di], ecx

    add di, 4
                    ;---------------------30       -      30         -   Video RAM (TextMode)
                    ;b8000 - b8fff
    mov ax, 0x8fff
    mov [di], ax

    add di, 2

    mov ax, 0x8000
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov ch, 01011011b
    shl ecx, 8
    mov ch, 10010010b
    mov cl, 0xB
    mov [di], ecx

    add di, 4
                    ;---------------------38       -      38         -   Video RAM
                    ;a0000 - e6500 or PCI device 1234:1111 BAR0
    mov eax, [GraphicsFramebufferAddress]
    shr eax, 12
    add ax, (720*400*4)>>12
    mov [di], ax

    add di, 2

    mov ax, [GraphicsFramebufferAddress]
    mov [di], ax

    add di, 2

    xor ecx, ecx
    mov cl, [GraphicsFramebufferAddress+3]
    shr cl, 4
    and cl, 00001111b
    or cl, 11000000b
    mov ch, [GraphicsFramebufferAddress+3]

    shl ecx, 16
    mov ch, 10010010b
    mov cl, [GraphicsFramebufferAddress+2]
    mov [di], ecx

    add di, 4       ;=====================

    mov si, di
    sub si, GDTLoc
    dec si
    mov [di], si
    mov eax, edi
    add di, 2
    mov dword [di], GDTLoc

    xchg bx, bx

    lgdt [eax]

    mov eax, cr0
    or al, 1       ; set PE (Protection Enable) bit in CR0 (Control Register 0)
    mov cr0, eax

    jmp 0x28:KernelInit32

    SetGDT:
