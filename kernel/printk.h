/*
 * Printing utilities for Bonk
 * (c) Jimmy Larsson 1998
 * 
 */

#ifndef PRINT_K_H
#define PRINT_K_H

/* include to read 'MSGS' flags */
#include "config.h"

/* 
 * Macro for boot messages
 * (Will not generate code unless __BOOT_MSGS__ is defined)
 *
 */

#ifdef __BOOT_MSGS__
  #define BOOT_MSG(msg) printk(msg); newline();
#else
  #define BOOT_MSG(msg)
#endif


/*
 * printk
 * print string to screen at current position
 * 
 */

void printk (char *message);

/*
 * printk_long 
 * prints a long int
 *
 */

void printk_long (long no);

/*
 * newline
 *
 */

void newline (void);

#endif

