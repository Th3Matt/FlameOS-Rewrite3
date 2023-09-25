Builds/FlameOS.img: Builds Builds/OS.bin
	cp "Builds/OS.bin" "Builds/FlameOS.img"
	truncate --size 1M "Builds/FlameOS.img" 

Builds:
	mkdir Builds

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
	nasm -f elf -F dwarf -g Kernel.asm -o "Builds/KRNL.o"
	ld -melf_i386 -T linker.ld -o Builds/KRNL.tmp
	nm Builds/KRNL.tmp | sort | grep -E "[0-9a-f]{8} [b-zA-Z] .+" | sed "s/\ [a-zA-Z]\ /\ /g" > Builds/KRNL.nm
	objcopy -O binary Builds/KRNL.tmp Builds/KRNL.bin
	truncate --size 21K "Builds/KRNL.bin"

Builds/FS.bin: FilesystemHeader.asm FS/*
	nasm -fbin FilesystemHeader.asm -o "Builds/FS.bin"
	nasm -fbin FS/Term.asm -o "Builds/Term.bin"
	nasm -fbin FS/Snake.asm -o "Builds/Snake.bin"
	nasm -fbin FS/SnakeData.asm -o "Builds/SnakeData.bin"
	nasm -fbin FS/Clock.asm -o "Builds/Clock.bin"
	cat Builds/FS.bin Builds/Term.bin Builds/Snake.bin Builds/SnakeData.bin Builds/Clock.bin > Builds/FStmp.bin
	mv Builds/FStmp.bin Builds/FS.bin

Builds/OS.bin: Builds/FBL.bin Builds/BL.bin Builds/TBL.bin Builds/KRNL.bin Builds/FS.bin
	if test -f "Builds/OS.bin"; then rm "Builds/OS.bin"; fi
	cat Builds/FBL.bin Builds/BL.bin Builds/TBL.bin Builds/KRNL.bin Builds/FS.bin > Builds/OS.bin

qemu: Builds/FlameOS.img
	qemu-system-x86_64 -vga std -drive file=Builds/FlameOS.img,format=raw -s -S

bochs: Builds/FlameOS.img
	if test -f "Builds/FlameOS.img.lock"; then rm Builds/FlameOS.img.lock; fi
	bochs -q

all: Builds/FlameOS.vdi

clear:
	rm Builds/*
