#include "bico.h"
void turn_left();
void go_on();


void _start(){
    int k;
    int i = 0;
    short unsigned int j = 0;
    
    add_alarm(turn_left, 5);
    
    add_alarm(go_on, 200);
    
    add_alarm(turn_left, 500);
   
    add_alarm(go_on, 1000);

    add_alarm(turn_left, 2000);
    
    add_alarm(go_on, 3000);

    add_alarm(turn_left, 4500);
    
    add_alarm(go_on, 6000);

    
    while(1){
    }
}

void go_on(){
    set_motors_speed(63,63);
}

void turn_left(){
    set_motors_speed(0 ,63);
}
