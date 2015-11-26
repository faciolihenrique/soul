#include "bico.h"
void vira_parede();
void segue_parede();

void _start(){
    int i;
    int speed;
    unsigned int dist[17];
    short unsigned int dist1 = 600, dist3 = 1500, dist4 = 1500;

    //set_motors_speed(20,20);
   
    read_sonars(dist);

    read_sonar(0, &dist1);
    /*while(dist3 > 400 && dist4 > 400){
        read_sonar(3, &dist3);
        read_sonar(4, &dist4);
    }
    set_motors_speed(0, 10);
    while(dist1 > 450){
        read_sonar(0, &dist1);
    }*/

    //register_proximity_callback(4 ,400 ,vira_parede);
    
    /*while(1){
        read_sonar(0, &dist1);    
        speed = (int) (dist1/50);
        set_motors_speed(speed , 10);
    }*/
    
    while(1){
    
    }
}

void segue_parede(){
    int i;
    
    short unsigned int dist0 = 2000;
}

void vira_parede(){
    short unsigned int dist1 = 2000;
    set_motors_speed(30, 25);
    while(dist1 > 500){
        read_sonar(0, &dist1);
    }
}

void stop_com_rollingstones(){
    set_motors_speed(0,0);
}
