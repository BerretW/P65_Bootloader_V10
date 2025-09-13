cd .\src 
ca65  main.asm -o ..\output\main.o -l ..\lst\main.lst
ca65  acia.asm -o ..\output\acia.o -l ..\lst\acia.lst
ca65  zeropage.asm -o ..\output\zeropage.o -l ..\lst\zeropage.lst
ca65  ram_disk.asm -o ..\output\ram_disk.o -l ..\lst\ram_disk.lst
ca65  ewoz.asm -o ..\output\ewoz.o -l ..\lst\ewoz.lst
cd ..\output
cl65 -m ram.map main.o acia.o zeropage.o ram_disk.o ewoz.o -C ..\config\APP_RAM_DISK.cfg -o ramdisk.bin
cl65 -m rom.map main.o acia.o zeropage.o ram_disk.o ewoz.o -C ..\config\appartus.cfg -o ROM.bin
