Builds/FlameOS.img: Builds/OS.bin
	cp "Builds/OS.bin" "Builds/FlameOS.img"
	truncate --size 1M "Builds/FlameOS.img" 

Builds/FlameOS.vdi: Builds/FlameOS.img
	if test -f "Builds/FlameOS.vdi"; then rm "Builds/FlameOS.vdi"; fi
	vboxmanage convertfromraw "Builds/FlameOS.img" "Builds/FlameOS.vdi"

Builds/FBL.bin: FirstBootloader.asm
	nasm -fbin FirstBootloader.asm -o "Builds/FBL.bin"

Builds/BL.bin: Bootloader.asm
	nasm -fbin Bootloader.asm -o "Builds/BL.bin"

Builds/TBL.bin: ThirdBootloader.asm KernelIncludes/Constants.asm KernelIncludes/GDT.asm
	nasm -fbin ThirdBootloader.asm -o "Builds/TBL.bin"

Builds/KRNL.bin: Kernel.asm Drivers/* KernelIncludes/*
	nasm -fbin Kernel.asm -o "Builds/KRNL.bin"

Builds/FS.bin: FilesystemHeader.asm FS/Term.asm
	nasm -fbin FilesystemHeader.asm -o "Builds/FS.bin"
	nasm -fbin FS/Term.asm -o "Builds/Term.bin"
	dd if="Builds/Term.bin" of="Builds/FS.bin" bs=512 seek=4 conv=notrunc

Builds/OS.bin: Builds/FBL.bin Builds/BL.bin Builds/TBL.bin Builds/KRNL.bin Builds/FS.bin
	dd if="Builds/FBL.bin" of="Builds/OS.bin" bs=512 conv=notrunc
	dd if="Builds/BL.bin" of="Builds/OS.bin" bs=512 seek=1 conv=notrunc
	dd if="Builds/TBL.bin" of="Builds/OS.bin" bs=512 seek=2 conv=notrunc
	dd if="Builds/KRNL.bin" of="Builds/OS.bin" bs=512 seek=7 conv=notrunc
	dd if="Builds/FS.bin" of="Builds/OS.bin" bs=512 seek=50 conv=notrunc

qemu: Builds/FlameOS.img
	qemu-system-x86_64 -vga std -drive file=Builds/FlameOS.img,format=raw

bochs: Builds/FlameOS.img
	bochs -q

all: Builds/FlameOS.vdi

clear:
	rm Builds/*
