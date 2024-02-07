AHCIOffsets.GHC			    equ 0x000   ; Generic host control
AHCIOffsets.Port0		    equ 0x100   ; Port 0 offset

AHCIOffsets.GHC.CAP		  equ 0x00    ; Host cababilities
AHCIOffsets.GHC.GHC		  equ 0x04    ; Global HBA control
AHCIOffsets.GHC.IS		  equ 0x08    ; Interrupt status
AHCIOffsets.GHC.PI		  equ 0x0C    ; Ports implemented
AHCIOffsets.GHC.VER		  equ 0x10    ; Version
AHCIOffsets.GHC.CCCC	  equ 0x14    ; Command completion coalescing control
AHCIOffsets.GHC.CCCP	  equ 0x18    ; Command completion coalsecing ports
AHCIOffsets.GHC.EML		  equ 0x1C    ; Enclosure management location
AHCIOffsets.GHC.EMC		  equ 0x20    ; Enclosure management control
AHCIOffsets.GHC.CAP2	  equ 0x24    ; Extended capbilities
AHCIOffsets.GHC.BOHC	  equ 0x28    ; BIOS handoff control

AHCIOffsets.Port.cl		  equ 0x00    ; command list address
AHCIOffsets.Port.fb		  equ 0x08    ; FIS base address
AHCIOffsets.Port.is		  equ 0x10    ; interrupt status
AHCIOffsets.Port.ie		  equ 0x14    ; interrupt enable
AHCIOffsets.Port.cmd	  equ 0x18    ; command and status
AHCIOffsets.Port.tfd	  equ 0x20    ; task file data
AHCIOffsets.Port.sig	  equ 0x24    ; Port signature
AHCIOffsets.Port.satas	equ 0x28    ; SATA status
AHCIOffsets.Port.satac	equ 0x2C    ; SATA control
AHCIOffsets.Port.satae	equ 0x30    ; SATA error
AHCIOffsets.Port.sataa	equ 0x34    ; SATA active
AHCIOffsets.Port.cmdi	  equ 0x38    ; command issue
AHCIOffsets.Port.satan	equ 0x3C    ; SATA notification
AHCIOffsets.Port.fbsc	  equ 0x40    ; FIS-based switch control

AHCIOffsets.CommandListEntry.DW0	  equ 0x0
AHCIOffsets.CommandListEntry.prdb 	equ 0x4 ; Physical region descriptor byte count transferred
AHCIOffsets.CommandListEntry.cmdt 	equ 0x8 ; Command table descriptor base address

AHCIOffsets.FIS.type      equ 0x00
AHCIOffsets.FIS.flags_PM  equ 0x01
AHCIOffsets.FIS.command   equ 0x02
AHCIOffsets.FIS.status    equ 0x02
AHCIOffsets.FIS.featureL  equ 0x03
AHCIOffsets.FIS.error     equ 0x03
AHCIOffsets.FIS.LBA0      equ 0x04
AHCIOffsets.FIS.LBA1      equ 0x05
AHCIOffsets.FIS.LBA2      equ 0x06
AHCIOffsets.FIS.device    equ 0x07
AHCIOffsets.FIS.LBA3      equ 0x08
AHCIOffsets.FIS.LBA4      equ 0x09
AHCIOffsets.FIS.LBA5      equ 0x0A
AHCIOffsets.FIS.featureH  equ 0x0B
AHCIOffsets.FIS.count     equ 0x0C
AHCIOffsets.FIS.ICC       equ 0x0E
AHCIOffsets.FIS.control   equ 0x0F
AHCIOffsets.FIS.newStatus equ 0x0F

AHCI.Port.Size				equ 0x80
AHCI.CommandListEntry.Size	equ 0x20

AHCI.PortSignatures.SATA   equ 0x00000101
AHCI.PortSignatures.SATAPI equ 0xEB140101
AHCI.PortSignatures.EMB    equ 0xC33C0101 ; Enclosure management bridge
AHCI.PortSignatures.PM     equ 0x96690101 ; Port multiplier

AHCI.FISTypes.REG_H2D	   equ 0x27 ; Register FIS - host to device
AHCI.FISTypes.REG_D2H      equ 0x34 ; Register FIS - device to host
AHCI.FISTypes.DMA_ACT	   equ 0x39 ; DMA activate FIS - device to host
AHCI.FISTypes.DMA_SETUP    equ 0x41 ; DMA setup FIS - bidirectional
AHCI.FISTypes.DATA	       equ 0x46 ; Data FIS - bidirectional
AHCI.FISTypes.BIST		   equ 0x58 ; BIST activate FIS - bidirectional
AHCI.FISTypes.PIO_SETUP    equ 0x5F ; PIO setup FIS - device to host
AHCI.FISTypes.DEV_BITS	   equ 0xA1 ; Set device bits FIS - device to host

