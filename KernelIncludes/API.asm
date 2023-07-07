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
        xor ebx, ebx
        mov ds, bx
        call ProcessManager.stopProcess

        call Print.delFramebuffer

        mov ax, 0x40
        mov es, ax

        and dword es:[PMDB.flags], 0xFFFFFFFE

        sti
        hlt
        jmp $-1

    .usermodeAllocate: ; ecx - requested blocks of 4 KiB. Output: si - segment.
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

        push es
        mov es, si
        xor edi, edi
        xor eax, eax
        mov ecx, ebx

        rep stosb
        pop es

        pop ds
        pop edi
        pop edx
        pop ecx
        pop ebx
        pop eax

        ret

    .loadFile: ; ds:esi - path to executable. Output: si - file segment
        push eax
        push ebx
        push ecx
        push edx

        push edx
        xor ebx, ebx
        call VFS.getFileInfo
        pop edx
        jc .loadFile.error
        push esi
        push eax

        mov ecx, ebx
        shr ecx, 1+2
        inc ecx

        call .usermodeAllocate

        pop eax
        mov fs, si
        pop esi
        xor edi, edi
        xor ebx, ebx

        call VFS.readFile

        xor esi, esi
        mov si, fs

        xor eax, eax
        clc
        jmp .loadFile.end

        .loadFile.error:
            mov eax, 1
            stc

        .loadFile.end:
            pop edx
            pop ecx
            pop ebx
            pop eax
            ret

    .yield:
        sti
        hlt
        cli
        ret
