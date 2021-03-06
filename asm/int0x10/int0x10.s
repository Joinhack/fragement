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
	call put_test
	call hello
loop:	
	call wait
	jmp loop

clear:
	movb $0x6, %ah #clear function no. 
	movb $0, %al
	movb $0, %bh
	movw $0, %cx  #cl ch left top position
	movb $24, %dh  #d right bottom position: row
	movb $79, %dh  #d right bottom position: col
	int $0x10
	ret
put_test:
	mov $0, %cx
	.pt_c:
	movb $0, %dh
	movb $0, %dl
	addb %cl, %dl
	call set_cursor
	call set_cursor
	movb %cl, %al
	addb $65, %al
	movb $1, %bl
	addb %cl, %bl
	push %cx
	call put
	pop %cx
	inc %cx
	cmp $26, %cx
	jnz .pt_c
	ret
put:
	movb $0x9, %ah
	movb $0x0, %bh
	movb $0x1, %cl
	int $0x10
	ret
set_cursor:
	movb $0x02, %ah
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

wait:
	movb $0, %ah
	int $0x16
	ret

msg:
	.asciz "Hello world, say hi"
len:
	.int . - msg
	.org 510, '.' #fill with "." util 510. total need 512, left is follow.
	.word 0xaa55
