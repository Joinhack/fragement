/**
 * link use this for relative address. example in Makefile ld use parameter -Tdata 0
 *	movw $begin, %ax now ax is 0
 * if -Tdata 0x7c0 $begin, %ax now ax is 0x7c0
 */

#define SADDR 0x7c00
#define MEMORY_CPU_CR0_PE_ON 0x1

.macro SEG_DESC Base, Limit, Attr
.2byte (\Limit & 0xFFFF)
.2byte (\Base & 0xFFFF)
.byte  ((\Base >> 16) & 0xFF)
.2byte ((\Attr & 0xF0FF) | ((\Limit >> 8) & 0x0F00))
.byte  ((\Base >> 24) & 0xFF)
.endm

.macro InitSegDescriptor OFFSET GDT_SEG_ADDR
xor     %ax, %ax
mov     %cs, %ax
shl     $4, %eax
addl    $(\OFFSET), %eax
movw    %ax, (\GDT_SEG_ADDR + 2)
shr     $16, %eax
movb    %al, (\GDT_SEG_ADDR + 4)
movb    %ah, (\GDT_SEG_ADDR + 7)
.endm

.code16
.section ".mytext", "ax"


begin:
	jmp _start

	ready_msg:.asciz "ready install gdt...\r\n"
	install_msg_success:.asciz "install gdt success\r\n"

gdt:
	GDT_DESC_NULL: SEG_DESC 0, 0, 0
	GDT_DESC_C32: SEG_DESC 0, (c32len - 1), (0x9A | 0x4000)

.set GdtLen, (. - GDT_DESC_NULL)	

.set c32selector, (GDT_DESC_C32 - GDT_DESC_NULL)

gdtdesc:
	.word	(GdtLen - 1)			/* limit */
	.long	0


	



.global _start
_start:
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
	call install_gdt

	
loop:	
	call wait
	jmp loop


print:
	lodsb %ds:(%si)
	or %al, %al
	jz .print_done
	movb $0x0e, %ah //ah function no. 0x13
	int $0x10
	jmp print
	.print_done:
	ret


wait:
	movb $0, %ah
	int $0x16
	ret



install_gdt:
	// install gdt
	cli

	InitSegDescriptor c32, GDT_DESC_C32
	/* load the GDT register */
	xor     %ax, %ax
	mov     %cs, %ax
	shl     $4, %eax
	addl    $GDT_DESC_NULL, %eax
	movl     %eax, (gdtdesc + 2) 

	xor     %ax,   %ax
	in      $0x92, %al
	or      $2,    %al
	out     %al,   $0x92

	lgdtl gdtdesc
	//go to prot_model
	movl	%cr0, %eax
	orl	$MEMORY_CPU_CR0_PE_ON, %eax
	movl	%eax, %cr0

	xorw	%ax, %ax
	movw	%ax, %ds
	ljmp $c32selector, $0

.code32
c32:
	movl $0, %eax
	jmp c32

.set c32len, ( . - c32 )

	.org 510, '.'
	.word 0xaa55

	
	

