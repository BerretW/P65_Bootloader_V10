cd .\src
ca65 main.s -o ..\output\main.o -l ..\lst\main.lst
ca65 ewoz.s -o ..\output\ewoz.o -l ..\lst\ewoz.lst
cd ..\output
cl65 -m ram.map main.o ewoz.o -C ..\config\APP_RAM_DISK.cfg -o ramdisk.bin
cl65 -m rom.map main.o ewoz.o -C ..\config\appartus.cfg -o ROM.bin