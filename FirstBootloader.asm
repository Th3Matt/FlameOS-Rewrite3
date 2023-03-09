[ org 0x7C00 ]
[ BITS 16 ]
; The first stage bootloader.

jmp 0:0x7C05

Boot:
    mov di, 0xB800
    mov es, di
    xor di, di

    cli
    mov ss, di
    mov sp, 0x7C00
    sti

    mov cx, 80*50/4
    xor eax, eax

    rep stosd

    xor si, si
    mov ds, si
    mov si, Message1
    xor di, di
    call Print

    mov si, PartitionTable+4
    mov byte ds:[0x7E00+4], 0   ; Making sure to only search the MBR partition table
    mov cx, 0

    .checkPartitions:
        lodsb
        cmp al, 0
        jz .checkPartitions.done
        add si, 15

        test byte ds:[(si-16)-4], 0x80
        jz .checkPartitions

        cmp al, 0xC8
        jnz .checkPartitions.notFlOS

        call PrintListPrefix
        inc cx
        mov si, FlameOSPartition
        call Print
        jmp .checkPartitions

        .checkPartitions.notFlOS:

        call PrintListPrefix
        inc cx
        mov si, UnknownPartition
        call Print
        jmp .checkPartitions

    .checkPartitions.done:

    add cx, 0x30

    .waitForInput:
        mov ah, 1
        int 0x16							; Waiting for input
        jz .waitForInput

        mov ah, 0
        int 0x16

        cmp ah, 0x1C 						; Check selection if Enter button pressed
        je .testSelection

        cmp al, 0x30						; Check if number (lower bound)
        jl .waitForInput

        cmp al, cl 							; Check if number (upper bound)
        jge .waitForInput

        mov ah, 0x0F
        mov [es:((80*23)+(80/2))*2], ax 	; Writing number
        jmp .waitForInput

    .testSelection:
        cmp byte [es:((80*23)+(80/2))*2], 0
        jz .waitForInput

    mov di, [es:((80*23)+(80/2))*2]
    and di, 0x00FF
    sub di, 0x30
    shl di, 4

    xor ax, ax
    int 0x13

    mov si, 0x500
    mov dword ds:[si], 0x00010010
    mov dword ds:[si+4], 0x7E00
    mov eax, ds:[di+8+PartitionTable]
    mov ds:[si+8], eax
    xor eax, eax
    mov dword ds:[si+12], eax
    mov ax, 0x4200

    push dx
    int 0x13
    pop dx

    mov ebx, ds:[di+8+PartitionTable]
    mov ecx, ds:[di+8+PartitionTable]

    jmp 0x7E00

PrintListPrefix:
    push cx

    add cl, '0'

    mov al, cl
    mov ah, 0x0F
    stosw

    mov al, ' '
    stosw

    mov al, '-'
    stosw

    mov al, ' '
    stosw

    pop cx
    ret

Print:
    mov ah, 0x0F

    .loop:
        lodsb
        cmp al, 0
        jz .loop.done
        stosw
        jmp .loop

    .loop.done:
    push cx
    mov cl, 80*2
    mov ax, di
    idiv cl
    pop cx
    shr ax, 8
    sub di, ax
    add di, 80*2

    ret

Message1:
    db "Bootable partitions:", 0
FlameOSPartition:
    db "Flame OS partition", 0
UnknownPartition:
    db "Unknown partition", 0

times 446-($-$$) db 0

PartitionTable:
	.partition0:
		db 0x80 ;Bootable
		db 0x00
		db 0x02
		db 0x00
		db 0xC8 ;I'm pretty sure this partition ID is (mostly) unused
		db 0xFF
		db 0xFF
		db 0xFF
		dd 0x00000001
		dd 0x00000800+1

times 510-($-$$) db 0

dw 0xAA55
