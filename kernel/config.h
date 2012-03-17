/*
 * Constants and other interesting stuff for Bonk
 * (c) Jimmy Larsson 1998
 *
 */

#ifndef CONFIG_H
#define CONFIG_H

/* Debug messages control, undef this to remove debugging garabage */
#define __DEBUG_MSGS__

/* Shall we show boot messages?  undef if not */
#define __BOOT_MSGS__

/* GDT selectors */
#define CS_SELECTOR  0x8
#define DS_SELECTOR  0x10
#define TSS_SELECTOR 0x18

/* GDT indices */
#define TSS_INDEX       3
#define GDT_INT_START_INDEX 4

/* must match "entry.S" */
#define GDT_SIZE 256

/* interrupt constants */
#define MAX_INTS      256
#define RESERVED_INTS 32

#define NO_OF_IRQS       16
#define NO_OF_EXCEPTIONS 16

/* Kernel stack */
#define KERNEL_STACK_SIZE 4096

/* Interrupt handler stack */
#define INT_STACK_SIZE 4096

/* Messages */
#define VERSION_STRING "Bonk - System start: version 0.0.0"
#define COPYRIGHT_STRING "(c) Jimmy Larsson 1998"

#endif



