/*
 * System call handler for Bonk
 * (c) 1998 Jimmy Larsson
 *
 */

#ifndef SYSCALL_H
#define SYSCALL_H


/* System call numbers */
#define SYSCALL_PRINTCHAR 1

/*
 * system call handler
 *
 */

void master_system_call_handler (void);


/*
 * Get arguments from calling task 
 *
 */ 


message_t get_arguments (void);



/*
 * physical to virtual address conversion
 * (physical to kernel-space)
 */

void *physical_to_virtual (void *ptr);


#endif
