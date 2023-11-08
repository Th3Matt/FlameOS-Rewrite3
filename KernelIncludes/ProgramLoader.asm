 
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

        mov ax, Segments.UserspaceMem
        mov ds, ax
        mov eax, ecx
        push ecx
        mov ecx, ebx

        call MemoryManager.memAlloc

        shl ebx, 4+4+3
        ;add ebx, eax
        pop ecx
        ;xor edx, edx

        call LDT.createEntry

		pop eax
        mov fs, si
        pop esi
        xor edi, edi

        pop ebx
        pop ds
        push ds
        push ebx

        push es
        mov ax, Segments.KernelStack
        mov es, ax
        xor edi, edi

        call VFS.readFileForNewProcess

        xor esi, esi
        mov si, ds

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
            pop ds
            pop esi
            pop fs
            pop edx
            pop eax

            ret

    .exec: ; eax - UserID, ecx - Process ID, edx - cpu ring
        push eax
        push ecx
        push ds
        push ebx
        push edx

        mov ax, Segments.UserspaceMem
        mov ds, ax
        mov eax, ecx
        push ecx
        mov ecx, 1

        call MemoryManager.memAlloc

        mov ebx, 0x3ff
        pop ecx
        xor edx, edx

        call LDT.createEntry ; Creating SS0

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

        call LDT.createEntry ; Creating SS

        push fs

        mov ax, 0x0
        mov fs, ax

        call LDT.set

        mov ax, 0+4+0
        mov ds, ax

        push es
        mov ax, 0x0
        mov es, ax

        push edx
        mov edx, [ds:0]

        shl esi, 16
        or esi, ((4+3)<<16)+0+4+3

        mov eax, 0x400
        mov ebx, eax

        call ProcessManager.setUpTask
        pop edx

        push ecx

        test dword [ds:4], 1b ; checking if program requests graphical framebuffer
        jz .exec.continue

        push ds
        mov ax, Segments.UserspaceMem
        mov ds, ax

        push edx
        mov eax, ecx
        push ecx
        mov ecx, (SCREEN_WIDTH*SCREEN_HEIGHT*4/0x1000)+1

        call MemoryManager.memAlloc

        mov ecx, ebx
        mov ebx, SCREEN_WIDTH*SCREEN_HEIGHT*4-1
        ;xor edx, edx
        pop ecx
        pop edx

        push esi
        call LDT.createEntry ; Creating GS

        call Print.addFramebuffer

        mov ax, (3<<3)+4
        mov es, ax

        or si, 11b
        mov es:[0x5C], si

        mov ax, Segments.Variables
        mov es, ax

        xor eax, eax
        mov ecx, es:[TotalPixels]
        shr ecx, 2

        mov es, si
        rep stosd

        pop esi
        pop ds

        mov ax, 0x0
        mov es, ax

        .exec.continue:

        call ProcessManager.getCurrentPID
        call LDT.set
        pop ecx

        pop es

        pop fs

        mov bx, Segments.UserspaceMem
        mov ds, bx

        shl ecx, 3+4+4
        add ecx, 5
        or byte [ds:ecx], 00001000b ; Making the segment executable

        pop ebx
        pop ds
        pop ecx
        pop eax

        ret
