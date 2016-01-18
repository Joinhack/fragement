#! /usr/bin/env python

import os

size = os.path.getsize("setup.img")

appendChars = [
	[],
	['\xff'],
	['\xfe', '\xff'],
	['\xfd', '\xfe', '\xff']
]

align = size%4
if align != 0:
	size += align
	with open("setup.img", "a") as appendfile:
		for v in appendChars[align]:
			appendfile.write(v)

outvalue='''

OUTPUT_FORMAT("elf32-i386", "elf32-i386", "elf32-i386")
OUTPUT_ARCH(i386)
ENTRY(kstart)

SECTIONS
{
	. = 0x%x;
	._textenrty : AT (0x%x) {
		*(._textenrty)
	}
	.text : {
		* (.text)
	}
	.rodata ALIGN(0x1) : AT (ADDR (.text) + SIZEOF (.text))  {
		*(.rodata) 
	}
	.data : {
		*(.data)
	}
	.bss : {
		*(.bss)
	}
	__end = .;
	/DISCARD/ : {
		*(.MIPS.options)
		*(.options)
		*(.pdr)
		*(.reginfo)
		*(.comment)
		*(.symtab)
		*(.note)
	}
}

'''

size += 0x9000
with open("kernel.ld", "w") as ld:
	ld.write(outvalue%(size, size))
