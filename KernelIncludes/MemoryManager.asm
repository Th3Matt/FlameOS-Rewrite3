 
ALLOCATABLE_SPACE_TABLE_SIZE equ 0x7FF8

MemoryManager:
    .init:
        pusha
        push es

        mov ax, 0x78
		mov es, ax

		xor edi, edi

		mov ecx, (0x40000-0x26000)/4
		xor eax, eax

		rep stosd

		mov ax, 0x70
		mov es, ax

		xor edi, edi
		xor eax, eax
		mov ecx, 256*32*32

		rep stosd

		pop es
		popa
		ret

    .createLDTEntry: ; eax - base, ebx - limit, ecx - Process ID, edx - cpu ring, ds - writable segment containing LDT. Output: esi - LDT entry.
        push eax
        push ebx
        push ecx
        push edx

        and dx, 11b
        shl dx, 5
        push edx

        shl ecx, 3+8
        mov esi, ecx
        sub esi, 8

        .createLDTEntry.loop: ; Finding free LDT entry
            add esi, 8
            test byte [ds:esi+5], 10000000b
            jnz .createLDTEntry.loop

        shr ebx, 12

        mov [ds:esi], bx

        add esi, 2
        mov [ds:esi], ax

        add esi, 2

        xor ecx, ecx

        ror eax, 16
        mov ch, ah
        shr ebx, 16
        mov cl, bl
        and cl, 0x0f
        or cl, 11010000b
        shl ecx, 16

        pop edx
        or ch, dl

        or ch, 10010010b
        mov cl, al
        mov [ds:esi], ecx

        and esi, 0xff

        pop edx
        pop ecx
        pop ebx
        pop eax
        ret

    .clearLDT: ; ecx - process ID, ds - writable segment containing LDT.
        push esi

        xor esi, esi

        .clearLDT.loop:
            call .deleteLDTEntry

            add esi, 8
            cmp esi, 0x200*8
            jle .clearLDT.loop

        pop esi
        ret

    .deleteLDTEntry: ; ecx - Process ID, esi - LDT entry, ds - writable segment containing LDT.
        push ecx
        push esi

        shl ecx, 3+8
        and esi, 111111111111111111111111111000b
        add esi, ecx
        and byte [ds:esi+5], 0

        pop esi
        pop ecx
        ret

    .memAlloc:    ; eax - process ID, ecx - requested blocks of 4 KiB. Output: eax - address of allocated space
        push es
        push ecx
        push edi
        push edx
        push ebx

        push eax

        mov ax, 0x78
		mov es, ax

		xor edi, edi
		xor eax, eax
		mov al, 1
        xor edx, edx
		jmp .memAlloc.checkSlot

        .memAlloc.notFree:
            xor edx, edx

		.memAlloc.shiftMask:
            shl eax, 1
            jnz .memAlloc.checkSlot

		.memAlloc.setTo1:
            mov eax, 1              ; reset mask
            add edi, 4
            cmp edi, ALLOCATABLE_SPACE_TABLE_SIZE
            jz .memAlloc.outOfMemory

        .memAlloc.checkSlot:
            test [es:edi], eax        ; check memory slot
            jnz .memAlloc.notFree
            inc edx
            cmp edx, ecx
            jnz .memAlloc.shiftMask

        xor edx, edx

        .memAlloc.setBits:
            or [es:edi], eax
            inc edx
            shr eax, 1
            jnz .memAlloc.setBits.2

            cmp edx, ecx
            jnl .memAlloc.writeAllocation

            mov eax, 80000000h
            sub edi, 4

        .memAlloc.setBits.2:
            cmp edx, ecx
            jl .memAlloc.setBits

		.memAlloc.writeAllocation:
            mov ebx, eax
            pop eax
            push esi
            xor esi, esi

            .memAlloc.writeAllocation.testIfWrite:
                cmp dword [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+8], 0
                jnz .memAlloc.nextAlloc

        shl edi, 5-2 ; encoding

        .memAlloc.getPosMidByte:
            cmp ebx, 0
            jz .memAlloc.getPosMidByte.done

            inc edi
            shr ebx, 1

            jmp .memAlloc.getPosMidByte

        .memAlloc.getPosMidByte.done:

        mov [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE], eax              ; PID
        mov [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+4], edi            ; Allocation location in table
        mov [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+8], ecx            ; Allocated space

        shl edi, 12

        add edi, 0x110000
        mov [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+12], edi           ; Start address of allocation
        pop esi

        mov eax, edi

        .memAlloc.end:

        pop ebx
        pop edx
        pop edi
        pop ecx
        pop es
        ret

        .memAlloc.nextAlloc:
            add esi, 16
            jmp .memAlloc.writeAllocation.testIfWrite

        .memAlloc.outOfMemory:
            mov ax, 0x38
            mov es, ax
            xor edi, edi

            mov ecx, 800*600
            mov eax, 0xff880000
            rep stosd

            mov ecx, 0xff880000
            call Print.fillScreen

            mov si, 0x28
            mov ds, si
            mov eax, 0x00FFFFFF
            mov esi, .outOfMemoryErrorMsg+1
            mov edi, [.outOfMemoryErrorMsg]
            and edi, 0xff

            mov edx, (800/10)*(30/10)+(800/20)
            push edi
            shr edi, 1
            sub edx, edi
            pop edi

            call Print.string

            mov bx, 0xFFFF
            call Print.refresh
            jmp $

    .memFreeAll:  ; eax - process ID ; Note: frees all memory taken by process with PID
        push eax
        push ecx
        push es
        push esi

        mov cx, 0x78
        mov es, cx

        mov ecx, (0x1000-0x200)/16
        xor esi, esi

        .memFreeAll.loop:
            cmp [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE], eax
            jnz .memFreeAll.loop.1

            mov ebx, [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+12]

            call .memFree

            .memFreeAll.loop.1:
                add esi, 16
                loop .memFreeAll.loop

        pop edi
        pop es
        pop ecx
        pop eax
        ret

    .memFree:     ; eax - process ID, ebx - allocation address.
        push es
        push eax
        push esi
        push ecx

        push eax

        mov ax, 0x78
		mov es, ax

        pop eax
        mov esi, [es:ALLOCATABLE_SPACE_TABLE_SIZE]

        .memFree.test:
            cmp [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE], eax
            jnz .memFree.nextAlloc
            cmp [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+12], ebx
            jnz .memFree.nextAlloc

        mov ecx, [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+4]
        mov ebx, [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+8]
        add ecx, ebx

        push cx     ; deencoding
        shr ecx, 5
        shl ecx, 7
        xor eax, eax
        pop ax
        and eax, 11111b
        add ecx, eax

        push ecx

        mov eax, 1
        and cl, 0x1f
        dec ecx
        shl eax, cl

        pop ecx
        shr ecx, 5

        .memFree.clearBits:
            xor [es:ecx], eax
            dec ebx
            cmp ebx, 0
            jz .memFree.clearAllocation

            shr eax, 1
            jnz .memFree.clearBits

            mov eax, 80000000h
            sub ecx, 4
            jmp .memFree.clearBits

        .memFree.clearAllocation:
            mov dword [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE], 0
            mov dword [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+4], 0
            mov dword [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+8], 0
            mov dword [es:esi+ALLOCATABLE_SPACE_TABLE_SIZE+12], 0

        pop ecx
        pop esi
        pop eax
        pop es
        clc

        .memFree.end:
            ret

        .memFree.nextAlloc:
            add esi, 16

            cmp esi, (0x1000-0x200)
            stc
            jz .memFree.end

            jmp .memFree.test

    .memAllocPrint:
        pusha
        push ds

        call Print.clearScreen

        mov ax, 0x28
        mov ds, ax

        xor eax, eax
        not eax
        xor edx, edx
        mov esi, .memTableTop+1
        mov edi, [ds:esi-1]
        shl edi, 24
        shr edi, 24
        xor ecx, ecx

        call Print.string

        push es
        mov cx, 0x78
        mov es, cx

        mov ecx, 18
        mov ebx, ALLOCATABLE_SPACE_TABLE_SIZE

        .memAllocPrint.PrintEntries:
            call .memAllocPrint.drawEntry
            add ebx, 16
            loop .memAllocPrint.PrintEntries

        pop es
        pop ds
        popa
        ret

        .memAllocPrint.drawEntry: ; ebx - entry
            push ecx
            push ebx
            xor ebx, ebx

            mov esi, .memTableEntry+1
            mov edi, 4
            xor ecx, ecx

            call Print.string

            pop ebx
            mov ecx, [es:ebx]
            push ebx
            xor ebx, ebx

            call Print.hex32

            mov edi, 5
            add esi, 4
            xor ecx, ecx

            call Print.string

            pop ebx
            mov ecx, [es:ebx+12]
            push ebx
            xor ebx, ebx

            call Print.hex32

            mov edi, 5
            add esi, 5
            xor ecx, ecx

            call Print.string

            pop ebx

            mov ecx, [es:ebx+8]
            push eax
            push edx
            mov eax, 0x1000
            mul ecx
            mov ecx, eax
            pop edx
            pop eax

            push ebx
            xor ebx, ebx

            call Print.hex32

            mov edi, 3
            add esi, 5
            xor ecx, ecx

            call Print.string

            mov esi, .memTableEnd+1
            mov edi, [ds:esi-1]
            shl edi, 24
            shr edi, 24
            xor ecx, ecx

            call Print.string

            pop ebx
            pop ecx
            ret

    section .rodata

    .memTableTop: db .memTableEntry-.memTableTop-1
        db "|--------------------------------------|", 10
        db "| PID        | StartAddr  | Size       |", 10
        db "|--------------------------------------|", 10

    .memTableEntry: db .memTableEnd-.memTableEntry-1
        db "| 0x", " | 0x", " | 0x", " |", 10

    .memTableEnd: db .memTable.end-.memTableEnd-1
        db "|--------------------------------------|", 10
    .memTable.end:

    .outOfMemoryErrorMsg: db .end-.outOfMemoryErrorMsg-1
        db "OUT OF MEMORY, so that sucks, I guess."
    .end:

    section .text
