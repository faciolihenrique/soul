#include "api_robot2.h" /* Robot control API */

void delay();

/* main function */
void _start(void) 
{
  unsigned int distances[16];
  short unsigned int dist3, dist4;
  /* While not close to anything. */
  do {
      read_sonar(3, &dist3);
      read_sonar(4, &dist4);
      if(dist3 < 1200)
          set_motors_speed(30, 0);
      else if(dist4 < 1200)
          set_motors_speed(0, 30);
      else
          set_motors_speed(30,30);
  } while (1);
}

/* Spend some time doing nothing. */
void delay()
{
  int i;
  /* Not the best way to delay */
  for(i = 0; i < 10000; i++ );  
}
