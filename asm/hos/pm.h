/* pm.h
*
*/


.macro SEG_DESC Base, Limit, Attr
.2byte (\Limit & 0xFFFF)
.2byte (\Base & 0xFFFF)
.byte  ((\Base >> 16) & 0xFF)
.2byte ((\Attr & 0xF0FF) | ((\Limit >> 8) & 0x0F00))
.byte  ((\Base >> 24) & 0xFF)
.endm

.macro InitSegDescriptor OFFSET GDT_SEG_ADDR
xor     %ax, %ax
mov     %cs, %ax
shl     $4, %eax
addl    $(\OFFSET), %eax
movw    %ax, (\GDT_SEG_ADDR + 2)
shr     $16, %eax
movb    %al, (\GDT_SEG_ADDR + 4)
movb    %ah, (\GDT_SEG_ADDR + 7)

.endm

.set DESC_ATTR_TYPE_LDT,         0x82     /* LDT Segment                    */
.set DESC_ATTR_TYPE_CD_ER,       0x9A     /* Code segment with Execute/Read */
.set DESC_ATTR_TYPE_CD_E,        0x98     /* Code segment with Execute Only */
.set DESC_ATTR_TYPE_CD_RW,       0x92     /* Data segment with R/W          */
.set DESC_ATTR_D,                0x4000   /* 32-bit segment                 */

/* Selector Attribute */
.set SA_TIL,      0x4
.set SA_RPL0,     0x0
.set SA_RPL1,     0x1
.set SA_RPL2,     0x2
.set SA_RPL3,     0x3