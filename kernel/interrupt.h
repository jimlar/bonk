/*
 * interrupt.h
 * (c) Jimmy Larsson 1998
 * Abstraction of the IDT and other shit to "interrupt-handlers"
 * for Bonk
 *
 */

#ifndef INTERRUPT_H
#define INTERRUPT_H


/*
 * initialize everything concerning interrupts
 *
 */

void init_interrupts (void);


/*
 * register_irq_handler
 * Sets up an handler for IRQ's
 * returns nonzero on failure (eg. a handler already registered)
 *
 */

int register_irq_handler (irq_handler_t   handler, int   irq);


#endif


