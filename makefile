Builds/FlameOS.img: Builds/OS.bin
	cp "Builds/OS.bin" "Builds/FlameOS.img"
	truncate --size 1M "Builds/FlameOS.img" 

Builds/FlameOS.vdi: Builds/FlameOS.img
	if test -f "Builds/FlameOS.vdi"; then rm "Builds/FlameOS.vdi"; fi
	vboxmanage convertfromraw "Builds/FlameOS.img" "Builds/FlameOS.vdi"

Builds/BL.bin: Bootloader.asm
	nasm -fbin Bootloader.asm -o "Builds/BL.bin"

Builds/KRNL.bin: Kernel.asm Drivers/* KernelIncludes/*
	nasm -fbin Kernel.asm -o "Builds/KRNL.bin"

Builds/FS.bin: FilesystemHeader.asm
	nasm -fbin FilesystemHeader.asm -o "Builds/FS.bin"

Builds/OS.bin: Builds/BL.bin Builds/KRNL.bin Builds/FS.bin
	dd if="Builds/BL.bin" of="Builds/OS.bin" bs=512 conv=notrunc
	dd if="Builds/KRNL.bin" of="Builds/OS.bin" bs=512 seek=1 conv=notrunc
	dd if="Builds/FS.bin" of="Builds/OS.bin" bs=512 seek=49 conv=notrunc

qemu: Builds/FlameOS.img
	qemu-system-x86_64 -sdl -vga std -drive file=Builds/FlameOS.img,format=raw

bochs: Builds/FlameOS.img
	bochs -q

all: Builds/FlameOS.vdi
