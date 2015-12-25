/* boot_loader.S
*/

.code16
.text

.set     BOOT_SEG,     0x07C0    /* starting code segment (CS) of boot loader */
.set     OS_SEG,       0x0900    /* code segment address of OS entry point */
.set     OS_OFFSET,    0x0000    /* the offset address of OS entry point */

.global _start
_start:
  # FAT12 file system format
 jmp       start_prog         # jmp instruction

.byte     0x90
.ascii    "Joinhack"         # OEM name (8 bytes)
.word     512                # Bytes per sector
.byte     1                  # Sector per cluster
.word     1                  # Reserved sector count: should be 1 for FAT12
.byte     2                  # Number of file allocation tables.
.word     224                # Maximum number of root directory entries.
.word     2880               # Total sectors
.byte     0xf0               # Media descriptor:
.word     9                  # Sectors per File Allocation Table
.word     18                 # Sectors per track
.word     2                  # Number of heads
.long     0                  # Count of hidden sectors
.long     0                  # Total sectors
.byte     0                  # Physical driver number
.byte     0                  # Reserved
.byte     0x29               # Extended boot signature
.long     0x12345678         # Serial Number
.ascii    "HELLO-OS   "      # Volume Label
.ascii    "FAT12   "         # FAT file system type
KERNSECTORS:
.byte     2
.fill     18, 1, 0           # fill 18 characters with zero

start_prog:
# initialize the register with cs register
movw    %cs, %ax
movw    %ax, %ds
movw    %ax, %es
movw    %ax, %ss
xorw    %sp, %sp

cld                     # clear direction flag
sti                     # set interrupt flag

# The following code is loaded three sectors (2-4th sectors from boot.bin)
# into the physical memory 0x8000-0x85FF.
movw    $OS_SEG,     %ax
mov     %ax,         %es  # ES:BX-> destination buffer address pointer
movw    $OS_OFFSET,  %bx
movb    $2,          %cl  # sector


cont:
movb     KERNSECTORS, %ah  # Read sectors from drive
movb     $0x1,  %al  # Sectors to read count
movb     $0x0,  %ch  # track
movb     $0x0,  %dh  # head
movb     $0,    %dl  # drive

int      $0x13       # trigger a interrupt 0x13 service
jc       fail        # the clear flag is set if the operation is failed

mov      %es,   %ax
addw     $0x20, %ax  # move to the next sector
movw     %ax,   %es  # move to the next sector
incb     %cl

cmpb     $3, %cl     # has finished reading 3 sectors?
jbe      cont        # continue to read the sector

jmp      os_entry    # jump to OS entry point

fail:
movw     $err_msg, %si
fail_loop:
lodsb
andb     %al, %al
jz       end
movb     $0x0e, %ah
int      $0x10
jmp      fail_loop


os_entry:
ljmp $OS_SEG, $OS_OFFSET  # jump to os context

end:
 hlt
 jmp end

err_msg:
.ascii "Reading sectors operation is failed!"
.byte     0

.org 0x1FE, 0x41 # fill the rest of characters with zero until the 254th character

 # Boot sector signature
.byte     0x55
.byte     0xaa
