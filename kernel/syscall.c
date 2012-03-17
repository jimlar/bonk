/*
 * System call handler for Bonk
 * (c) 1998 Jimmy Larsson
 *
 */


#include "types.h"
#include "config.h"
#include "gdt.h"
#include "printk.h"
#include "syscall.h"
#include "switching.h"
#include "task_test.h"

void master_system_call_handler (void)
{
  message_t arg = get_arguments ();
  char      str[2];

  switch (arg.dest)
  {
  case SYSCALL_PRINTCHAR:
    str[1] = '\0';
    str[0] = (char) arg.data_u.data1.mt1_l1;
    printk(&str[0]);
    break;
  }
  
  //printk ("System call: ");
  //printk_long (arg.dest);
  //newline();

 
  load_task (cur_task, BUSY_SET);
}

/*
 * Get arguments from calling task 
 *
 */ 


message_t get_arguments (void)
{
  message_t           ret_msg;
  message_t          *tmp_msg;
  tss_386_t          *sender;
  tss_descriptor_t   *gdt;  
  
  
  gdt = (tss_descriptor_t *) &_gdt;

  /* Get tss of message sender (caller) */
  sender = gdt[TSS_INDEX].base_low;
  sender = (tss_386_t *) ((gdt[TSS_INDEX].base_mid << 16) + (char *) sender);
  sender = (tss_386_t *) ((gdt[TSS_INDEX].base_high << 24) + (char *) sender);

  /* 
   * Since the address of the message already is physical and
   * the kernels linear = physical, we don't need no address conversion
   *
   */

  /* We have to add 4 byte to the addr, because of some strange reason ??????????? (ret addr ?) */

  tmp_msg = (message_t *) ((char *) sender->esp + 4);

  ret_msg.source = tmp_msg->source;
  ret_msg.dest = tmp_msg->dest;
  ret_msg.type = tmp_msg->type;
 
  switch (ret_msg.type)
  {

  case 1:
    ret_msg.data_u.data1.mt1_l1 = tmp_msg->data_u.data1.mt1_l1; 
    ret_msg.data_u.data1.mt1_l2 = tmp_msg->data_u.data1.mt1_l2; 
    ret_msg.data_u.data1.mt1_l3 = tmp_msg->data_u.data1.mt1_l3; 
    ret_msg.data_u.data1.mt1_l4 = tmp_msg->data_u.data1.mt1_l4; 
    ret_msg.data_u.data1.mt1_l5 = tmp_msg->data_u.data1.mt1_l5; 
    ret_msg.data_u.data1.mt1_l6 = tmp_msg->data_u.data1.mt1_l6;
    break;
  case 2:
    break;
  case 3:
    break;
  case 4:
    break;
  }

  return ret_msg;
  
}


/*
 * physical to virtual address conversion
 *
 */

void *physical_to_virtual (void *ptr)
{
  /* since the kernel has all memory phys=lin mapped (for now), this is simple */

  return ptr;
}




