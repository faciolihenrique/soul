all: disk

soul.o:
	arm-eabi-as -g soul.s -o soul.o

soul: soul.o
	 arm-eabi-ld soul.o -o soul -g --section-start=.iv=0x778005e0 -Ttext=0x77800700 -Tdata=0x77801800 -e 0x778005e0

disk: soul 
	mksd.sh --so soul --user bico

clean:
	rm soul.o disk.img soul

run:
	player -g /home/specg12-1/mc404/simulador/simulador_player/worlds_mc404/simple.cfg 
