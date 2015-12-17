
.macro SEG_DESC Base, Limit, Attr
	.2byte (\Limit & 0xFFFF)
	.2byte (\Base & 0xFFFF)
	.byte  ((\Base >> 16) & 0xFF)
	.2byte ((\Attr & 0xF0FF) | ((\Limit >> 8) & 0x0F00))
	.byte  ((\Base >> 24) & 0xFF)
.endm

.macro InitSegDescriptor OFFSET GDT_SEG_ADDR
	xor %ax, %ax
	mov %cs, %ax
	shl $4, %eax
	addl $(\OFFSET), %eax
	movw %ax, (\GDT_SEG_ADDR + 2)
	shr $16, %eax
	movb %al, (\GDT_SEG_ADDR + 4)
	movb %ah, (\GDT_SEG_ADDR + 7)
.endm

.code16
.section .text
	jmp 1f

	ready_msg:.asciz "ready install gdt...\r\n"
	install_msg_success:.asciz "install gdt success\r\n"

gdt:
	GDT_DESC_NULL: SEG_DESC 0, 0, 0
	GDT_DESC_C32: SEG_DESC 0, (c32len - 1), (0x9A | 0x4000)
	GDT_DESC_VIDEO: SEG_DESC     0xB8000, 0xFFFF, (0x92)

.set GdtLen, (. - GDT_DESC_NULL)	

.set c32selector, (GDT_DESC_C32 - GDT_DESC_NULL)
.set vselector,  (GDT_DESC_VIDEO - GDT_DESC_NULL)

gdtptr:
	.word	(GdtLen - 1)			/* limit */
	.long	0

1:
	cli
	movw %cs, %ax
	movw %ax, %ds
	movw %ax, %gs
	movw %ax, %fs
	movw %ax, %es

	//stack alloc
	movw 0xf000, %ax
	movw %ax, %ss
	movw $0xffff, %sp
	sti

	movw $ready_msg, %si
	call print
	jmp install_gdt




print:
	lodsb %ds:(%si)
	or %al, %al
	jz .print_done
	movb $0x0e, %ah //ah function no. 0x13
	int $0x10
	jmp print
	.print_done:
	ret


install_gdt:
	// install gdt
	cli

	InitSegDescriptor c32, GDT_DESC_C32

	//cs*0x10 + relativeAddr(gdt) == absoluteAddress(gdt)
	xor %eax, %eax
	xor %ebx, %ebx
	mov %cs, %ax
	shr $4, %eax
	lea gdt, %bx
	add %ebx, %eax
	movl %eax, (gdtptr+2)

	lgdtl gdtptr
	//go to prot_model
	movl	%cr0, %eax
	orl	$1, %eax
	movl	%eax, %cr0

	ljmp $c32selector, $0

.code32
c32:
	mov $(vselector), %ax
	mov %ax, %gs
	movb $'a', %al
	movb $0x1, %ah
	.loop:
	/* Output the data */
	mov $((90 * 10 + 0) * 2), %edi
	inc %al
	inc %ah
	mov %ax, %gs:(%edi)
	jmp .loop

.set c32len, ( . - c32 )

.org (510), '.'
.word 0xaa55

	
	

