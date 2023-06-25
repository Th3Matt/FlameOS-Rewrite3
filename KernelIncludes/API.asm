API:
    .quickLoad: ; ds:esi - path to executable.
        push edx
        xor eax, eax
        mov edx, 0x3

        call ProgramLoader.load
        jc .quickLoad.error

        cli

        call ProgramLoader.exec

        mov eax, ecx
        call ProcessManager.getCurrentPID

        call ProcessManager.pauseProcess

        sti
        push es
        mov ax, 0x40
        mov es, ax
        shl ecx, 4

        .quickLoad.wait: ; waiting for another process to take over
        hlt

        test byte [es:ecx+0x20+0x4], 1 ; check if we're unpaused
        jnz .quickLoad.wait

        pop es

        xor eax, eax
        pop edx
        ret

        .quickLoad.error:
            mov eax, ebx

            pop edx
            ret

    .processExit:
        pusha

        call ProcessManager.getCurrentPID
        cli
        call ProcessManager.stopProcess

        mov ax, 0x40
        mov es, ax

        and byte es:[0x10], 0xFE

        sti
        hlt
        jmp $-1

    .usermodeAllocate: ; ecx - requested blocks of 4 KiB
        push eax
        push ebx
        push ecx
        push edx
        push edi

        push ecx
        call ProcessManager.getCurrentPID
        mov eax, ecx
        pop ecx
        call MemoryManager.memAlloc
        push eax

        mov eax, 0x1000
        mul ecx

        mov ebx, eax
        dec ebx
        pop eax

        mov edx, 3

        push ds
        mov si, 0x70
        mov ds, si

        call ProcessManager.getCurrentPID

        call MemoryManager.createLDTEntry

        or esi, 111b

        mov es, si
        xor edi, edi
        xor eax, eax
        mov ecx, ebx

        rep stosb

        pop ds
        pop edi
        pop edx
        pop ecx
        pop ebx
        pop eax

        ret
