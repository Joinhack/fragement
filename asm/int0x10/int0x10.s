# A bootsect, which print a string by BIOS interrupt video services(int 0x10)  
.code16

.section .text
.global main  
main:
	movw $0, %ax
	movw %ax, %es
	movw %ax, %ds
	movw $0xffff, %sp #alloc stack
	call clear
	call hello
	call loop
clear:
	movb $0x6, %ah #clear function no. 
	movb $0, %al
	movb $0x7, %bh
	movw $0, %cx  #cl ch left top position
	movb $24, %dh  #d right bottom position: row
	movb $79, %dh  #d right bottom position: col
	int $0x10
	ret
hello:
	movw $msg, %bp  #msg relative address, es is the segment address.
	movb $0x13, %ah #ah function no. 0x13
	movb $0x1, %al  #dispaly model
	movb $0x0, %bh 
	movb $0x23, %bl  #display attribute, 1:blue, 2:green, 3...
	movw len, %cx
	movb $0x9, %dh  #row
	movb $0x08, %dl  #col
	int $0x10
	ret
loop:
	jmp loop
  
msg:  
	.asciz "Hello world, say hi"
len:
	.int . - msg
	.org 0x1fe, 0x90  
	.word 0xaa55
