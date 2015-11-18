# A bootsect, which print a string by BIOS interrupt video services(int 0x10)  
.code16

.section .text  
.global _start  
_start:
	movw $0, %ax
	movw %ax, %es

	movw %ax, %ds
	movw $msg, %bp

	movb $0x13, %ah
	movb $0x1, %al
	movb $0x0, %bh
	movb $0x1, %bl
	movw len, %cx
	movb $0x9, %dh  #row
	movb $0x08, %dl  #col
	int $0x10

  
msg:  
	.asciz "Hello world, say hi"
len:
	.int . - msg
	.org 0x1fe, 0x90  
	.word 0xaa55
