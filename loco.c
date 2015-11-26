#include "bico.h"
void turn_left();
void go_on();
void stop_com_rollingstones();

void _start(){
    int k;
    int i = 0;
    short unsigned int j = 0;
    
    //go_on();

    register_proximity_callback(4, 1000, go_on);

    register_proximity_callback(1, 500, turn_left);

    //add_alarm(turn_left, 10000);
    
   // add_alarm(go_on, 200);
    
    //add_alarm(turn_left, 500);
   
    //add_alarm(go_on, 1000);

    
    //add_alarm(turn_left, 2000);
    
    //add_alarm(go_on, 3000);

    //add_alarm(turn_left, 4500);
    
    //add_alarm(go_on, 6000);

    
    while(1){
    //read_sonar(4, &j);

    //if(j < 1200){
//	set_motors_speed(0,0);
//	while(1){
//	
//	}
    }
    set_motors_speed(0,0);

}

void go_on(){
    set_motors_speed(30,30);
}

void turn_left(){
    set_motors_speed(0 ,63);
}

void stop_com_rollingstones(){
    set_motors_speed(0,0);
}
