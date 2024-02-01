Clock.clockTicks equ Clock

API:
    .quickLoad: ; ds:esi - path to executable. Output: eax - error code (1 - file not found, 2 - not executable)
        push edx
        push ecx
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
        mov ax, Segments.ProcessData
        mov es, ax
        shl ecx, 4

        .quickLoad.wait: ; waiting for another process to take over
        hlt

        test byte [es:ecx+0x20+0x4], 1 ; check if we're unpaused
        jnz .quickLoad.wait

        pop es

        xor eax, eax

        pop ecx
        pop edx
        ret

        .quickLoad.error:
            mov eax, ebx

            pop ecx
            pop edx
            ret

    .processExit:
        pusha

        call ProcessManager.getCurrentPID
        cli
        xor ebx, ebx
        mov ds, bx
        mov es, bx
        call ProcessManager.stopProcess

        call Print.delFramebuffer

        mov ax, Segments.ProcessData
        mov es, ax

        and dword es:[PMDB.flags], 0xFFFFFFFE

        sti
        hlt
        jmp $-1

    .usermodeAllocate:
        push edx

        mov edx, 3
        call .alloc

        pop edx
        ret

    .alloc: ; ecx - requested blocks of 4 KiB, edx - cpu ring. Output: si - segment.
        push eax

        call .allocWithAddress

        pop eax

        ret

    .allocWithAddress: ; ecx - requested blocks of 4 KiB, edx - cpu ring. Output: eax - allocation address, si - segment.
        push ebx
        push ecx
        push edx
        push edi

        push ecx
        call ProcessManager.getCurrentPID
        mov eax, ecx
        pop ecx
        call MemoryManager.memAlloc

        shl ecx, 4+4+4 ;*0x1000 
        mov ebx, ecx

        push ds
        mov si, Segments.UserspaceMem
        mov ds, si

        call ProcessManager.getCurrentPID

        call LDT.createEntry

        or esi, edx
        or esi, 100b

        push eax
        push es
        mov es, si
        xor edi, edi
        xor eax, eax
        mov ecx, ebx
        inc ecx

        rep stosb ; clearing memory (for security)
        pop es
		    pop eax

        pop ds
        pop edi
        pop edx
        pop ecx
        pop ebx

        ret

    .allocAtLocation: ; ecx - requested blocks of 4 KiB, edx - cpu ring, edi - location. Output: si - segment.
        push eax
        push ebx
        push ecx
        push edx
        push edi

        call MemoryManager.memAllocAtLocation

        shl ecx, 12
        mov ebx, ecx

        push ds
        mov si, Segments.UserspaceMem
        mov ds, si

        mov eax, edi

        call ProcessManager.getCurrentPID

        call LDT.createEntry

        or esi, 100b

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

    .readClock: ; Output: eax - clock ticks
        push ds
        mov ax, Segments.Variables
        mov ds, ax

        mov eax, ds:[Clock.clockTicks]

        pop ds
        ret