AHCIDriver:
  .init:
    pusha
    push ds
    push es
    push fs

    mov ecx, 1
    xor edx, edx
    call API.alloc
    mov cx, Segments.Variables
    mov es, cx
    mov [es:AllocSegments.AHCI_Data], si
    mov es, si

    mov si, Segments.KernelCode
    mov ds, si

    mov esi, Prefix.AHCI
    call CurrentContext.addNew

    mov eax, 0x01060100
    xor ebx, ebx ; Location

    call PCIDriver.deviceInfoByDword3
    jc .init.ideCheck

    .init.AHCICheck:
      push eax
      mov eax, 0x00FFFFFF
      mov esi, .msgAHCI
      xor ecx, ecx

      call Print.prefixedString
      pop eax

      call .initController

      jmp .init.end

    .init.ideCheck:
      mov eax, 0x01018000
      xor ebx, ebx ; Location

      call PCIDriver.deviceInfoByDword3
      jc .init.end

      push eax
      mov eax, 0x00FFFFFF
      mov esi, .msgIDE
      xor ecx, ecx

      call Print.prefixedString

      pop eax

      call .initController

    .init.end:
      pop fs
      pop es
      pop ds

      call CurrentContext.delContext

    popa
    ret

  .initController: ; eax - controller location, ds - Kernel Code, es - AHCI Data
    push eax
    mov eax, 0x00FFFFFF
    mov esi, .msgBAR5
    xor ecx, ecx

    call Print.prefixedString

    pop eax
    push eax
    mov ebx, 0x9+1 ; BAR 5

    call PCIDriver.deviceInfoByLocation
    pop ebx

    jc .doesntWork

    push ebx
    mov ebx, eax
    mov eax, 0x00FFFFFF
    xor ecx, ecx

    call Print.hex32

    mov esi, .msgEND

    call Print.string

    pop eax
    push eax

    call PCIDriver.getStatus

    test ax, 1<<4 ; Capabilities
    jz .initController.capabilitiesCheckEnd

    pop eax
    push eax

    mov ebx, 0x12 ; SATA

    call PCIDriver.checkCapability
    jc .initController.capabilitiesCheckEnd

    xor eax, eax
    not eax
    xor ecx, ecx

    mov esi, .msgCAP

    call Print.prefixedString

    .initController.capabilitiesCheckEnd:

    pop eax

    mov ebx, 5
    call PCIDriver.getBAR
    jz .doesntWork

    test eax, 1
    jz .initController.initMMIO

    .initController.initIO:

      and eax, 0xFFFFFFFC ; preparing IO port address
      mov edx, eax

      jmp .initController.checkGHC

    .initController.initMMIO:

      mov fs, si
      xor edx, edx
      not edx

    .initController.checkGHC:

      mov esi, AHCIOffsets.GHC.GHC

      call .readRegister

      test eax, 0x80000000 ; check if in ahci mode
      jz .initController.notInACHIMode

    .initController.checkPI:

      mov esi, AHCIOffsets.GHC.PI

      call .readRegister

      cmp eax, 0 ; check if any ports implemented
      jz .initController.noPortsImplemented

      mov [es:0], edx
      mov [es:4], fs

      call .initController.countPorts

    mov ebx, ecx
    xor eax, eax
    not eax
    xor ecx, ecx

    call Print.context

    call Print.dec32

    mov esi, .msgPortsImplemented
    call Print.string

    mov esi, AHCIOffsets.GHC.CAP2

    call .readRegister

    test eax, 0x00000001 ; check if BIOS/OS handoff needed
    jz .initController.BIOSHandoff.done

    .initController.BIOSHandoff:

      mov esi, AHCIOffsets.GHC.BOHC
      call .readRegister
      or eax, 1<<3
      call .writeRegister

      mov eax, 0x00FFFFFF
      mov esi, .msgHandoff
      xor ecx, ecx

      call Print.prefixedString

    .initController.BIOSHandoff.done:

		xor ecx, ecx
    dec ecx
		push ecx

    .initController.checkPorts:
			pop ecx
      inc ecx
			push ecx

			mov ax, 0x04
			mov bx, 0x03

			call DeviceList.findDevice

			jc .initController.checkPorts.done
      
      push eax

      mov ecx, eax

			call DeviceList.getDeviceEntry

      cmp cx, 1 ; check that device type is SATA
			jnz .initController.checkPorts.notDisk

      shr ecx, 16

			push es
			push ecx
			push edx

			mov ecx, 3
			xor edx, edx
			call API.allocWithAddress
      
      mov es, si

			pop edx
			pop ecx

			mov esi, ecx
			shl esi, 4+3 ; *0x80
			add esi, AHCIOffsets.Port0+AHCIOffsets.Port.cl

			call .writeRegister

			push eax

			xor eax, eax

			add esi, 4 ; Command list upper 32 bits

			call .writeRegister

			pop eax

			add eax, 0x400

			add esi, 4 ; FIS base address

			call .writeRegister

			push eax

			xor eax, eax

			add esi, 4 ; FIS base address upper 32 bits

			call .writeRegister

			pop eax

			call .stopCmdProcessing

			push ecx
			mov ecx, 32
			xor edi, edi

			.initController.checkPorts.disk.loop:
				mov [es:edi+AHCIOffsets.CommandListEntry.prdb], dword 0
				mov [es:edi+AHCIOffsets.CommandListEntry.cmdt], eax
				mov [es:edi+AHCIOffsets.CommandListEntry.cmdt+4], dword 0

        add eax, 0x100
				add edi, AHCI.CommandListEntry.Size

				loop .initController.checkPorts.disk.loop

			pop ecx

			call .resetPort

			call .startCmdProcessing

			push ecx

			mov ecx, 1
			call Sleep

			pop ecx

			mov esi, ecx
			shl esi, 4+3 ; *0x80
			add esi, AHCIOffsets.Port0+AHCIOffsets.Port.sig
			;mov esi, 0

			call .readRegister
			cmp eax, 0x00000101
			je .initController.checkPorts.disk.isStillADisk

			pop es
      pop eax

			jmp .initController.checkPorts

			.initController.checkPorts.disk.isStillADisk:

			pusha

      mov edi, ecx

      mov ecx, 1
      xor edx, edx
      
      call API.allocWithAddress

      mov ebx, 0xFFFF

      call .setBufferForSlot

			mov eax, ATA.CMD.IDENTIFY
			mov ebx, 0
			mov dx, cx
      mov cx, 0

			call .prepareATACommand
      
      popa
      pusha

      mov edi, ecx
      mov ecx, 0
      call .issueCommand

      popa

      mov ax, es
			pop es

      pop ecx
      xor esi, esi
      
      call DeviceList.writeWordToDeviceEntry

			jmp .initController.checkPorts

		.initController.checkPorts.notDisk:

    pop eax
	  jmp .initController.checkPorts

		.initController.checkPorts.done:
		  pop ecx
      clc

    .initController.end:
    
    ret

  .initController.countPorts: ; eax - ports implemented register. Output: ecx - count of ports implemented.
    push eax
    push ebx

    xor ebx, ebx
    xor ecx, ecx

    .initController.countPorts.loop:
      test eax, 1
      jz .initController.countPorts.noPort

      inc ecx

      push eax

      call .initController.registerDisk

      pop eax

    .initController.countPorts.noPort:
      shr eax, 1
      inc ebx
      cmp eax, 0
      jnz .initController.countPorts.loop

      pop ebx
      pop eax

    ret

	.initController.notInACHIMode:
        mov eax, 0x00FFFFFF
        mov esi, .msgNotInACHIMode
        xor ecx, ecx

        call Print.prefixedString

        stc
        jmp .initController.end

    .initController.noPortsImplemented:
        mov eax, 0x00FFFFFF
        mov esi, .msgNoPortsImplemented
        xor ecx, ecx

        call Print.prefixedString

        stc
        jmp .initController.end

    .initController.registerDisk:
        pusha

        push fs

        mov ecx, ebx
        shl ecx, 16

        mov cx, Segments.Variables
        mov fs, cx
        mov cx, [fs:AllocSegments.AHCI_Data]
        mov fs, cx

        mov esi, ebx
        shl esi, 4+3 ; *0x80
        add esi, AHCIOffsets.Port0+AHCIOffsets.Port.sig

        mov edx, [fs:0]
        mov fs, [fs:4]

        call .readRegister

        mov cx, 1
        cmp eax, AHCI.PortSignatures.SATA
        je .initController.registerDisk.sigDone

        mov cx, 2
        cmp eax, AHCI.PortSignatures.SATAPI
        je .initController.registerDisk.sigDone

        mov cx, 3
        cmp eax, AHCI.PortSignatures.EMB
        je .initController.registerDisk.sigDone

        mov cx, 4
        cmp eax, AHCI.PortSignatures.PM
        je .initController.registerDisk.sigDone

        mov cx, 0

        .initController.registerDisk.sigDone:

        mov eax, 4
        mov bx, 3

        call DeviceList.addDevice

        pop fs

        popa
        ret

  .doesntWork:
    mov eax, 0x00FFFFFF
    mov esi, .msgFail
    xor ecx, ecx

    call Print.prefixedString

    ret

  .readRegister: ; edx - ABAR IO port (0xFFFFFFFF if mmio), esi - offset, fs - ABAR segment, used if mmio. Output: eax - read data.
    push edx
    inc edx
    jz .readRegister.mmio

    .readRegister.IO:
      dec edx
      add edx, esi

      in eax, dx

      jmp .readRegister.end

    .readRegister.mmio:
      mov eax, fs:[esi]

    .readRegister.end:
    
    pop edx
    ret

  .writeRegister: ; eax - data to write, edx - ABAR IO port (0xFFFFFFFF if mmio), esi - offset, fs - ABAR segment, used if mmio.
    push edx
    inc edx
    jz .writeRegister.mmio

    .writeRegister.IO:
      dec edx
      add edx, esi

      out dx, eax

      jmp .writeRegister.end

    .writeRegister.mmio:
      mov fs:[esi], eax

    .writeRegister.end:
    
    pop edx
    ret

	.startCmdProcessing: ; ecx - port, edx - ABAR IO port (0xFFFFFFFF if mmio), fs - ABAR segment, used if mmio.
		pusha

		mov esi, ecx
    shl esi, 4+3 ; *0x80
    add esi, AHCIOffsets.Port0+AHCIOffsets.Port.cmd

    .startCmdProcessing.loop:
			call .readRegister

			test eax, 1<<15 ; check if command list running
			jnz .startCmdProcessing.loop

		or eax, ((1<<04) + (1<<00)) ; set "FIS recieve enable" and "Start"

		call .writeRegister

    popa
    ret

	.stopCmdProcessing: ; ecx - port, edx - ABAR IO port (0xFFFFFFFF if mmio), fs - ABAR segment, used if mmio.
		pusha

		mov esi, ecx
        shl esi, 4+3 ; *0x80
        add esi, AHCIOffsets.Port0+AHCIOffsets.Port.cmd

		call .readRegister

		and eax, 0xFFFFFFFF^((1<<04) + (1<<00)) ; unset "FIS recieve enable" and "Start"

		call .writeRegister

		.stopCmdProcessing.loop:
			call .readRegister

			test eax, (1<<15) + (1<<14) ; check if command list running or FIS recieve running
			jnz .stopCmdProcessing.loop

        popa
        ret

	.resetPort: ; ecx - port, edx - ABAR IO port (0xFFFFFFFF if mmio), fs - ABAR segment, used if mmio.
		pusha

		mov esi, ecx
        shl esi, 4+3 ; *0x80
        add esi, AHCIOffsets.Port0+AHCIOffsets.Port.satac

		call .readRegister

		and eax, 0xFFFFFFFF^(1111b)
		or eax, 0001b

		call .writeRegister

		push ecx
		mov ecx, 1
		call Sleep
		pop ecx

		call .readRegister

		and eax, 0xFFFFFFFF^(1111b)

		call .writeRegister

		add esi, AHCIOffsets.Port.satas-AHCIOffsets.Port.satac

		.resetPort.loop:
			call .readRegister

			and al, 0xF
			cmp al, 3
			jnz .resetPort.loop

		add esi, AHCIOffsets.Port.satae-AHCIOffsets.Port.satas

		xor eax, eax
		not eax

		call .writeRegister

		popa
		ret

  .prepareATACommand: ; eax - (Features << 8) + Command, ebx - lba (first 32 bits), cx - count, dx - ammount of physical region descriptor table entries, edi - command slot, es - command segment
    pusha

    push edi
    shl edi, 4+4 ; *0x100
    add edi, 32*0x20

    mov byte es:[edi+AHCIOffsets.FIS.type], AHCI.FISTypes.REG_H2D
    mov byte es:[edi+AHCIOffsets.FIS.flags_PM], (1<<7) + (0<<4) + (0)
    mov word es:[edi+AHCIOffsets.FIS.command], ax

    mov word es:[edi+AHCIOffsets.FIS.LBA0], bx
    shr ebx, 16
    mov byte es:[edi+AHCIOffsets.FIS.LBA2], bl

    mov byte es:[edi+AHCIOffsets.FIS.device], 11100000b

    mov byte es:[edi+AHCIOffsets.FIS.LBA3], bh
    mov word es:[edi+AHCIOffsets.FIS.LBA4], 0

    shr eax, 16
    mov byte es:[edi+AHCIOffsets.FIS.featureH], al

    mov word es:[edi+AHCIOffsets.FIS.count], cx

    mov byte es:[edi+AHCIOffsets.FIS.ICC], 0
    mov byte es:[edi+AHCIOffsets.FIS.control], 0

    pop edi
    shl edi, 1+4 ; *0x20

    mov word es:[edi], (1<<10) + (0<<7) + (0<<6) + (0<<5) + 5

    mov word es:[edi+2], dx

    popa
    ret

  .issueCommand: ; ecx - command slot, edx - ABAR IO port (0xFFFFFFFF if mmio), edi - port, fs - ABAR segment, used if mmio.
    pusha

    shl edi, 3+4 ; *0x80

    mov esi, edi

    add esi, AHCIOffsets.Port0 + AHCIOffsets.Port.cmdi
    mov eax, 1
    shl eax, cl
    call .writeRegister

    popa
    ret

  .waitForCommandCompletion: ; ecx - command slot, edx - ABAR IO port (0xFFFFFFFF if mmio), edi - port, fs - ABAR segment, used if mmio.
    pusha

    shl edi, 3+4 ; *0x80

    mov esi, edi

    add esi, AHCIOffsets.Port0 + AHCIOffsets.Port.cmdi
    mov ebx, 1
    shl ebx, cl
    
    .waitForCommandCompletion.loop:
      sub esi, AHCIOffsets.Port.cmdi - AHCIOffsets.Port.is

      call .readRegister

      test eax, 1<<30 ; check for error
      stc
      jnz .waitForCommandCompletion.end

      add esi, AHCIOffsets.Port.cmdi - AHCIOffsets.Port.is

      call .readRegister
      
      test eax, ebx
      jnz .waitForCommandCompletion.loop

    clc
    
    .waitForCommandCompletion.end:
    popa
    ret

  .setBufferForSlot: ; eax - buffer base, ebx - buffer size, edi - command slot, es - command segment. Output: ecx - count of PRDB descriptors set up.
    push eax
    push ebx
    push edx
    push esi

    push eax
   
    mov ecx, 0x400000
    mov eax, ebx
    xor edx, edx
    div ecx
    mov ecx, eax

    pop eax

    mov esi, ecx

    jecxz .setBufferForSlot.finalWrite 
    
    .setBufferForSlot.loop:
      push ecx

      sub ecx, esi
      not ecx
      inc ecx

      mov ebx, 0x400000

      call .modifyPRDTEntry

      add eax, 0x400000
      pop ecx

      loop .setBufferForSlot.loop

    .setBufferForSlot.finalWrite:
      mov ecx, esi
      mov ebx, edx

      call .modifyPRDTEntry 

    mov ecx, esi
    inc ecx

    pop esi
    pop edx
    pop ebx
    pop eax

    ret

  .clearPRDTEntries: ; edi - command slot, es - command segment.
    pusha

    xor eax, eax
    xor ebx, ebx
    mov ecx, 32

    .clearPRDTEntries.loop:
      call .modifyPRDTEntry

      loop .clearPRDTEntries.loop

    popa
    ret

  .modifyPRDTEntry: ; eax - buffer base, ebx - buffer size (22-bit), ecx - entry number, edi - command slot, es - command segment.
    pusha

    shl edi, 4+4 ; *0x100
    add edi, 32*0x20+0x80
    shl ecx, 2
    add edi, ecx

    and eax, 0xFFFFFFFE

    mov dword es:[edi], eax
    mov dword es:[edi+4], 0
    mov dword es:[edi+8], 0
    
    sub ebx, 1
    jc .modifyPRDTEntry.end
    and ebx, (0<<31) + 0x3FFFFF
    mov dword es:[edi+12], ebx 

    .modifyPRDTEntry.end:
    popa
    ret
  
  .waitForNotBusy: ; edx - ABAR IO port (0xFFFFFFFF if mmio), edi - port, fs - ABAR segment, used if mmio.
    pusha

    shl edi, 3+4 ; *0x80

    mov esi, edi

    add esi, AHCIOffsets.Port0 + AHCIOffsets.Port.tfd
    
    .waitForNotBusy.loop:
      call .readRegister

      test eax, ATA_STATUS_DRQ|ATA_STATUS_BSY ; check for error
      jnz .waitForNotBusy.loop

    clc
    .waitForNotBusy.end:
    popa
    ret

  .readSectors: ; eax - starting sector, ebx - disk #, ecx - sectors to read, fs:edi - buffer.
    pushfd
    cli
    pusha

    push eax
    push ecx

    mov ecx, ebx
		mov ax, 0x04
		mov bx, 0x03

    call DeviceList.findDevice
    jc .readSectors.notDisk

    push eax

    mov ecx, eax

		call DeviceList.getDeviceEntry

    mov ebx, ecx
    pop ecx ; pop eax
		
    cmp bx, 1 ; check that device type is SATA
		jnz .readSectors.notDisk

    shr ebx, 16

    xor esi, esi

    call DeviceList.readWordFromDeviceEntry

    pop ecx
    pop esi ; pop eax
    
    push fs
    push es
    push ds

    push esi
    SWITCH_TO_SYSTEM_LDT si
    
    mov es, ax
    
    SWITCH_BACK_TO_PROCESS_LDT si
    pop esi

    mov eax, esi

    mov si, fs
    mov ds, si

    call LDT.getEntryBaseAddress ; This function has the quirk of requiring the current LDT to be the one containing ds

    push ebx
    push ecx
    push eax
    mov eax, esi

    mov ebx, ecx
    shl ebx, 1+4+4 ; *0x200
    xor edi, edi

    call .clearPRDTEntries
    call .setBufferForSlot

		mov eax, ATA.CMD.READ.DMA_EXT
    pop ebx ; pop eax
    mov dx, cx
    pop ecx

		call .prepareATACommand
    
    SWITCH_TO_SYSTEM_LDT di

    mov di, Segments.Variables
    mov fs, di
    mov fs, fs:[AllocSegments.AHCI_Data]
    mov edx, fs:[0]
    cmp edx, 0xFFFFFFFF
    jne .readSectors.pastFSGet
    
    mov fs, fs:[4]
  
    .readSectors.pastFSGet:
    
    SWITCH_BACK_TO_PROCESS_LDT di

    pop edi ; pop ebx
    mov ecx, 0

    call .waitForNotBusy

    call .issueCommand

    call .waitForCommandCompletion 

    pop ds
    pop es
    pop fs

    jc .readSectors.error

    clc
    popa
    popfd
    ret

    .readSectors.notDisk:
      pop ecx
      pop eax

    .readSectors.error:
      
      stc
      popa
      popfd
      ret

