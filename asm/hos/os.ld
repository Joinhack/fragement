OUTPUT_FORMAT("elf32-i386", "elf32-i386", "elf32-i386")
OUTPUT_ARCH(i386)
ENTRY(_start)

SECTIONS
{
	. = 0;
	.initsec : {
		*(.initsec)
	}
	.text32 : {
		*(.text32)
	}
	. = ALIGN(16);
	.rodata : { 
		*(.rodata*) 
	}
	.data : {
		*(.data)
	}
	.bss : {
		*(.bss)
	}
	
	.bootendsec : {
		*(.bootendsec)
	}
	_end = .;
	/DISCARD/ : {
		*(.MIPS.options)
		*(.options)
		*(.pdr)
		*(.reginfo)
		*(.comment)
		*(.note)
	}
}