#include "kernel.h"
.code32
.text

.global idt_handler_array, idt_handler_array_len

idt_handler_array:
i = 0
.rept IRQLEN
cli
.ifeq (EXCEPTION_ERRCODE_MASK >> i) & 1
push $0		# Dummy error code, to make stack frame uniform
.endif
pushl $i
jmp idt_handler_common
i = i + 1
.endr
.set idt_handler_array_len, (. - idt_handler_array)

idt_handler_common:
pusha                    // Pushes edi,esi,ebp,esp,ebx,edx,ecx,eax

call irq_handler
popa

addl $8, %esp
sti
iret