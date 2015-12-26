SECTIONS
{
	.text16 : {
		*(.text16)
	}
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