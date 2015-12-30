#! /usr/bin/env sh

ADDR=$(printf "0x%x" $(( $(wc -c setup.img|awk '{print $1}') + 0x9000 )))

cat > kernel.ld << END
OUTPUT_FORMAT("elf32-i386", "elf32-i386", "elf32-i386")
OUTPUT_ARCH(i386)
ENTRY(kstart)

SECTIONS
{
	. = $ADDR;
	.text : {
		* (.text)
	}
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
END