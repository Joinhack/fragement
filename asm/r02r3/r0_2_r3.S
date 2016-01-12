
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
	ldt_msg:.asciz "ldt welcome ..."
	cgw_msg:.asciz "r3 -> r0  ..."
.set datalen, (. - dataseg)

r3dataseg:
	r3_msg:.asciz "r3 welcome ..."
.set r3datalen, (. - r3dataseg)

gdt:
	GDT_DESC_NULL: SEG_DESC 0, 0, 0
	GDT_DESC_C32: SEG_DESC 0, (c32len - 1), (0x9A | 0x4000)
	GDT_DESC_DATA: SEG_DESC 0, (datalen - 1), 0x92
	GDT_DESC_VIDEO: SEG_DESC 0xB8000, 0xFFFF, (0x92|0x60)
	GDT_LDT_ENTRY: SEG_DESC 0, (ldtlen - 1), 0x82
	GDT_DES_CGC32: SEG_DESC 0, (cgc32len - 1), (0x9A | 0x4000)

	GDT_DES_R3CODE: SEG_DESC 0, (r3codelen - 1), (0x9A | 0x4000| 0x60)  //0x60 is set DPL

	GDT_DESC_STACKR0: SEG_DESC 0, (stackr0len - 1), (0x92)
	GDT_DESC_STACKR3: SEG_DESC 0, (stackr3len - 1), (0x92|0x60)
	GDT_DESC_R3DATA: SEG_DESC 0, (r3datalen - 1), 0x92|0x60
	GDT_CG: CALL_GATE CGCODESEL, 0, 0, 0x8C|0x60

	GDT_DESC_TSS: SEG_DESC 0, (tsslen - 1), (0x89)

.set GdtLen, (. - GDT_DESC_NULL)	

.set C32SEL, (GDT_DESC_C32 - GDT_DESC_NULL)
.set DATASEL, (GDT_DESC_DATA - GDT_DESC_NULL)
.set VSEL,  (GDT_DESC_VIDEO - GDT_DESC_NULL)|0x3
.set LDTSEL,  (GDT_LDT_ENTRY - GDT_DESC_NULL)
.set CGCODESEL,  (GDT_DES_CGC32 - GDT_DESC_NULL)
.set GWSEL,  (GDT_CG - GDT_DESC_NULL)|0x3
.set R3CODESEL, (GDT_DES_R3CODE - GDT_DESC_NULL) | 0x3 //RPL: 0x3
.set R3DATASEL, (GDT_DESC_R3DATA - GDT_DESC_NULL) | 0x3 //RPL: 0x3

.set STACK0SEL, (GDT_DESC_STACKR0 - GDT_DESC_NULL)
.set STACK3SEL, (GDT_DESC_STACKR3 - GDT_DESC_NULL)| 0x3

.set TSSSEL, (GDT_DESC_TSS - GDT_DESC_NULL)

ldt:
	LDT_DESC_C32: SEG_DESC 0, (lc32len - 1), (0x9A | 0x4000)

.set ldtlen, (. - ldt)
.set LDTC32SEL, (LDT_DESC_C32 - ldt + 1<<2) //TI bit must be 1.

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
	InitSegDescriptor ldt, GDT_LDT_ENTRY
	InitSegDescriptor lc32, LDT_DESC_C32
	InitSegDescriptor cgc32, GDT_DES_CGC32

	InitSegDescriptor stackr3, GDT_DESC_STACKR3
	InitSegDescriptor stackr0, GDT_DESC_STACKR0
	InitSegDescriptor r3code, GDT_DES_R3CODE
	InitSegDescriptor r3dataseg, GDT_DESC_R3DATA
	InitSegDescriptor tss, GDT_DESC_TSS
	
	movl $stackr0len, tss+4
	movl $STACK0SEL, tss+8


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

	mov $STACK0SEL, %ax
	mov %ax, %ss

	mov $stackr0len, %esp

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
	mov $LDTSEL, %ax
	lldt %ax

	lcall $LDTC32SEL, $0


	mov $TSSSEL, %ax
	ltr %ax

	pushl	$(STACK3SEL)
	pushl $stackr3len
	pushl $R3CODESEL

	pushl $0
	lret

.set c32len, ( . - c32 )


r3code:
	mov $R3DATASEL,  %ax
	mov %ax, %ds

	mov $VSEL, %ax
	mov %ax, %gs

	mov $STACK3SEL, %ax
	mov %ax, %ss

	mov $stackr3len, %esp

	xor %esi, %esi
	xor %edi, %edi
	mov $(r3_msg - r3dataseg), %esi
	mov $((80 * 12 + 0) * 2), %edi

	mov $2, %ah
	.r3code:
	lodsb
	andb %al, %al
	jz .r3codeend
	mov %ax, %gs:(%edi)
	addl $2, %edi
	jmp .r3code

	.r3codeend:
	lcall $GWSEL, $0
.set r3codelen, (. - r3code)	


lc32:
	
	mov $DATASEL,  %ax
	mov %ax, %ds

	mov $VSEL, %ax
	mov %ax, %gs

	xor %esi, %esi
	xor %edi, %edi
	mov $(ldt_msg - dataseg), %esi
	mov $((80 * 11 + 0) * 2), %edi

	mov $20, %ah
	.ldt:
	lodsb
	andb %al, %al
	jz .cgw
	inc %ah
	mov %ax, %gs:(%edi)
	addl $2, %edi
	jmp .ldt

.cgw:
	lret

.set lc32len, ( . - lc32 )	

cgc32:
	mov $DATASEL, %ax
	mov %ax, %ds

	mov $VSEL, %ax
	mov %ax, %gs

	xor %esi, %esi
	xor %edi, %edi
	mov $(cgw_msg - dataseg), %esi
	mov $((80 * 13 + 0) * 2), %edi

	mov $3, %ah
	.cgc32:
	lodsb
	andb %al, %al
	jz .cgc32end
	inc %ah
	mov %ax, %gs:(%edi)
	addl $2, %edi
	jmp .cgc32

	.cgc32end:
	jmp .
.set cgc32len, ( . - cgc32 )


.align 4
stackr0:
	.space 512, 0
.set stackr0len, (. - stackr0)

stackr3:
	.space 512, 0
.set stackr3len, (. - stackr3)

tss:
	.space 104, 0
.set tsslen, (. - tss) 
