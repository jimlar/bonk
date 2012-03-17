/*
 * Tasktesting for Bonk
 * (c) Jimmy Larsson 1998
 * 
 */

#include "config.h"
#include "types.h"
#include "printk.h"
#include "switching.h"
#include "printk.h"
#include "interrupt.h"
#include "port_io.h"
#include "8259.h"
#include "task_test.h"
#include "idt.h"
#include "syscall.h"

/* for testing a few processes */
static tss_386_t   tss_test1;
static tss_386_t   tss_test2;
static char        test_stack1[1024];
static char        test_stack2[1024];

tss_386_t   *cur_task;

/* get CR3 utility */
static long get_cr3 (void)
{
  unsigned long cr3;

  asm ("mov %%cr3, %0" : "=r" (cr3));
  return cr3;
}


/* test tasks */

void task1 (void)
{
  message_t args;
 
  __asm__("sti");
  for (;;)
  {
    __asm__("cli");

    args.dest = SYSCALL_PRINTCHAR;
    args.type = 1;
    args.data_u.data1.mt1_l1 = 'A';
    
    /* push message address */
    __asm__ ("push  %%eax
              int   $0x40
              pop   %%eax" : : "a" (&args));

   
    
    __asm__("sti");
  }
}

void task2 (void)
{
  __asm__("sti");
  for (;;)
  {
    __asm__("cli");
    printk ("B");
    __asm__("sti");
  }
}

/*
 * *really* simple scheduler to test tasks
 * just run them in turn (direct connected to clock irq)
 * 
 */

int test_scheduler (int irq)
{
  if (cur_task == &tss_test1)
  {
    cur_task = &tss_test2;
    load_task (cur_task, BUSY_SET);
  } else
  {
    cur_task = &tss_test1;
    load_task (cur_task, BUSY_SET);
  }

  return 0;
}


/*
 *  init some tasks and start one 
 *
 */


void start_tasktest (void)
{
  /* test process 1 */
  tss_test1.ds = DS_SELECTOR;
  tss_test1.es = DS_SELECTOR;
  tss_test1.cs = CS_SELECTOR;
  tss_test1.ss = DS_SELECTOR;
  tss_test1.esp = (long) &test_stack1[1023];
  tss_test1.cr3 = get_cr3 ();
  tss_test1.eflags = 2;
  tss_test1.eip = (long) task1;
  tss_test1.trace = 0;
  tss_test1.backlink = TSS_SELECTOR;

  /* test process 2 */
  tss_test2.ds = DS_SELECTOR;
  tss_test2.es = DS_SELECTOR;
  tss_test2.cs = CS_SELECTOR;
  tss_test2.ss = DS_SELECTOR;
  tss_test2.esp = (long) &test_stack2[1023];
  tss_test2.cr3 = get_cr3 ();
  tss_test2.eflags = 2;
  tss_test2.eip = (long) task2;
  tss_test2.trace = 0;
  tss_test2.backlink = TSS_SELECTOR;

  /* start scheduler */
  cur_task = &tss_test2;

  /* hook scheduler with irq 0 */
  register_irq_handler (test_scheduler, 0);  

  /* fire up timer */
  out_b (0x43, 0x34);
  out_b (0x40, 0x0f);
  out_b (0x40, 0x0e);


}
