# A bootsect, which print a string by BIOS interrupt video services(int 0x13)  
.code16

.section .text
.global main
main:
	movw $0, %ax
	movw %ax, %es
	movw %ax, %ds
	movw $0xffff, %sp #alloc stack
	
	call clear
	movw $msg, %bp  #msg relative address, es is the segment address.
	movw msglen, %cx
	movw $0x0, %dx  #row dh:0, col dl:0
	call print
	
	movw $0, %bx
	movw headSec, %ax  #read address location, location is es:bx
	movw %ax, %es
	call read_sector

	movw $0, %ax
	movw %ax, %es  #reset es, print used es
	movw $0, %bx
	movw %ax, %ds
	leaw alert, %bp  #msg relative address, es is the segment address.
	movw alert_len, %cx
	movw $0x100, %dx  #row dh:0, col dl:0
	call print

	movw headSec, %ax  #print es:bp size is cx
	movw %ax, %es
	movw $0, %ax
	movw %ax, %bp
	movw $512, %cx
	movw $0x200, %dx
	call print

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

print:
	movb $0x13, %ah #ah function no. 0x13
	movb $0x1, %al  #dispaly model
	movb $0x0, %bh 
	movb $0x2, %bl  #display attribute, 1:blue, 2:green, 3...
	int $0x10
	ret
read_sector:
	mov $5, %di #retry times
.sector_loop:
	movb $0x2, %ah
	movb $0x1, %al #read only one sector
	movb absTrack, %ch
	movb absSector, %cl
	movb absHead, %dh
	movb devNO, %dl
	int $0x13
	jnc .sector_sucess
	xorw %ax,%ax  #reset
	int $0x13
	dec %di

	movw $0, %ax
	movw %ax, %es
	jnz .sector_loop
	movw $read_error_msg, %bp  #msg relative address, es is the segment address.
	movw read_error_msg_len, %cx
	movw $0x20, %dx  #row dh:1, col dl:0
	call print
.sector_sucess:
	ret

wait:
	movb $0, %ah
	int $0x16
	ret


msg: .asciz "This is for test 0x13"
msglen: .int . - msg
read_error_msg: .asciz "error read sector"
read_error_msg_len: .int . - read_error_msg	
alert: .asciz "follow is data."
alert_len: .int . - alert	
absTrack: .byte 0
absSector: .byte 1
devNO: .byte 0	
absHead: .byte 0	
headSec: .int 20000
	.org 510, '.' #fill with "." util 510. total need 512, left is follow.
	.word 0xaa55
