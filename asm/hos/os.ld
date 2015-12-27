SECTIONS
{
	.text16 : {
		*(.text16)
	}
	c32_begin = .;
	.text32 : {
		*(.text32)
	}
	.data : {
		*(.data)
	}
	/DISCARD/ : {
		*(.MIPS.options)
		*(.options)
		*(.pdr)
		*(.reginfo)
		*(.comment)
		*(.note)
	}
}