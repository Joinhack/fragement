/**
 * link use this for relative address. example in Makefile ld use parameter -Tdata 0
 *	movw $begin, %ax now ax is 0
 * if -Tdata 0x7c0 $begin, %ax now ax is 0x7c0
 */

#define SADDR 0x7c00
#define MEMORY_CPU_CR0_PE_ON 0x1

.code16
.section ".mytext", "ax"

begin:
	jmp _start

	ready_msg:.asciz "ready install gdt...\r\n"
	install_msg_success:.asciz "install gdt success\r\n"

.global _start
_start:
	cli
	movw $0x7c0, %ax
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


	.p2align	5	/* force 4-byte alignment, mean 1<<5 32 bits  */
gdt:
	.word	0, 0
	.byte	0, 0, 0, 0

	/* -- code segment --
	 * base = 0x00000000, limit = 0xFFFFF (4 KiB Granularity), present
	 * type = 32bit code execute/read, DPL = 0
	 */
	.word	0xFFFF, 0
	.byte	0, 0x9A, 0xCF, 0

	/* -- data segment --
	 * base = 0x00000000, limit 0xFFFFF (4 KiB Granularity), present
	 * type = 32 bit data read/write, DPL = 0
	 */
	.word	0xFFFF, 0
	.byte	0, 0x92, 0xCF, 0

	/* -- 16 bit real mode CS --
	 * base = 0x00000000, limit 0x0FFFF (1 B Granularity), present
	 * type = 16 bit code execute/read only/conforming, DPL = 0
	 */
	.word	0xFFFF, 0
	.byte	0, 0x9E, 0, 0

	/* -- 16 bit real mode DS --
	 * base = 0x00000000, limit 0x0FFFF (1 B Granularity), present
	 * type = 16 bit data read/write, DPL = 0
	 */
	.word	0xFFFF, 0
	.byte	0, 0x92, 0, 0


	.p2align 5 //1<<5
/* this is the GDT descriptor */
gdtdesc:
	.word	0x27			/* limit */
	.long	( SADDR + gdt	)


install_gdt:
	// install gdt
	cli

	/* load the GDT register */
	lgdtl	%cs:(0x7c00 + gdtdesc)
	//go to prot_model
	movl	%cr0, %eax
	orl	$MEMORY_CPU_CR0_PE_ON, %eax
	movl	%eax, %cr0
	sti

	xorw	%ax, %ax
	movw	%ax, %ds
	jmp $1, $(SADDR + test32)

.code32
test32:
	movl $0, %eax

	
	.org 510, '.'
	.word 0xaa55


	
	

