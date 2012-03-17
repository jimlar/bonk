/*
 * Debug messages for Bonk
 * (c) Jimmy Larsson 1998
 * 
 */

#ifndef DEBUG_MESSAGES_H
#define DEBUG_MESSAGES_H

/* include to read 'MSGS' flags */
#include "config.h"
#include "printk.h"

/* 
 * Macro for debugging messages
 * (Will not generate code unless __DEBUG__ is defined)
 *
 */

#ifdef __DEBUG_MSGS__
  #define DEBUG_MSG(msg) printk(msg); newline();
  #define DEBUG_MSG_NB(msg) printk(msg);
#else
  #define DEBUG_MSG(msg)
  #define DEBUG_MSG_NB(msg)
#endif


#endif





