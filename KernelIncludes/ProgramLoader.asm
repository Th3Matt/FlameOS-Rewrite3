 
ProgramLoader:
    .load: ; eax - UserID, edx - cpu ring, ds:esi - path to file. Output: ecx - Process ID
        push eax
        push edx
        push fs
        push esi
        push ds

        mov ebx, eax
        push ebx

        call ProcessManager.startProcess

        push edx
        call VFS.getFileInfo
        pop edx
        jc .load.error
        push esi
        push eax

        mov ax, 0x70
        mov ds, ax
        mov eax, ecx
        push ecx
        mov ecx, ebx

        call MemoryManager.memAlloc

        shl ebx, 4+4+3
        add ebx, eax
        pop ecx
        ;xor edx, edx

        call MemoryManager.createLDTEntry

		pop eax
        mov fs, si
        pop esi
        xor edi, edi

        pop ebx
        pop ds
        push ds
        push ebx

        call ProcessManager.setLDT

        push es
        mov ax, 0x8
        mov es, ax
        xor edi, edi

        call VFS.readFileForNewProcess

        xor esi, esi
        mov si, ds

        push ecx
        call ProcessManager.getCurrentPID
        call ProcessManager.setLDT
        pop ecx

        pop es
        pop ebx
        pop ds
        pop esi
        pop fs
        pop edx
        pop eax

        ret

        .load.error:
            call ProcessManager.stopProcess
            stc
            pop esi ; pop ebx
            pop esi
            pop fs
            pop edx
            pop eax

            ret

    .exec: ; eax - UserID, ecx - Process ID, edx - cpu ring
        push eax
        push ds
        push ebx
        push edx

        mov ax, 0x70
        mov ds, ax
        mov eax, ecx
        push ecx
        mov ecx, 1

        call MemoryManager.memAlloc

        mov ebx, 0x3ff
        pop ecx
        xor edx, edx

        call MemoryManager.createLDTEntry ; Creating SS0

        or esi, 4+0
        mov edi, esi
        mov eax, ecx
        push ecx
        mov ecx, 1

        call MemoryManager.memAlloc

        mov ecx, ebx
        mov ebx, 0x3ff
        pop ecx
        ;xor edx, edx
        pop edx

        call MemoryManager.createLDTEntry ; Creating SS

        push fs
        mov dx, 0x8
        mov fs, dx

        call ProcessManager.setLDT

        mov dx, 0+4+0
        mov ds, dx

        mov edx, [ds:0]

        shl esi, 16
        or esi, ((4+3)<<16)+0+4+3

        push es
        mov ax, 0x8
        mov es, ax
        mov eax, 0x400
        mov ebx, eax

        call ProcessManager.setUpTask

        push ecx
        call ProcessManager.getCurrentPID
        call ProcessManager.setLDT
        pop ecx

        pop es

        pop fs

        mov bx, 0x70
        mov ds, bx

        shl ecx, 3+4+4
        add ecx, 5
        or byte [ds:ecx], 00001000b ; Making the segment executable

        pop ebx
        pop ds
        pop eax

        ret

    .quickLoad: ; ds:esi - path to executable.
        push edx
        xor eax, eax
        mov edx, 0x3

        call .load
        jc .quickLoad.error

        cli

        call .exec

        mov eax, ecx
        call ProcessManager.getCurrentPID

        call ProcessManager.pauseProcess

        sti
        hlt

        xor eax, eax
        pop edx
        ret

        .quickLoad.error:
            mov eax, ebx

            pop edx
            ret
