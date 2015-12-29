#include "boot.h"
.code16
.text
.global realmode2protect

realmode2protect:
	movl %cs, %eax

	shll $4, %eax
	addl %eax, 1f
	
	.byte	0x66, 0xea
1:.long	pmbridge
	.word	__BOOT_CS

.code32
pmbridge:
	jmp .
