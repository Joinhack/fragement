
.code16
.section .text
	jmp 1f

	buf:.fill 10
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
	movw $0x510, %sp
	int $0x12 //result in ax

	lea buf, %di
p2asc:
	xor %dx, %dx
	divw ten
	add	$'0', %dl
	movb %dl, (%di)
	inc %di
	or %ax, %ax
	jnz p2asc
	

	lea buf, %si
	call print

	lea suffix, %si
	call print
	

	mov	$0x00, %ah		# get_keystroke
	int	$0x16			# invoke BIOS service
	

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
