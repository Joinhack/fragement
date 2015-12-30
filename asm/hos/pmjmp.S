#include "boot.h"
.code16
.section ".initsec", "ax"
.global realmode2protect

realmode2protect:
	movl %cs, %eax

	shll $4, %eax
	addl %eax, 1f
	
	
	movl %cr0, %edx
	orl $1, %edx	
	movl %edx, %cr0
	
	movl $__BOOT_DS, %ecx

	.byte	0x66, 0xea
1:.long	pmbridge
	.word	__BOOT_CS

.text
.code32
.extern _end
pmbridge:
	movl	%ecx, %ds
	movl	%ecx, %es
	movl	%ecx, %fs
	movl	%ecx, %gs
	movl	%ecx, %ss
.section ".bootendsec", "aw"	
2:.word _end
