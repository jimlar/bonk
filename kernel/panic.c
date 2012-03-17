/*
 * panic.c
 * (c) Jimmy Larsson 1998
 * Die with an error message
 *
 */

#include "panic.h"
#include "printk.h"


void panic (char   *msg)
{
  newline ();
  printk ("PANIC: ");
  printk (msg);
  newline ();

  while (1);
}


void warning (char   *msg)
{
  newline ();
  printk ("WARNING: ");
  printk (msg);
  newline ();

}


