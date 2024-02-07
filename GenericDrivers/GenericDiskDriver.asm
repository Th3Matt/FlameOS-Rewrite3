
GenericDiskD:
  .init:
    ret

  .readSectors: ; eax - starting sector, ebx - (disk type << 8) + disk #, ecx - sectors to read, fs:edi - buffer.
    push ebx
    push edx
    ror ebx, 8
    cmp bl, 2
    jne .readSectors.notATA

    mov edx, S_ATA_PI.readSectors
    jmp .readSectors.read
    
    .readSectors.notATA: 

    cmp bl, 3
    jne .readSectors.notAHCI

    mov edx, AHCIDriver.readSectors
    jmp .readSectors.read

    .readSectors.notAHCI:
    
    jmp $
    
    stc
    jmp .readSectors.end

    .readSectors.read:
    shr ebx, 24

    call edx 
    .readSectors.end:
    pop edx
    pop ebx
    ret
    
