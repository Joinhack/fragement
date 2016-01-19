#include "kernel.h"

static u32 lines = 0;
static u32 cols = 0;

static u16 *vga = (u16*)0xB8000;

static void scroll() {
	u8 attr = 0x0;
	u16 v = ' '&(attr<<0x8);
	if(lines >= 25) {
		lines = 24; //set last line
		int i;
		for(i = 0; i < lines*80; i++) {
			vga[i] = vga[i+80];
		}
		for(i = lines*80; i < 25*80; i++) {
			vga[i] = v;
		}
	}
}

void screen_clear() {
	int i;
	u8 attr = 0x0;
	u16 v = ' '&(attr<<0x8);
	for(i = 0; i <= 25*80; i++) {
		vga[i] = v;
	}
}


void put(char c) {
	u8 attr = (0x2&0x0f);
	u16 v = (attr<<8)&0xff00;
	switch(c) {
	case 0x08:
		if(cols) cols--;
		break;
	case 0x09:
		cols = (cols+8)&~(8-1);
		break;
	case '\r':
		cols = 0;
		break;
	case '\n':
		cols = 0;
		lines++;
		break;
	default:
		if(c >= ' ') {
			*(vga + (lines*80 + cols++)) = v|c;
		}
		break;
	}
	if (cols >= 80) {
		cols = 0;
		lines++;
	}
	scroll();
}

void puts(char *c) {
	char v;
	while((v = *(c++))) {
		put(v);
	}
}