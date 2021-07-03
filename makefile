BuildFS: FS.bin
	cp "Builds/FS.bin" "Builds/FlameOS.img"
	truncate --size 1M "Builds/FlameOS.img" 
	if test -f "Builds/FlameOS.vdi"; then rm "Builds/FlameOS.vdi"; fi
	VBoxManage convertfromraw "Builds/FlameOS.img" "Builds/FlameOS.vdi"

FS.bin: Bootloader.asm
	nasm -fbin Kernel.asm -o "Builds/FS1.bin"
	nasm -fbin Bootloader.asm -o "Builds/BL.bin"
	dd if="Builds/BL.bin" of="Builds/FS.bin" bs=512 conv=notrunc
	dd if="Builds/FS1.bin" of="Builds/FS.bin" bs=512 seek=1 conv=notrunc
	
