/*
 * types.h
 * Type definitions for Bonk used structures
 * (c) 1998 Jimmy Larsson
 *
 */

#ifndef TYPES_H
#define TYPES_H


/* interrupt handler type */
typedef int  (*irq_handler_t)(int irq);

/* task struct segment type */
typedef struct tss_386_s
{
  unsigned short  backlink, __blh;
  unsigned long   esp0;
  unsigned short  ss0, __ss0h;
  unsigned long   esp1;
  unsigned short  ss1, __ss1h;
  unsigned long   esp2;
  unsigned short  ss2, __ss2h;
  unsigned long   cr3, eip, eflags;
  unsigned long   eax, ecx, edx, ebx, esp, ebp, esi, edi;

  unsigned short  es, __esh;
  unsigned short  cs, __csh;
  unsigned short  ss, __ssh;
  unsigned short  ds, __dsh;
  unsigned short  fs, __fsh;
  unsigned short  gs, __gsh;
  unsigned short  ldt, __ldth;
  unsigned short  trace, iomapbase;
} tss_386_t;
  


/* Trap and Int gate type */
typedef struct gate_s
{
  short int       offset_low;
  short int       selector;
  unsigned char   pad;           /* 000xxxxx, int/trap */
  unsigned char   p_dpl_type;
  short int       offset_high;
} gate_t;


/* Segment descriptor type */
typedef struct seg_descriptor_s
{
  short int       limit_low;
  short int       base_low;
  unsigned char   base_mid;
  unsigned char   p_dpl_type;
  unsigned char   g_limit_high;
  unsigned char   base_high;
} seg_descriptor_t;

/* tss descriptor type */
typedef seg_descriptor_t   tss_descriptor_t;


/*
 * Message types, used in system calls
 * (all pointers in and to messages should be physical addresses)
 */

typedef struct
{
  long   mt1_l1, mt1_l2, mt1_l3, mt1_l4, mt1_l5, mt1_l6;
} mess_type_1_t;

typedef struct
{
  char   *mt2_cp1, *mt2_cp2, *mt2_cp3, *mt2_cp4, *mt2_cp5, *mt2_cp6;
} mess_type_2_t;

typedef struct
{
  long    mt3_l1, mt3_l2, mt3_l3;
  char   *mt3_cp1, *mt3_cp2, *mt3_cp3;
} mess_type_3_t;


/* This is the type used for real messages */

typedef struct
{
  unsigned long  source;
  unsigned long  dest;
  unsigned int   type;

  union
  {
    mess_type_1_t  data1;
    mess_type_2_t  data2;
    mess_type_3_t  data3;
  } data_u;

} message_t;

#endif 








