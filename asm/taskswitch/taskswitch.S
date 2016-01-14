
.macro SEG_DESC Base, Limit, Attr
	.2byte (\Limit & 0xFFFF)
	.2byte (\Base & 0xFFFF)
	.byte  ((\Base >> 16) & 0xFF)
	.2byte ((\Attr & 0xF0FF) | ((\Limit >> 8) & 0x0F00))
	.byte  ((\Base >> 24) & 0xFF)
.endm

.macro CALL_GATE SegSelector, Offset, ParamCount, Attr
  .2byte (\Offset & 0xFFFF)
  .2byte (\SegSelector)
  .byte  (\ParamCount)
  .byte  (\Attr)
  .2byte ((\Offset >> 16) & 0xFFFF)
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
	gdt_msg:.asciz "gdt welcome ..."
	ldt1_msg:.asciz "ldt1 welcome ..."
	ldt2_msg:.asciz "ldt2 welcome ..."
.set datalen, (. - dataseg)

gdt:
	GDT_DESC_NULL: SEG_DESC 0, 0, 0
	GDT_DESC_C32: SEG_DESC 0, (c32len - 1), (0x9A | 0x4000)
	GDT_DESC_DATA: SEG_DESC 0, (datalen - 1), 0x92
	GDT_DESC_VIDEO: SEG_DESC 0xB8000, 0xFFFF, (0x92|0x60)
	GDT_LDT1: SEG_DESC 0, (ldt1len - 1), 0x82
	GDT_LDT2: SEG_DESC 0, (ldt2len - 1), 0x82
	
	GDT_DESC_STACK1: SEG_DESC 0, (stack1len - 1), (0x92)
	GDT_DESC_STACK2: SEG_DESC 0, (stack2len - 1), (0x92)
	GDT_DESC_TSS1: SEG_DESC 0, (tss1len - 1), (0x89|0x1)
	GDT_DESC_TSS2: SEG_DESC 0, (tss2len - 1), (0x89|0x1)


.set GdtLen, (. - GDT_DESC_NULL)

.set C32SEL, (GDT_DESC_C32 - GDT_DESC_NULL)
.set DATASEL, (GDT_DESC_DATA - GDT_DESC_NULL)
.set VSEL,  (GDT_DESC_VIDEO - GDT_DESC_NULL)
.set LDT1SEL,  (GDT_LDT1 - GDT_DESC_NULL)
.set LDT2SEL,  (GDT_LDT2 - GDT_DESC_NULL)


.set STACK1SEL, (GDT_DESC_STACK1 - GDT_DESC_NULL)
.set STACK2SEL, (GDT_DESC_STACK2 - GDT_DESC_NULL)

.set TSS1SEL, (GDT_DESC_TSS1 - GDT_DESC_NULL)
.set TSS2SEL, (GDT_DESC_TSS2 - GDT_DESC_NULL)

ldt1:
	LDT1_DESC_C32: SEG_DESC 0, (ldt1codelen - 1), (0x9A | 0x4000)

.set ldt1len, (. - ldt1)
.set LDT1C32SEL, (0 + 1<<2) //TI bit must be 1.

ldt2:
	LDT2_DESC_C32: SEG_DESC 0, (ldt2codelen - 1), (0x9A | 0x4000)

.set ldt2len, (. - ldt2)
.set LDT2C32SEL, (0 + 1<<2) //TI bit must be 1.

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

	jmp install_gdt

install_gdt:
	// install gdt


	InitSegDescriptor c32, GDT_DESC_C32
	InitSegDescriptor dataseg, GDT_DESC_DATA
	InitSegDescriptor ldt1, GDT_LDT1
	InitSegDescriptor ldt2, GDT_LDT2

	InitSegDescriptor stack1, GDT_DESC_STACK1
	InitSegDescriptor stack2, GDT_DESC_STACK2
	InitSegDescriptor tss1, GDT_DESC_TSS1
	InitSegDescriptor tss2, GDT_DESC_TSS2

	InitSegDescriptor ldt1code, LDT1_DESC_C32
	InitSegDescriptor ldt2code, LDT2_DESC_C32
	
	movl $stack1len, tss1+4
	movl $STACK1SEL, tss1+8

	//task2 init
	movl $stack2len, tss2+32
	movl $STACK2SEL, tss2+80

	movl $0, tss2+32
	movl $LDT2C32SEL, tss2+76
	movl $LDT2SEL, tss2+96

	movl $VSEL, tss2+92
	movl $DATASEL, tss2+84
	//end task2 init


	//cs*0x10 + relativeAddr(gdt) == absoluteAddress(gdt)
	xor %eax, %eax
	xor %ebx, %ebx
	mov %cs, %ax
	shl $4, %eax
	lea gdt, %bx
	add %ebx, %eax
	movl %eax, (gdtptr+2)

	lgdtl gdtptr
	//go to prot_model
	movl	%cr0, %eax
	orl	$1, %eax
	movl	%eax, %cr0

	ljmp $C32SEL, $0

.code32
c32:
	mov $DATASEL,  %ax
	mov %ax, %ds

	mov $VSEL, %ax
	mov %ax, %gs

	mov $STACK1SEL, %ax
	mov %ax, %ss

	mov $stack1len, %esp

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
	jmp .gdt

useldt:
	mov $LDT1SEL, %ax
	lldt %ax

	lcall $LDT1C32SEL, $0
	jmp .

.set c32len, ( . - c32 )

ldt2code:
	xor %esi, %esi
	xor %edi, %edi
	mov $(ldt2_msg - dataseg), %esi
	mov $((80 * 12 + 0) * 2), %edi

	mov $3, %ah
	.ldt2code:
	lodsb
	andb %al, %al
	jz .ldt2end
	inc %ah
	mov %ax, %gs:(%edi)
	addl $2, %edi
	jmp .ldt2code

	.ldt2end:
	jmp .
.set ldt2codelen, ( . - ldt2code )


ldt1code:
	
	mov $DATASEL,  %ax
	mov %ax, %ds

	mov $VSEL, %ax
	mov %ax, %gs

	xor %esi, %esi
	xor %edi, %edi
	mov $(ldt1_msg - dataseg), %esi
	mov $((80 * 11 + 0) * 2), %edi

	mov $20, %ah
	.ldt1code:
	lodsb
	andb %al, %al
	jz .ldt1final
	inc %ah
	mov %ax, %gs:(%edi)
	addl $2, %edi
	jmp .ldt1code

.ldt1final:
	lcall $TSS2SEL, $0

.set ldt1codelen, ( . - ldt1code )	




.align 4
stack1:
	.space 512, 0
.set stack1len, (. - stack1)

stack2:
	.space 512, 0
.set stack2len, (. - stack2)

tss1:
	.space 104, 0
.set tss1len, (. - tss1) 

tss2:
	.space 104, 0
.set tss2len, (. - tss2) 
