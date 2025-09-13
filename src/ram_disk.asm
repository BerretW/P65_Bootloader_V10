          .include "..\include\io.inc65"
					.include "..\include\macros.inc65"
					.include "..\include\zeropage.inc65"
					.include "ewoz.asm"

					.import _acia_init
					.import _acia_putc
					.import _acia_getc
					.import _acia_puts
					.import _acia_put_newline


					.export _print_help
					.export _write_to_ram
					.export _read_ram
					.export _bootloader_

					.segment "RODATA"
msg_0:			.byte "APPARTUS P65 Bootloader V10 HW 10-2-1", $00
msg_1:			.byte "Cekam na data", $00
msg_2:			.byte "Pro napovedu stiskni H Prikazy posilej bez CR LF.", $00
msg_3:			.byte "w = kazdy nasledujici byte zapise do pameti na pozici h2000 - h3FFF. Po prijeti vsech bytu se novy program spusti z pameti.", $00
msg_4:			.byte "r = posle na seriovou linku data z pameti h2000 - h3FFF.", $00
msg_6:			.byte "m = spusti EWOZ Monitor.", $00
msg_5:			.byte "s = Spusti program z pozice reset vectoru nacteneho programu na adrese h3FFC,h3FFD.", $00
msg_7:			.byte "Priklady prikazu pro EWOZ monitor:", $00
msg_8:			.byte "FFF0 vypise HEX hodnotu na adrese pameti hFFF0", $00
msg_9:			.byte "2000:FF zapise FF do pameti na adresu h2000", $00
msg_10:			.byte "2000.200F vypise HEX hodnoty z adres h2000-h200F", $00



					.segment "CODE"

_bootloader_:	JSR _acia_put_newline
				LDA #<(msg_0)
				LDX #>(msg_0)
				JSR _acia_puts
				JSR _acia_put_newline
				LDA #<(msg_2)
				LDX #>(msg_2)
				JSR _acia_puts
				JSR _acia_put_newline

_loop:			JSR _acia_getc

				CMP #'w'
				BEQ _start_write

				CMP #'r'
				BEQ _start_read

				CMP #'H'
				BEQ _start_help

				CMP #'s'
				BEQ _start_program

				CMP #'m'
				BEQ _start_ewoz

        CMP #'0'
				BEQ _switch_b0

        CMP #'1'
        BEQ _switch_b1

        CMP #'2'
				BEQ _switch_b2

				JMP	_loop

_start_program:	JMP (RAMDISK_RESET_VECTOR)
_start_ewoz:	JMP _EWOZ
_start_help:	JMP _print_help
_start_read:	JMP _read_ram
_start_write:	JMP _write_to_ram

_switch_b0: LDA #0
            STA $CE00
            JMP _loop
_switch_b1: LDA #1
            STA $CE00
            JMP _loop
_switch_b2: LDA #2
            STA $CE00
            JMP _loop


_print_help:	LDA #<(msg_3)
				LDX #>(msg_3)
				JSR _acia_puts
				JSR _acia_put_newline
				LDA #<(msg_4)
				LDX #>(msg_4)
				JSR _acia_puts
				JSR _acia_put_newline
				LDA #<(msg_5)
				LDX #>(msg_5)
				JSR _acia_puts
				JSR _acia_put_newline
				LDA #<(msg_6)
				LDX #>(msg_6)
				JSR _acia_puts
				JSR _acia_put_newline
				LDA #<(msg_7)
				LDX #>(msg_7)
				JSR _acia_puts
				JSR _acia_put_newline
				LDA #<(msg_8)
				LDX #>(msg_8)
				JSR _acia_puts
				JSR _acia_put_newline
				LDA #<(msg_9)
				LDX #>(msg_9)
				JSR _acia_puts
				JSR _acia_put_newline
				LDA #<(msg_10)
				LDX #>(msg_10)
				JSR _acia_puts
				JSR _acia_put_newline
				JMP _loop



_write_to_ram:	LDA #<(msg_1)
				LDX #>(msg_1)
				JSR _acia_puts

				LDY #0
				LDA #<(RAMDISK)
				LDX #>(RAMDISK)
				STA ptr1
				STX ptr1 + 1

@write:			JSR _acia_getc
				;JSR _lcd_putc
				STA (ptr1), Y
				INY
				CPY #$0
				BNE @end
				INX
				STX ptr1 + 1
				CPX #$20
				BNE @end
				JMP (RAMDISK_RESET_VECTOR)
@end:			JMP @write

_go_loop:		JMP _loop
_read_ram:
				LDY #0
				LDA #<(RAMDISK)
				LDX #>(RAMDISK)
				STA ptr1
				STX ptr1 + 1
@read:			LDA (ptr1),Y
				JSR _acia_putc
				INY
				CPY #$0
				BNE @read
				INX
				STX ptr1 + 1
				CPX #$40
				BEQ _go_loop
@end:			JMP @read
