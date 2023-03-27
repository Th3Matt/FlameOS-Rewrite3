 
ProgramLoader:
    .load: ; eax - UserID, edx - cpu ring, esi - path to file. Output: ebx - Process ID
        push eax
        push ecx
        push ds
        push esi

        mov ebx, eax
        push ebx

        call ProcessManager.startProcess

        call VFS.getFileInfo
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
        mov ds, si
        pop esi
        xor edi, edi
        pop ebx
        call VFS.readFile

        xor esi, esi
        mov si, ds

        mov bx, 0x70
        mov ds, bx

        mov ebx, ecx
        shl ecx, 6+8
        add ecx, 5
        or byte [ds:ecx+esi], 00001000b ; Making the segment executable

        pop esi
        pop ds
        pop ecx
        pop eax

        ret

    .exec: ; eax - UserID, ebx - Process ID, edx - cpu ring
        push eax
        push ds
        push ebx
        push edx

        mov ax, 0x70
        mov ds, ax
        mov eax, ebx
        mov ecx, 1

        call MemoryManager.memAlloc

        mov ecx, ebx
        push ecx
        mov ebx, eax
        add ebx, 0x3ff
        xor edx, edx

        call MemoryManager.createLDTEntry ; Creating SS0

        or esi, 4+0
        mov edi, esi
        pop ebx ; pop ecx
        xor eax, eax
        mov ecx, 1

        call MemoryManager.memAlloc

        mov ecx, ebx
        mov ebx, eax
        add ebx, 0x3ff
        ;xor edx, edx
        pop edx

        call MemoryManager.createLDTEntry ; Creating SS

        mov dx, 0+4+0
        mov ds, dx

        mov edx, [ds:0]

        shl esi, 16
        or esi, ((4+3)<<16)+0+4+3

        mov eax, 0x400
        mov ebx, eax

        call ProcessManager.setUpTask

        mov bx, 0x70
        mov ds, bx

        pop ebx
        mov ecx, ebx
        shl ecx, 3+4+4
        add ecx, 5
        or byte [ds:ecx], 00001000b ; Making the segment executable

        pop ds
        pop eax

        ret
