#include "kernel.h"

extern u32 memend;

typedef struct page {
	u32 present    : 1;   // Page present in memory
	u32 rw         : 1;   // Read-only if clear, readwrite if set
	u32 user       : 1;   // Supervisor level only if clear
	u32 accessed   : 1;   // Has the page been accessed since last refresh?
	u32 dirty      : 1;   // Has the page been written to since last refresh?
	u32 unused     : 7;   // Amalgamation of unused and reserved bits
	u32 frame      : 20;  // Frame address (shifted right 12 bits)
} page_t;

typedef struct page_table {
	page_t pages[1024];
} page_table_t;

typedef struct page_directory {
	/**
	   Array of pointers to pagetables.
	**/
	page_table_t *tables[1024];
	/**
	   Array of pointers to the pagetables above, but gives their *physical*
	   location, for loading into the CR3 register.
	**/
	u32 tablesPhysical[1024];

	/**
	   The physical address of tablesPhysical. This comes into play
	   when we get our kernel heap allocated and the directory
	   may be in a different location in virtual memory.
	**/
	u32 physicalAddr;
} page_directory_t;



// The kernel's page directory
page_directory_t *kernel_directory=0;

// The current page directory;
page_directory_t *current_directory=0;

// A bitset of frames - used or free.
u32 *frames;
u32 nframes;

page_t *get_page(u32 address, page_directory_t *dir);

void switch_page_directory(page_directory_t *dir);


// Macros used in the bitset algorithms.
#define INDEX_FROM_BIT(a) (a/(8*4))
#define OFFSET_FROM_BIT(a) (a%(8*4))

// Static function to set a bit in the frames bitset
static void set_frame(u32 frame_addr) {
	u32 frame = frame_addr/0x1000;
	u32 idx = INDEX_FROM_BIT(frame);
	u32 off = OFFSET_FROM_BIT(frame);
	frames[idx] |= (0x1 << off);
}

// Static function to clear a bit in the frames bitset
static void clear_frame(u32 frame_addr) {
	u32 frame = frame_addr/0x1000;
	u32 idx = INDEX_FROM_BIT(frame);
	u32 off = OFFSET_FROM_BIT(frame);
	frames[idx] &= ~(0x1 << off);
}

// Static function to test if a bit is set.
static u32 test_frame(u32 frame_addr) {
	u32 frame = frame_addr/0x1000;
	u32 idx = INDEX_FROM_BIT(frame);
	u32 off = OFFSET_FROM_BIT(frame);
	return (frames[idx] & (0x1 << off));
}

// Static function to find the first free frame.
static u32 first_frame() {
	u32 i, j;
	for (i = 0; i < INDEX_FROM_BIT(nframes); i++) {
		// nothing free, exit early.
		if (frames[i] != 0xFFFFFFFF) {
			// at least one bit is free here.
			for (j = 0; j < 32; j++) {
				u32 toTest = 0x1 << j;
				if ( !(frames[i]&toTest) ) {
					return i*4*8+j;
				}
			}
		}
	}
}

// Function to allocate a frame.
void alloc_frame(page_t *page, int is_kernel, int is_writeable) {
	if (page->frame != 0) {
		return;
	} else {
		u32 idx = first_frame();
		if (idx == (u32)-1) {
		    // PANIC! no free frames!!
		}
		set_frame(idx*0x1000);
		page->present = 1;
		page->rw = (is_writeable)?1:0;
		page->user = (is_kernel)?0:1;
		page->frame = idx;
	}
}

// Function to deallocate a frame.
void free_frame(page_t *page) {
	u32 frame;
	if (!(frame=page->frame)) {
		return;
	} else {
		clear_frame(frame);
		page->frame = 0x0;
	}
}


void switch_page_dir(page_directory_t *dir) {
	current_directory = dir;
	asm volatile("mov %0, %%cr3":: "r"(&dir->tablesPhysical));
	u32 cr0;
	asm volatile("mov %%cr0, %0": "=r"(cr0));
	cr0 |= 0x80000000; // Enable paging!
	asm volatile("mov %0, %%cr0":: "r"(cr0));
}

page_t *get_page(u32 address, page_directory_t *dir) {
	// Turn the address into an index.
	address /= 0x1000;
	u32 table_idx = address / 1024;
	if (dir->tables[table_idx]) {
		return &dir->tables[table_idx]->pages[address%1024];
	} else {
		u32 tmp;
		dir->tables[table_idx] = (page_table_t*)kmalloc_alignp(sizeof(page_table_t), &tmp);
		dir->tablesPhysical[table_idx] = tmp | 0x7; // PRESENT, RW, US.
		return &dir->tables[table_idx]->pages[address%1024];
	}
}

void page_fault(u32 i) {
	u32 faulting_address;
	asm volatile("mov %%cr2, %0" : "=r" (faulting_address));
	puts("page fault\n");
} 

void init_mmu() {
	// The size of physical memory. For the moment we 
	// assume it is 16MB big.
	u32 mem_end_page = 0x1000000;

	nframes = mem_end_page / 0x1000;
	frames = (u32*)kmalloc(INDEX_FROM_BIT(nframes));
	memset(frames, 0, INDEX_FROM_BIT(nframes));

	// Let's make a page directory.
	kernel_directory = (page_directory_t*)kmalloc_align(sizeof(page_directory_t));
	int i = 0;
	while (i < memend) {
		// Kernel code is readable but not writeable from userspace.
		alloc_frame(get_page(i, kernel_directory), 0, 0);
		i += 0x1000;
	}
	set_irq_handle(13, page_fault);
	switch_page_dir(kernel_directory);
}