#include "bico.h"

int main(){
    short unsigned int i;
    int j = 0;
    set_motors_speed(20,20);
    set_motors_speed(20,0);
    while(1 == 1){
        j++;
        read_sonar(3,&i);
        if(i > 100 && i < 500){
            set_motors_speed(0,0);
        }
        if( j == 500){
           set_motors_speed(0,0);
        }
    }
    
    while(1 == 1);

        

    return 0;
}
