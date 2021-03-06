/**
 * A bootsect, refers
 * https://en.wikipedia.org/wiki/INT_13H(int 0x13)  
 * https://en.wikipedia.org/wiki/File_Allocation_Table//FAT12
 * http://tigcc.ticalc.org/doc/gnuasm.html#SEC39
 */


/**
 * link use this for relative address. example in Makefile ld use parameter -Tdata 0
 *	movw $begin, %ax now ax is 0
 * if -Tdata 0x7c0 $begin, %ax now ax is 0x7c0
 */
.code16
.section ".mytext", "ax"

begin:
	jmp _start
bpbOEM: .ascii "TEST FLO"
bpbBytesPerSector: .short 512
bpbSectorsPerCluster: .byte 1
bpbReservedSectors: .short 1
bpbNumberOfFATs: .byte 2
bpbRootEntries: .short 224  //define 224 enteries
bpbTotalSectors: .short 2880
bpbMedia: .byte 0xf0
bpbSectorsPerFAT: .short 9
bpbSectorsPerTrack: .short 18
bpbHeadsPerCylinder: .short 2
bpbHiddenSectors: .int 0
bpbTotalSectorsBig: .int 0
bsDriveNumber: .byte 0
bsUnused: .byte 0
bsExtBootSignature: .byte 0x29
bsSerialNumber: .int 0xa0a1a2a3
bsVolumeLabel: .ascii "TEST FLOPPY"
bsFileSystem: .ascii "FAT12   "

.global _start
_start:
	cli
	movw $0x7c0, %ax
	movw %ax, %ds
	movw %ax, %gs
	movw %ax, %fs
	movw %ax, %es

	//stack alloc
	movw 0xf000, %ax
	movw %ax, %ss
	movw $0xffff, %sp
	sti

	movw $msg, %si
	call print
	
	call load_root

	call search_kernel_fat
	//should not happened follow steps.
loop:	
	call wait
	jmp loop


print:
	lodsb %ds:(%si)
	or %al, %al
	jz .print_done
	movb $0x0e, %ah //ah function no. 0x13
	int $0x10
	jmp print
	.print_done:
	ret

load_root:

	//compute how many sectors is used, and stored in cx
	xorw %cx, %cx
	xorw %dx, %dx
	movw $0x0020, %ax //compute total size of root entries
	mulw bpbRootEntries //bpbRootEntries * 0x20  is total size
	divw bpbBytesPerSector //compute how many sectors are used.
	xchgw %ax, %cx //set cx to ax

	//compute location of root directory and store in "ax"
	movb bpbNumberOfFATs, %al
	mulw bpbSectorsPerFAT            //sectors used by FATs (9, ax = 18)
	addw bpbReservedSectors, %ax     //adjust for bootsector(1, ax = 19)
	movw %ax, datasector             //base of root directory([datasector] = 19)
	addw %cx, datasector             //[datasector] = 19 + 14 = 33

	/**read  to (0x7C00:0x0200)
	in nasm assign the es is not necessary, because use start address for es, ds, ss, and etc
	there some different between nasm and gas.*/

	movw kernel_offset, %bx
	call readSectors
	ret


readSectors:
	movw $5, %di //max retry times
	.readS_main:
	pushw %ax
	pushw %bx
	pushw %cx
	call LBACHS
	movb $0x02, %ah
	movb $0x01, %al 
	movb absCHTrack, %ch
	movb absCLSector, %cl
	movb absDHHead, %dh
	movb devNO, %dl
	int $0x13
	jnc .readS_success
	xorw %ax, %ax //reset when retry
	int $0x13
	popw %cx
	popw %bx
	popw %ax
	decw %di
	jnz .readS_main
	int $0x18
	.readS_success:
	movw $msgProgess, %si //print "."
	call print
	popw %cx
	popw %bx
	popw %ax
	add bpbBytesPerSector, %bx
	incw %ax
	loop readSectors
	ret

/**Temp = LBA / (Sectors per Track)
Sector = (LBA % (Sectors per Track)) + 1
Head = Temp % (Number of Heads)
Cylinder = Temp / (Number of Heads)*/
LBACHS:
	xorw %dx, %dx
	divw bpbSectorsPerTrack
	incb %dl
	movb %dl, absCLSector
	xorw %dx, %dx
	divw bpbHeadsPerCylinder
	movb %dl, absDHHead
	movb %al, absCHTrack
	ret

wait:
	movb $0, %ah
	int $0x16
	ret

search_kernel_fat:
	movw bpbRootEntries, %cx
	movw kernel_offset, %di
	.search_kernel_fat_loop:
	pushw %cx
	pushw %di
	movw $11, %cx //compare 11 bytes.
	movw $kernel_name, %si
	repnz cmpsb %es:(%di), %ds:(%si)
	je load_fat
	popw %di
	popw %cx
	addw $0x0020, %di //compare 11 bytes every 0x20 block.
	loop .search_kernel_fat_loop
	call fail_load
	ret
	
load_fat:
	popw %di  //fetch the origin di in stack pushed in search_kernel_fat before jmp to here.
	movw 0x1A(%di), %dx //0x1A is the first cluster, refer fat12 root entity.

	// compute size of FAT and store in "cx"
	xorw %ax, %ax
	movb bpbNumberOfFATs, %al
	mulw bpbSectorsPerFAT  
	movw %ax, %cx
	mulw bpbBytesPerSector
	movw %ax, fatsize
	movw bpbReservedSectors, %ax

	//read FAT into memory (7C00:0200)
	mov kernel_offset, %bx
	call readSectors
	

fail_load:
	movw $failedMsg, %si
	call print
	call wait
	int $0x19
	ret


msg: .asciz "Loading"
kernel_name: .ascii "kernel.img"
msgProgess: .asciz "."
failedMsg: .asciz "\r\nLoading failed.\r\n"
absCHTrack: .byte 0
absCLSector: .byte 0
kernel_offset: .short 0x200
devNO: .byte 0	
fstCluster: .short 0
fatsize: .short 0
absDHHead: .byte 0
datasector: .short 0

headSec: .int 20000
	.org 510, '.'
	.word 0xaa55
