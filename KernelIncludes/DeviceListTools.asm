DeviceList.Size equ 0
DeviceList.FirstEntry equ 0x20
DeviceList.EntryDriverDataOffset equ 2+2+2

DeviceList:
    .init:
        push eax
        push ecx
        push edi
        push ds

        mov ax, 0xB0
        mov ds, ax

        xor edi, edi
        mov ecx, 0x2000>>4

        rep stosd

        pop ds
        pop edi
        pop ecx
        pop eax
        ret

    .addDevice: ; eax - (Device type)+(Parent device)<<16, bx - Protocol, ecx - 4 bytes of additional data. Output: eax - Device entry number
        push ds
        push eax

        mov ax, 0xB0
        mov ds, ax

        pop eax
        push esi

        int word [ds:DeviceList.Size]
        xor esi, esi
        mov si, [ds:DeviceList.Size]
        shl esi, 5

        mov [ds:DeviceList.FirstEntry+si], eax
        mov [ds:DeviceList.FirstEntry+si+4], bx
        mov [ds:DeviceList.FirstEntry+si+6], ecx

        mov eax, esi

        pop esi

        pop ds
        ret

    .writeToDeviceEntry: ; al - data, ecx - Device entry number, esi - offset
        push ds
        push eax

        mov ax, 0xB0
        mov ds, ax

        pop eax

        push ecx

        shl esi, 5
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
        push ecx

        shl ecx, 5

        mov eax, [ds:DeviceList.FirstEntry+cx]
        mov bx, [ds:DeviceList.FirstEntry+cx+4]
        mov ecx, [ds:DeviceList.FirstEntry+cx+6]

        pop ecx

        pop ds
        ret

    .removeDevice: ; ecx - Device entry number.
        push ds
        push eax

        mov ax, 0xB0
        mov ds, ax

        pop eax
        push ecx

        shl ecx, 5

        mov [ds:DeviceList.FirstEntry+cx], 0
        mov [ds:DeviceList.FirstEntry+cx+4], 0
        mov [ds:DeviceList.FirstEntry+cx+6], 0

        pop ecx

        pop ds
        ret
