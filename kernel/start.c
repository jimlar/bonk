/*
 * C entry point for Bonk
 * (System entry in entry.S)
 * (c) Jimmy Larsson 1998
 * 
 */


#include "types.h"
#include "config.h"
#include "printk.h"
#include "interrupt.h"
#include "switching.h"
#include "task_test.h"
#include "panic.h"


void system_start (void)
{

  BOOT_MSG (VERSION_STRING);
  BOOT_MSG (COPYRIGHT_STRING);
  BOOT_MSG ("----");


  init_interrupts();
  init_switching();


  /* init_memory (); */

  /* Build some processes and hook up a simple scheduler */
  start_tasktest ();


  /* Turn on interrupts and everything will begin */
  __asm__("sti");


}


