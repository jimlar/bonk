/*
 * pages.c
 * Paging support functions for the kernel
 * (c) Jimmy Larsson 1998
 *
 */


#include "pages.h"

/*
 * init_paging, sets up paging
 * argument: total memory in MegaBytes
 *
 */

void init_paging (unsigned long  mem_size)
{
  pagetable_entry_t  *page_dir;
  pagetable_entry_t  *page_table;
  int                 i;

  page_dir = (pagetable_entry_t *) PAGE_DIR_INIT_ADDRESS;
  page_table = (pagetable_entry_t *) PAGE_TABLE_INIT_ADDRESS;

  /* 7 = present, read/write, user - page */
  page_dir[0] = (unsigned long) page_table + 7;
  page_dir[1] = (unsigned long) page_table + 4096 + 7;
  

  /* map linear = physical for first 1 MB */
  for (i = 0; i < 2048; i++)
  {
    page_table[i] = 7 + 4096*i;
  }
  

  /* set new page directory */
  __asm__ ("mov  %%eax, %%cr3" : : "a" (page_dir));


  /* turn on paging */
  __asm__ ("mov %%cr0, %%eax
            or  $0x80000000, %%eax
            mov %%eax, %%cr0" : : : "eax");

}


