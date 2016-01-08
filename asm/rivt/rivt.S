
.code16
.section .text
	jmp _start

isr_tick:
	push %ax
	incw tick
	//EOI command: if have no EOI, will no this interrupt again.
	mov $0x20, %al
	out %al, $0x20
	pop %ax
	iret

	tick:.2byte 0
	msg:.ascii "Tick"
	buf:.asciz "        "
.set lbuf, (. - buf)
.set lmsg, (. - msg)
	ten: .2byte 10
_start:
	cli
	movw %cs, %ax
	movw %ax, %ds
	movw %ax, %gs
	movw %ax, %es

	//stack initial
	movw %ax, %ss
	movw $se, %sp

	
	mov $0, %ax
	mov %ax, %es


	//use the same segment 
	movw $isr_tick, %es:0x08*4+0	# write vector's lo-word
	movw %cs, %es:0x08*4+2
	sti

again:
	mov $(buf + lbuf - 1), %di
	movw tick, %ax
	call p2asc


	mov $msg, %si
	mov $lmsg, %cx
	mov $((12*80 + 31)*2), %di
	call print
	
	xor	%ah, %ah		# return keyboard entry
	int	$0x16			# request BIOS service
	jmp	again	


p2asc:
	xor %dx, %dx
	divw ten
	add	$'0', %dl
	movb %dl, (%di)
	dec %di
	or %ax, %ax
	jnz p2asc	
	ret

print:
	mov %es, %bx 
	mov $0xB800, %dx
	mov $2, %ah //color
	.ploop:
	mov %bx, %es
	lodsb %es:(%si)
	mov %dx, %es
	stosw %es:(%di)
	loop .ploop
	mov %bx, %es
	ret
	
.org (510), '.'
.set se, . - 2
.word 0xaa55

