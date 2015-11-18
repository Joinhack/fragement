
use qemu for virtual machine.

tools download [gcc](http://crossgcc.rts-software.org/doku.php)

$ qemu-system-i386 -drive file=int0x10.img,index=0,media=disk,format=raw
