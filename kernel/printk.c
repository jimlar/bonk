/*
 * Printing utilities for Bonk
 * (c) Jimmy Larsson 1998
 * 
 */

#include "printk.h"

#define CHAR_ATTRIBUTE 0x1f
#define MAX_X 80
#define MAX_Y 25

/* video memory pointer */
static char   *video_mem = (char *) 0xb8000;

/* cursor pos */
static int cursor_x = 0;
static int cursor_y = 0;

/* clear screen flag */
static int first_time = 1;


/* Prototypes for private functions */
static void clear_screen (void);

/*
 * printk
 * print string to screen at current position
 * 
 */

void printk (char *message)
{
  int i = 0;
  int tmp;

  if (first_time)
    clear_screen();

  while (message[i] != '\0')
  {
    video_mem[2 * (cursor_y * MAX_X + cursor_x)] = message[i];
    video_mem[2 * (cursor_y * MAX_X + cursor_x) + 1] = CHAR_ATTRIBUTE;

    cursor_x++;

    if (cursor_x >= MAX_X)
    {
      cursor_x = 0;
      cursor_y++;

      if (cursor_y >= MAX_Y)
      {
	cursor_y = 0;
      }
    }
    i++;
  }

  tmp = cursor_x;
  /* clear rest of line */
  while (cursor_x < MAX_X)
  {
      video_mem[2 * (MAX_X * cursor_y + cursor_x)] = 0x20;
      video_mem[2 * (MAX_X * cursor_y + cursor_x) + 1] = CHAR_ATTRIBUTE;
      cursor_x++;
  }
  cursor_x = tmp;
}

/*
 * printk_long 
 * prints a long int
 *
 */

void printk_long (long no)
{
  int i;
  char str[2];

  str[1] = '\0';

  printk ("0x");

  for (i = 28; i >= 0; i -= 4)
  {
    str[0] = (no >> i) & 0xF;
    if (str[0] > 9)
      str[0] = str[0] + 'a' - 10;
    else
      str[0] = str[0] + '0';

    printk (str);
  }
}

/*
 * newline
 *
 */

void newline (void)
{
  cursor_x = 0;
  cursor_y++;

  if (cursor_y >= MAX_Y)
  {
    cursor_y = 0;
  }
}


/* 
 * fill screen with spaces 
 * 
 */

static void clear_screen (void)
{
  int x,y;

  for (y = 0; y < MAX_Y; y++)
  {
    for (x = 0; x < MAX_X; x++)
    {
      video_mem[2 * (MAX_X * y + x)] = 0x20;
      video_mem[2 * (MAX_X * y + x) + 1] = CHAR_ATTRIBUTE;
    }
  }

  cursor_x = 0;
  cursor_y = 0;

  first_time = 0;
}

