
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
	prepare_msg:.asciz "ready install gdt...\r\n"
	gdt_msg:.asciz "gdt welcome ..."
	ldt_msg:.asciz "ldt welcome ..."

.set datalen, (. - dataseg)

gdt:
	GDT_DESC_NULL: SEG_DESC 0, 0, 0
	GDT_DESC_C32: SEG_DESC 0, (c32len - 1), (0x9A | 0x4000)
	GDT_DESC_DATA: SEG_DESC 0, (datalen - 1), 0x92
	GDT_DESC_VIDEO: SEG_DESC 0xB8000, 0xFFFF, 0x92
	GDT_LDT_ENTRY: SEG_DESC  0, (ldtlen - 1), 0x82

.set GdtLen, (. - GDT_DESC_NULL)	

.set C32SELECTOR, (GDT_DESC_C32 - GDT_DESC_NULL)
.set DATASELECTOR, (GDT_DESC_DATA - GDT_DESC_NULL)
.set VSELECTOR,  (GDT_DESC_VIDEO - GDT_DESC_NULL)
.set LDTSELCTOR,  (GDT_LDT_ENTRY - GDT_DESC_NULL)

ldt:
	LDT_DESC_C32: SEG_DESC 0, (lc32len - 1), (0x9A | 0x4000)

.set ldtlen, (. - ldt)
.set LDTC32SELECTOR, (LDT_DESC_C32 - ldt + 1<<2)

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

	movw $prepare_msg, %si
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
	InitSegDescriptor dataseg, GDT_DESC_DATA
	InitSegDescriptor ldt, GDT_LDT_ENTRY
	InitSegDescriptor lc32, LDT_DESC_C32

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

	ljmp $C32SELECTOR, $0

.code32
c32:
	mov $DATASELECTOR,  %ax
	mov %ax, %ds

	mov $VSELECTOR, %ax
	mov %ax, %gs

	xor %esi, %esi
	xor %edi, %edi
	mov $(gdt_msg - dataseg), %esi
	mov $((80 * 10 + 0) * 2), %edi
	
	mov $1, %ah
	.gdt:
	lodsb
	andb %al, %al
	jz useldt
	inc %ah
	mov %ax, %gs:(%edi)
	addl $2, %edi
	jnz .gdt

useldt:
	mov $LDTSELCTOR, %ax
	lldt %ax
	ljmp $LDTC32SELECTOR, $0

.set c32len, ( . - c32 )

lc32:
	mov $DATASELECTOR,  %ax
	mov %ax, %ds

	mov $VSELECTOR, %ax
	mov %ax, %gs

	xor %esi, %esi
	xor %edi, %edi
	mov $(ldt_msg - dataseg), %esi
	mov $((80 * 11 + 0) * 2), %edi

	mov $20, %ah
	.ldt:
	lodsb
	andb %al, %al
	jz .end
	inc %ah
	mov %ax, %gs:(%edi)
	addl $2, %edi
	jnz .ldt

	.end:
	jmp .

.set lc32len, ( . - lc32 )

.org (510), '.'
.word 0xaa55

	
	

