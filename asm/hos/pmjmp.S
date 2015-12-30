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
	
	movl %cr0, %edx
	orl $1, %edx	
	movl %edx, %cr0

	movl (2f), %ebx
	
	movl $__BOOT_DS, %ecx

	.byte	0x66, 0xea
1:.long	pmbridge
	.word	__BOOT_CS

2:.4byte _end

.text
.code32

pmbridge:
	movl %ecx, %ds
	movl %ecx, %es
	movl %ecx, %fs
	movl %ecx, %gs
	movl %ecx, %ss
	jmpl *%ebx

