
GDV.CurrentKeyboard equ GenericDriverVariables

GenericKeyboardD:
    .init:
        pusha

        mov ebx, .getKey
        mov ecx, 0x10
        call Syscall.add

        popa
        ret

    .getKey:
        push ebx
        push esi
        push ecx
        push ds

        mov ax, Segments.Variables
        mov ds, ax

        .getKey.getKeyboard:

        mov ebx, ds:[GDV.CurrentKeyboard]
        inc dword ds:[GDV.CurrentKeyboard]

        mov ecx, ebx
        mov ebx, 1
        mov eax, 2

        call DeviceList.findDevice
        jc .getKey.overflow

        mov ecx, eax
        mov esi, 1

        call DeviceList.readWordFromDeviceEntry

        mov bl, ah
        cmp bl, al
        mov eax, 0
        je .getKey.done

        mov esi, 2
        inc ebx

        cmp ebx, PS2_keyboardBufferSize ; check for overflow
        jl .getKey.1

        mov ebx, 0x0

        .getKey.1:

        mov al, bl

        call DeviceList.writeByteToDeviceEntry

        add ebx, 3-1

        mov esi, ebx

        xor eax, eax
        call DeviceList.readByteFromDeviceEntry

        .getKey.done:

        pop ds
        pop ecx
        pop esi
        pop ebx
        ret

        .getKey.overflow:
            mov dword ds:[GDV.CurrentKeyboard], 0

            jmp .getKey.getKeyboard
