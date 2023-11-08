
STARTUP(Builds/KRNL.o)
ENTRY(KernelInit32)
OUTPUT_FORMAT(elf32-i386)

SECTIONS
{
    .text :
    {
        Builds/KRNL.o(.text)
    }

    .rodata :
    {
        *(.rodata)
    }
}
