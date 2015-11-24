#include "bico.h"
void turn_left();
void _start(){
    int k;
    int i = 0;
    short unsigned int j = 0;
    
    set_motors_speed(63,63);
    
    for(i = 0; i < 100000; i++);

   // set_motors_speed(0,0);
    
    for(i = 0; i < 100000; i++);
    
    //set_motors_speed(63,0);
    
    for(i = 0; i < 100000; i++);
    
    set_motors_speed(0,0);

    add_alarm(turn_left, 200);

   // while(1){
//	read_sonar(4, &j);
//	for(i = 0; i < 1000; i++);
//	if(j > 1000)
//	    set_motors_speed(0,63);
//	if(j < 1000)
//	    set_motors_speed(63,0);
  //  }
    
    while(1){
        //read_sonar(3, &i);
	//read_sonar(4, &j);
        //if(i < 500){
        //    set_motors_speed(63, 0);
	//    for(k = 0; k < 5000; k++);
	//}
	//if(j < 500){
	//    set_motors_speed(0,63);
	//    for(k = 0; k < 5000; k++);
	//}
	//set_motors_speed(20,20);
    }
}

void turn_left(){
    int i;
    set_motors_speed(0 ,63);

}
