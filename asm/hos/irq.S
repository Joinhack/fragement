#include "kernel.h"
.code32
.text

.global idt_handler_array, idt_handler_array_len

idt_handler_array:
i = 0
.rept IRQLEN
pushl $i
jmp idt_handler_common
i = i + 1
.endr
.set idt_handler_array_len, (. - idt_handler_array)

idt_handler_common:
call irq_handler
addl $4, %esp

iret