section .rodata

    .msgFail:
        db .msgFail.end-.msgFail-1, "AHCI controller insane or doesn't exist.", 10
        .msgFail.end:
    .msgBAR5:
        db .msgBAR5.end-.msgBAR5-1, "AHCI controller BAR5 is 0x"
        .msgBAR5.end:
    .msgCAP:
        db .msgCAP.end-.msgCAP-1, "AHCI controller has SATA capability.", 10
        .msgCAP.end:
    .msgEND:
        db .msgEND.end-.msgEND-1, ".", 10
        .msgEND.end:
    .msgNoPortsImplemented:
        db .msgNoPortsImplemented.end-.msgNoPortsImplemented-1, "No ports implemented, exiting.", 10
        .msgNoPortsImplemented.end:
    .msgAHCI:
        db .msgAHCI.end-.msgAHCI-1, "AHCI controller detected.", 10
        .msgAHCI.end:
    .msgIDE:
        db .msgIDE.end-.msgIDE-1, "AHCI controller in IDE mode detected.", 10
        .msgIDE.end:
    .msgNotInACHIMode:
        db .msgNotInACHIMode.end-.msgNotInACHIMode-1, "AHCI controller is not in AHCI mode, exiting.", 10
        .msgNotInACHIMode.end:
    .msgPortsImplemented:
        db .msgPortsImplemented.end-.msgPortsImplemented-1, " port(s) implemented.", 10
        .msgPortsImplemented.end:
    .msgHandoff:
        db .msgHandoff.end-.msgHandoff-1, "BIOS/OS handoff completed.", 10
        .msgHandoff.end:

Prefix.AHCI: db Prefix.AHCI.end-Prefix.AHCI-1, "AHCIDriver: "
Prefix.AHCI.end:

section .text

