
VFS:
  .init:
    pusha
    push es
    push fs
    push ds

    mov ax, Segments.Variables
    mov ds, ax

    mov ecx, 1
    xor edx, edx
    call API.alloc
    mov [ds:AllocSegments.VFS_Data], si
    mov es, si

    mov ax, Segments.FS_Header
    mov fs, ax

    xor eax, eax
    mov ecx, 0xfff/4
		xor edi, edi

		rep stosd

		mov byte es:[0], 00000001b   ; flags - mount point present
		mov eax, fs:[0]
		mov es:[1], eax              ; mounted disk

		mov byte es:[5], '/'         ; mount point (string, 26 byte max length)

		pop ds
		pop fs
    pop es
    popa
    ret

  .getFileInfo: ; ebx - UserID, ds:esi - file name string (zero-terminated). Output: ebx - file size, dl - file flags
    push edi
    push esi
    push edx
    push ecx
    push eax
    mov eax, esi
    call .mountCheck

    cmp eax, esi
    je .getFileInfo.error1


    call FlFS.getFileNumber
    jc .getFileInfo.error1

    cmp ebx, 0
    jz .getFileInfo.skipCheck

    call FlFS.getFileInfo
    cmp ebx, ecx

    jnz .getFileInfo.error2

    .getFileInfo.skipCheck:

    call FlFS.getFileInfo

    clc

    pop eax
    pop ecx
    pop esi ; pop edx
    pop esi
    pop edi
    ret

    .getFileInfo.error1:
      pop eax
      pop ecx
      pop edx
      pop esi
      pop edi

      jmp .error1.postpop

    .getFileInfo.error2:
      pop eax
      pop ecx
      pop edx
      pop esi
      pop edi

      jmp .error2.postpop

  .readFileForNewProcess: ; ebx - UserID, ecx - new PID, ds:esi - file name string (zero-terminated), fs:edi - buffer.
    pusha
    mov eax, esi
    push ecx
    call .mountCheck
    mov edx, ecx

    pop ecx
    cmp eax, esi
    je .error1

    call FlFS.getFileNumber
    jc .error1

    call LDT.set

    mov ecx, edx

    cmp ebx, 0
    jz .readFileForNewProcess.skipCheck
    push ecx
    push ebx
    call FlFS.getFileInfo
    pop ebx
    cmp ebx, ecx
    pop ecx
    jnz .error2

    .readFileForNewProcess.skipCheck:

    mov bx, fs
    mov ds, bx

    call FlFS.readFile

    popa
    ret

  .readFile: ; ebx - UserID, ds:esi - file name string (zero-terminated), fs:edi - buffer.
    pusha
    mov eax, esi
    call .mountCheck

    cmp eax, esi
    je .error1

    call FlFS.getFileNumber

    jc .error1

    cmp ebx, 0
    jz .readFile.skipCheck
    push ebx
    call FlFS.getFileInfo
    pop ebx
    cmp ebx, ecx
    jnz .error2

    .readFile.skipCheck:

    push ds
    mov bx, fs
    mov ds, bx

    call FlFS.readFile

    pop ds

    popa
    ret

    .error1:
      popa
    .error1.postpop:
      push ecx
		  call ProcessManager.getCurrentPID
		  call LDT.set
			pop ecx

      stc
      mov ebx, 0x00000001 ; Impossible path
      ret

    .error2:
      popa
    .error2.postpop:
      push ecx
	    call ProcessManager.getCurrentPID
		  call LDT.set
	    pop ecx

      stc
      mov ebx, 0x00000002 ; Not permitted to access
      ret

  .mountCheck: ; ds:esi - file path. Output: ecx - mounted disk, esi - path from mountpoint.
    pushfd
    cli
    push edx
    push eax
    push ebx
    push edi
    push fs

    SWITCH_TO_SYSTEM_LDT cx

    mov cx, Segments.Variables
    mov fs, cx

    mov cx, [fs:AllocSegments.VFS_Data]
    mov fs, cx

    xor ecx, ecx
    xor edi, edi
    xor ebx, ebx

    .mountCheck.loop:
      mov dl, fs:[edi+ecx+5]     ; read char from mountpoint path
      cmp dl, ds:[esi+ecx]       ; compare
      jne .mountCheck.next

      inc ecx
      cmp byte fs:[edi+ecx+5], 0 ; check if mountpoint path string has ended
      jnz .mountCheck.loop

      cmp ecx, ebx
      jl .mountCheck.next

      mov ebx, ecx
      mov eax, fs:[edi+1]

    .mountCheck.next:
      xor ecx, ecx
      add edi, 0x20

      cmp edi, 0xfdf
      jle .mountCheck.loop

    SWITCH_BACK_TO_PROCESS_LDT cx

    mov ecx, eax
    add esi, ebx

    pop fs
    pop edi
    pop ebx
    pop eax
    pop edx
    popfd
    ret
