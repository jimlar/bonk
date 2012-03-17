/*
 * pages.h
 * Paging support functions for the kernel
 * (c) Jimmy Larsson 1998
 *
 */

#ifndef PAGES_H
#define PAGES_H

/* Where we build the kernels pagedir and pagetables (0-0xffff used by bios, leave it for now) */
#define PAGE_DIR_INIT_ADDRESS      0x10000
#define PAGE_TABLE_INIT_ADDRESS    PAGE_DIR_INIT_ADDRESS + 1024



typedef unsigned long    pagetable_entry_t;


#endif
