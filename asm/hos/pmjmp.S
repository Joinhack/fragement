#include "boot.h"
.code16
.section ".initsec", "ax"
.global realmode2protect
.extern _end
realmode2protect:
	movl %cs, %eax
	shll $4, %eax
	addl %eax, 1f
	addl %eax, 2f


	movl 2f, %eax
	movl %eax, %ebx

	and $0x3, %eax
	cmp $0x0, %eax
	je .cm
	add %eax, %ebx

	.cm:
	movl %cr0, %edx
	orl $1, %edx	
	movl %edx, %cr0
	
	movl $__BOOT_DS, %ecx

	.byte	0x66, 0xea
1:.long	pmbridge
	.word	__BOOT_CS
2:.long _end

.text
.code32

pmbridge:
	cld
	movl %ecx, %ds
	movl %ecx, %es
	movl %ecx, %fs
	movl %ecx, %gs
	movl %ecx, %ss
	jmpl *%ebx
