# A bootsect, http://baike.baidu.com/item/FAT12(int 0x13)  
.code16

.section .text
.org 0
	jmp _start
bpbOEM: .ascii "TEST FLO"
bpbBytesPerSector: .short 512
bpbSectorsPerCluster: .byte 1
bpbReservedSectors: .short 1
bpbNumberOfFATs: .byte 2
bpbRootEntries: .short 20  #define 20 enteries
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
	movw $0, %ax
	movw %ax, %es
	movw %ax, %ds
	movw $0xffff, %sp #alloc stack
	movw $msg, %si
	call print
	
loop:	
	call wait
	jmp loop


print:
	lodsb
	or %al, %al
	jz .print_done
	movb $0x0e, %ah #ah function no. 0x13
	int $0x10
	jmp print
	.print_done:
	ret

load_root:

	#compute how many sectors is used, and stored in cx
	xorw %cx, %cx
	xorw %dx, %dx
	movw $0x20, %ax #compute total size of root entries
	mulw bpbRootEntries #bpbRootEntries * 0x20  is total size
	divw bpbBytesPerSector #compute how many sectors are used.
	xchgw %ax, %cx #set cx to ax

	#compute location of root directory and store in "ax"
	movw bpbNumberOfFATs, %ax
	mulw bpbSectorsPerFAT            #sectors used by FATs (9, ax = 18)
	addw bpbReservedSectors, %ax     #adjust for bootsector(1, ax = 19)
	movw %ax, datasector             #base of root directory([datasector] = 19)
	addw %cx, datasector

wait:
	movb $0, %ah
	int $0x16
	ret


msg: .asciz "Loading...\r\n"
absTrack: .byte 0
absSector: .byte 1
devNO: .byte 0	
absHead: .byte 0
datasector: .short 0

headSec: .int 20000
	.org 510, '.' #fill with "." util 510. total need 512, left is follow.
	.word 0xaa55
