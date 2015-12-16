/* os.S
*
* Adrian Huang (adrianhuang0701@gmail.com)
*
* This code is OS context for protected-mode.
*
*/
#include "pm.h"

.code16
.text
jmp os_main

# Segment descritors for GDT
GDT_DESC_NULL: SEG_DESC      0, 0, 0
GDT_DESC_CODE32: SEG_DESC    0, (PECode32Len - 1), (DESC_ATTR_TYPE_CD_ER | DESC_ATTR_D)
GDT_DESC_VIDEO: SEG_DESC     0xB8000, 0xFFFF, (DESC_ATTR_TYPE_CD_RW)

# The length of GDT
.set GdtLen, (. - GDT_DESC_NULL)

# Segment selectors for code segment and video output
.set SegSelectorCode32, (GDT_DESC_CODE32 - GDT_DESC_NULL)
.set SegSelectorVideo,  (GDT_DESC_VIDEO - GDT_DESC_NULL)

# GDTR pointer
GDTPtr:
.2byte (GdtLen - 1)     # Limit field
.4byte 0                 # base field

# real-mode OS code
os_main:
mov %cs, %ax
mov %ax, %ds
mov %ax, %ss
mov %ax, %es


/* Set gdt for code segment */
InitSegDescriptor PE_CODE32, GDT_DESC_CODE32

/* Set GDTR */
xor     %ax, %ax
mov     %cs, %ax
shl     $4, %eax
addl    $GDT_DESC_NULL, %eax
movl     %eax, (GDTPtr + 2)        

/* Enable A20 line */
xor     %ax,   %ax
in      $0x92, %al
or      $2,    %al
out     %al,   $0x92

cli

/* Load the GDT base address and limit from memory into the GDTR register */
lgdt     GDTPtr

/* Enable protect mode */
movl     %cr0, %eax
orl      $1,   %eax
movl     %eax, %cr0

/* Jump to protected-mode OS code */
ljmp     $SegSelectorCode32, $0


# protected-mode OS code
PE_CODE32:
.code32
/* Load Video segment selector */
mov     $(SegSelectorVideo), %ax
mov     %ax, %gs

/* Output the data */
movl    $((80 * 10 + 0) * 2), %edi
movb    $0xC, %ah
movb    $'9', %al
mov     %ax, %gs:(%edi)

jmp .

.set PECode32Len, (. - PE_CODE32)

os_msg:
.ascii "Welcome to OS context!"
.byte     0

.org    0x200, 0x41 # fill characters with 'A'. Sector 2