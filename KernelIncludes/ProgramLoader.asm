 
ProgramLoader:
    .load: ; eax - UserID, esi - path to file. Output: ebx - Process ID
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
        xor edx, edx

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

    .exec: ; eax - UserID, ebx - Process ID
        push eax
        push ebx
        push ds

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

        call MemoryManager.createLDTEntry ; Creating SS

        pop ebx ; pop ecx
        xor eax, eax
        mov ecx, 1

        call MemoryManager.memAlloc

        mov ecx, ebx
        mov ebx, eax
        add ebx, 0x3ff
        xor edx, edx

        call MemoryManager.createLDTEntry ; Creating SS0

        mov dx, 0+4+0
        mov ds, dx

        mov edx, [ds:0]

        mov eax, 4+4+3
        mov ebx, eax

        mov esi, 0+4+((8+4)<<16)
        mov edi, 16+4

        call ProcessManager.setUpTask

        pop ds
        pop ebx
        pop eax

        ret
