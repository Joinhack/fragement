.code16
.section ".text16", "ax"


.macro SEG_DESC Base, Limit, Attr
	.2byte (\Limit & 0xFFFF)
	.2byte (\Base & 0xFFFF)
	.byte  ((\Base >> 16) & 0xFF)
	.2byte ((\Attr & 0xF0FF) | ((\Limit >> 8) & 0x0F00))
	.byte  ((\Base >> 24) & 0xFF)
.endm

jmp installgdt
TEMPGDT:
	GDT_DESC_NULL: SEG_DESC 0, 0, 0
	GDT_DESC_C32: SEG_DESC 0, 0xFFFF, (0x9A | 0x4000)

.set GDTLEN, (. - GDT_DESC_NULL)	

GDTPTR:
	.word	(GDTLEN - 1)			/* limit */
	.long	0

installgdt:
	cli
	movw %cs, %ax
	movw %ax, %ds
	movw %ax, %gs
	movw %ax, %fs
	movw %ax, %es

	xor %eax, %eax
	xor %ebx, %ebx
	mov %cs, %ax
	shl $4, %eax
	lea TEMPGDT, %bx
	add %ebx, %eax
	movl %eax, (GDTPTR+2)


	lgdtl GDTPTR

	movl	%cr0, %eax
	orl	$1, %eax
	movl	%eax, %cr0

	ljmp $8, $(0x09000 + c32_begin)

.section ".text32", "ax"
.code32
c32:
	jmp .

