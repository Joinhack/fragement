SECTIONS
{
	. = 0x7c00;
	.text : { *(.text ) }
	. = 0x0;
	.data : { *(.data ) }
}

/**
SECTIONS
{
	. = 0x7c00;
	.text . : { *(.text ) }
	. = 0x0;
	.data . : { *(.data ) }
}
*/

/**
SECTIONS
{
	.text 0x7c00 : { *(.text ) }
	.data 0x0 : { *(.data ) }
}
*/