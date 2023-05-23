DeviceList.Size equ 0
DeviceList.FirstEntry equ 0x20
DeviceList.EntryDriverDataOffset equ 2+2+2
DeviceList.DeviceTypeOffset equ 0
DeviceList.ProtocolOffset equ 2+2

DeviceList:
    .init:
        push eax
        push ecx
        push edi
        push es

        mov ax, 0xB0
        mov es, ax

        xor edi, edi
        xor eax, eax
        mov ecx, 0x2000>>4

        rep stosd

        pop es
        pop edi
        pop ecx
        pop eax
        ret

    .addDevice: ; eax - Device type+(Parent device<<16), bx - Protocol, ecx - 4 bytes of additional data. Output: eax - Device entry number
        push ds
        push eax

        mov ax, 0xB0
        mov ds, ax

        pop eax
        push esi

        xor esi, esi
        mov si, [ds:DeviceList.Size]
        shl esi, 5
        cmp esi, 0x2000
        jz .addDevice.noSpace

        mov [ds:DeviceList.FirstEntry+si], eax
        mov [ds:DeviceList.FirstEntry+si+4], bx
        mov [ds:DeviceList.FirstEntry+si+6], ecx

        mov eax, esi

        inc word [ds:DeviceList.Size]
        inc eax

        pop esi
        pop ds
        clc
        ret

        .addDevice.noSpace:
            pop esi
            pop ds
            stc
            ret

    .writeToDeviceEntry: ; al - data, ecx - Device entry number, esi - offset
        push ds
        push eax

        mov ax, 0xB0
        mov ds, ax

        pop eax

        push ecx

        dec ecx
        shl ecx, 5
        add esi, ecx

        mov [ds:DeviceList.FirstEntry+si], al

        pop ecx

        pop ds
        ret

    .getDeviceEntry: ; ecx - Device entry number. Output: eax - (Device type)+(Parent device)<<16, bx - Protocol, ecx - 4 bytes of additional data
        push ds
        push eax

        mov ax, 0xB0
        mov ds, ax

        pop eax

        dec ecx
        shl ecx, 5

        mov eax, [ds:DeviceList.FirstEntry+ecx]
        mov bx, [ds:DeviceList.FirstEntry+ecx+4]
        mov ecx, [ds:DeviceList.FirstEntry+ecx+6]

        pop ds
        ret

    .removeDevice: ; ecx - Device entry number.
        push ds
        push eax

        mov ax, 0xB0
        mov ds, ax

        pop eax
        push ecx

        dec ecx
        shl ecx, 5

        mov dword [ds:DeviceList.FirstEntry+ecx], 0
        mov word [ds:DeviceList.FirstEntry+ecx+4], 0
        mov dword [ds:DeviceList.FirstEntry+ecx+6], 0

        pop ecx

        pop ds
        ret

    .findDevice: ;ax - Device type, bx - Protocol, ecx - which maching entry to return. Output: eax - Device entry number
        push esi
        push edx
        push ds
        mov si, 0xB0
        mov ds, si
        xor esi, esi
        xor edx, edx

        .findDevice.check:
            cmp ax, [ds:DeviceList.FirstEntry+si+DeviceList.DeviceTypeOffset]
            jnz .findDevice.next

            cmp bx, [ds:DeviceList.FirstEntry+si+DeviceList.ProtocolOffset]
            jnz .findDevice.next

            cmp edx, ecx
            jnz .findDevice.next2

        shr esi, 5
        mov eax, esi
        inc eax

        pop ds
        pop edx
        pop esi
        clc
        ret

        .findDevice.next2:
            inc edx
        .findDevice.next:
            add esi, 32
            cmp esi, 0x2000
            jz .findDevice.notFound
            jmp .findDevice.check

        .findDevice.notFound:
            pop ds
            pop edx
            pop esi
            stc
            ret
