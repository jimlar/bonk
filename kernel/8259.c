/*
 * 8259 - Interrupt controller functions for Bonk
 * (c) Jimmy Larsson
 * 
 */

#include "config.h"
#include "debug_messages.h"
#include "8259.h"
#include "port_io.h"

/* Crappy 8259 constants, won't put the in .h file */
#define CASCADE_IRQ  2
/* ICW4 needed, cascade, 8 byte int. vec, edge triggered. */
#define ICW1         0x11
/* Defines which IRQ connects slave/master */
#define MASTER_ICW3  (1 << CASCADE_IRQ)
#define SLAVE_ICW3   CASCADE_IRQ
/* 80x86 mode */
#define ICW4         0x01

/* EOI Command */
#define ENABLE_INT       0x20

/* IO Ports */
#define MASTER_CTL       0x20
#define SLAVE_CTL        0xa0
#define MASTER_CTLMASK   0x21
#define SLAVE_CTLMASK    0xa1
                                

void init_8259 (void)
{
  /* Start initialization */
  out_b (MASTER_CTL, ICW1);
  out_b (SLAVE_CTL,  ICW1);

  /* Set IRQ vectors */
  out_b (MASTER_CTLMASK, IRQ0_VECTOR);
  out_b (SLAVE_CTLMASK,  IRQ8_VECTOR);

  /* Connect master/slave */
  out_b (MASTER_CTLMASK, MASTER_ICW3);
  out_b (SLAVE_CTLMASK,  SLAVE_ICW3);

  /* finish initialization */
  out_b (MASTER_CTLMASK, ICW4);
  out_b (SLAVE_CTLMASK,  ICW4);

  /* mask off all interrupts, but the cascade */
  out_b (MASTER_CTLMASK, ~(1 << CASCADE_IRQ));
  out_b (SLAVE_CTLMASK, ~0);

  DEBUG_MSG("8259 initialized");
}


/*
 * enable_8259_irq
 * Unmask an irq on the controller
 *
 */

void enable_8259_irq (int irq)
{
  if (irq > -1 && irq < 8)
  {
    __asm__ ("pushf");
    out_b (MASTER_CTLMASK, (in_b (MASTER_CTLMASK) & ~(1 << irq)));
    __asm__ ("popf");
  }
  else if (irq > 7 && irq < 16)
  {
    __asm__ ("pushf");
    out_b (SLAVE_CTLMASK, (in_b (SLAVE_CTLMASK) & ~(1 << (irq - 8))));
    __asm__ ("popf");
  }
}                 


/*
 * disable_8259_irq
 * mask off an irq on the controller
 *
 */

void disable_8259_irq (int irq)
{
  
  if (irq > -1 && irq < 8)
  {
    __asm__ ("pushf");
    out_b (MASTER_CTLMASK, (in_b (MASTER_CTLMASK) | (1 << irq)));
    __asm__ ("popf");
  } else if (irq > 7 && irq < 16)
  {
    __asm__ ("pushf");
    out_b (SLAVE_CTLMASK, (in_b (SLAVE_CTLMASK) | (1 << (irq - 8))));
    __asm__ ("popf");
  }
}

/*
 * eoi_8259_irq
 * EndOfInterrupt, finished with interrupt handling
 * send ack. to controllers (eg. turn them on again)
 */

void eoi_8259 (int irq)
{
  if (irq > -1 && irq < 8)
  {
    out_b (MASTER_CTL, ENABLE_INT);

  } else if (irq > 7 && irq < 16)
  {
    out_b (MASTER_CTL, ENABLE_INT);
    out_b (SLAVE_CTL, ENABLE_INT);
  }
}

