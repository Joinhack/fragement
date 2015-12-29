.code16
.section ".initsec", "ax"

.global _start
_start:
	movw %cs, %ax
	movw %ax, %ds
	movw %ax, %es

	//init stack 4k stack
	mov $0x07E0, %ax
	movw %ax, %ss
	mov $4096, %sp
	
	jmp main
	
