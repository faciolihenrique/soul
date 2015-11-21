#include "bico.h"

int main(){
    short unsigned int i;
    int j = 0;
    set_motors_speed(20,20);
    
    while(1 == 1){
        j++;
        read_sonar(3,&i);
        set_motors_speed(0,0);
    }

    while(1 == 1);

        

    return 0;
}
