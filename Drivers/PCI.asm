PCI_FunctionDoesNotExist equ 0xFFFFFFFF

PCIDeviceFunctionAmmount equ PCIDriverVariableSpace+0

PCIDriver:
    .detectDevices:
        pusha
        push ds
        push es
        mov word es:[PCIDeviceFunctionAmmount], 0
        mov edi, 0
        mov cx, 0x80
        mov ds, cx
        mov cx, 0x10
        mov es, cx
        mov cx, 0xFFFF
        mov eax, 1<<31
        mov dx, 0xCF8

        .detectDevices.loop:
            out dx, eax

            add dx, 4
            push eax
            in eax, dx
            sub dx, 4

            cmp eax, PCI_FunctionDoesNotExist						; Check if device function exists
            je .detectDevices.loopcont

            mov ds:[edi+4], eax
            pop eax
            push eax
            mov ds:[edi], eax

            or eax, 0x8
            out dx, eax
            add dx, 4
            in eax, dx
            sub dx, 4
            mov ds:[edi+8], eax

            inc word es:[PCIDeviceFunctionAmmount]
            add edi, 0x20

        .detectDevices.loopcont:
            pop eax
            shr eax, 8
            inc eax
            shl eax, 8
            loop .detectDevices.loop

        .detectDevices.done:
            pop es
            pop ds
            popa
            ret
