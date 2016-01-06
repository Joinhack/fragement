
.code16
.section .text
	ljmp $0x7c0, $1f

	buf:.fill 10
.set lbuf, . - buf
	.byte 0
	suffix:.asciz "KB memory \r\n"
	ten: .2byte 10
1:
	cli
	movw %cs, %ax
	movw %ax, %ds
	movw %ax, %gs
	movw %ax, %fs
	movw %ax, %es

	movw %ax, %ss
	movw $500, %sp


	int $0x12 //result in ax

	mov $(buf + lbuf - 1), %di
	call p2asc

	mov %di, %si
	add $1, %si
	call print

	lea suffix, %si
	call print

	call get_memory_size

	mov $(buf + lbuf - 1), %di
	call p2asc

	mov %di, %si
	add $1, %si
	call print

	lea suffix, %si
	call print


	mov	$0x00, %ah		# get_keystroke
	int	$0x16			# invoke BIOS service
get_memory_size: //address 0x413 for memory size
	push %ds
	mov $0x0040, %ax
	mov %ax, %ds
	mov %ds:0x13, %ax
	pop %ds
	ret

p2asc:
	xor %dx, %dx
	divw ten
	add	$'0', %dl
	movb %dl, (%di)
	dec %di
	or %ax, %ax
	jnz p2asc	
	ret

print:
	lodsb %ds:(%si)
	or %al, %al
	jz .print_done
	movb $0x0e, %ah //ah function no. 0x13
	int $0x10
	jmp print
	.print_done:
	ret
	
.org (510), '.'
.word 0xaa55
