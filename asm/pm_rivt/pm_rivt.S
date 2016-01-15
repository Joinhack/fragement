
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

dataseg:
tick:.4byte 1
	msg:.ascii "Tick"
	buf:.asciz "       "
.set lbuf, (. - buf)
.set lmsg, (. - msg)
	ten: .2byte 10	
.set datalen, (. - dataseg)

gdt:
	GDT_DESC_NULL: SEG_DESC 0, 0, 0
	GDT_DESC_C32: SEG_DESC 0, (c32len - 1), (0x9A | 0x4000)
	GDT_DESC_DATA: SEG_DESC 0, (datalen - 1), 0x92
	GDT_DESC_VIDEO: SEG_DESC 0xB8000, 0xFFFF, (0x92|0x60)	
	GDT_DESC_STACK1: SEG_DESC 0, (stack1len - 1), (0x92)


.set GdtLen, (. - GDT_DESC_NULL)

.set C32SEL, (GDT_DESC_C32 - GDT_DESC_NULL)
.set DATASEL, (GDT_DESC_DATA - GDT_DESC_NULL)
.set VSEL,  (GDT_DESC_VIDEO - GDT_DESC_NULL)


.set STACK1SEL, (GDT_DESC_STACK1 - GDT_DESC_NULL)


gdtptr:
	.word	(GdtLen - 1)			/* limit */
	.long	0

idtptr:
	.word	(idtlen - 1)			/* limit */
	.long	0	

1:
	cli
	movw %cs, %ax
	movw %ax, %ds
	movw %ax, %gs
	movw %ax, %fs
	movw %ax, %es
	jmp install_gdt

install_gdt:
	// install gdt

	InitSegDescriptor c32, GDT_DESC_C32
	InitSegDescriptor dataseg, GDT_DESC_DATA
	InitSegDescriptor stack1, GDT_DESC_STACK1


	//cs*0x10 + relativeAddr(gdt) == absoluteAddress(gdt)
	xor %eax, %eax
	xor %ebx, %ebx
	mov %cs, %ax
	shl $4, %eax
	mov %eax, %ecx //tmp save

	lea gdt, %bx
	add %ebx, %eax
	movl %eax, (gdtptr+2)

	mov %ecx, %eax
	lea idt, %bx
	add %ebx, %eax
	movl %eax, (idtptr+2)

	movw $(isr_tick - c32), idt+0x08*8+0	# write vector's lo-word
	movw $C32SEL, idt + 0x08*8+2
	movw	$0x8e00, idt + 0x08*8+4 //0x8e  32bits interrupt.
	movw	$0x0000, idt + 0x08*8+6

	lgdtl gdtptr
	lidtl idtptr

	//go to prot_model
	movl	%cr0, %eax
	orl	$1, %eax
	movl	%eax, %cr0

	
	mov $DATASEL,  %ax
	mov %ax, %ds

	mov $VSEL, %ax
	mov %ax, %gs

	mov $STACK1SEL, %ax
	mov %ax, %ss

	mov $stack1len, %esp

	mov $0xfe, %al
	out	%al, $0x21 		# write Master-PIC mask
	mov $0xff, %al
	out	%al, $0xA1
	sti


	ljmp $C32SEL, $(main - c32) //jmp to main

.code32

c32:

isr_tick:
	pushl %eax
	incl tick - dataseg
	//EOI command: if have no EOI, will no this interrupt again.
	mov $0x20, %al
	out %al, $0x20
	popl %eax
	iret
.set isr_ticklen, (. - isr_tick)



main:
	mov $(buf - dataseg + lbuf - 1), %di
	movl tick - dataseg, %eax
	call p2asc

	xor %esi, %esi
	xor %edi, %edi
	mov $(msg - dataseg), %esi
	mov $((80 * 11 + 0) * 2), %edi

	
	#mov $2, %ah
	movb tick - dataseg, %ah //color changed
	.gdt:
	lodsb
	andb %al, %al
	jz useldt
	mov %ax, %gs:(%edi)
	addl $2, %edi
	jmp .gdt

useldt:
	jmp main

p2asc:
	xor %dx, %dx
	divl ten - dataseg
	add	$'0', %dl
	movb %dl, (%di)
	dec %di
	or %ax, %ax
	jnz p2asc	
	ret

.set c32len, (. - c32)	


idt:
	.space 8*256, 0
.set idtlen, (. - idt)

.align 4
stack1:
	.space 128, 0
.set stack1len, (. - stack1)



