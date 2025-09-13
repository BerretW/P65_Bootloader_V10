                .setcpu "65C02"

;==============================================================================
; HARDWARE DEFINITIONS (from io.inc65)
;==============================================================================
; ACIA registers
ACIA_BASE    = $C800
ACIA_DATA    = ACIA_BASE
ACIA_STATUS  = ACIA_BASE + 1
ACIA_COMMAND = ACIA_BASE + 2
ACIA_CONTROL = ACIA_BASE + 3

; ACIA status register bit masks
ACIA_STATUS_TX_EMPTY   = 1 << 4
ACIA_STATUS_RX_FULL    = 1 << 3

; RAM DISK / APP location definitions
RAMDISK = $6000
RAMDISK_END = $7FFF
RAMDISK_RESET_VECTOR = $7FFC
RAMDISK_IRQ_VECTOR = $7FFE

;==============================================================================
; MACROS (from macros.inc65)
;==============================================================================
; Push A, X and Y
.macro phaxy
  sta tmpstack
  pha
  txa
  pha
  tya
  pha
  lda tmpstack
.endmacro

; Pull A, X and Y
.macro plaxy
  pla
  tay
  pla
  tax
  pla
.endmacro

; Push A and Y
.macro phay
  sta tmpstack
  pha
  tya
  pha
  lda tmpstack
.endmacro

; Pull A and Y
.macro play
  pla
  tay
  pla
.endmacro

;==============================================================================
; ZERO PAGE VARIABLES (from zeropage.asm)
;==============================================================================
                .zeropage
ptr1:           .res 2
tmpstack:       .res 1

;==============================================================================
; VECTORS
;==============================================================================
                .segment "VECTORS"
                .word   nmi
                .word   reset
                .word   irq

;==============================================================================
; RODATA (STRINGS)
;==============================================================================
                .segment "RODATA"
msg_0:          .byte "APPARTUS P65 Bootloader V10 HW 10-2-1", $00
msg_1:          .byte "Cekam na data", $00
msg_2:          .byte "Pro napovedu stiskni H Prikazy posilej bez CR LF.", $00
msg_3:          .byte "w = kazdy nasledujici byte zapise do pameti na pozici $6000 - $7FFF. Po prijeti vsech bytu se novy program spusti z pameti.", $00
msg_4:          .byte "r = posle na seriovou linku data z pameti $6000 - $7FFF.", $00
msg_5:          .byte "s = Spusti program z pozice reset vectoru nacteneho programu na adrese $7FFC.", $00
msg_6:          .byte "m = spusti EWOZ Monitor.", $00
msg_7:          .byte "Priklady prikazu pro EWOZ monitor:", $00
msg_8:          .byte "E000 vypise HEX hodnotu na adrese pameti $E000", $00
msg_9:          .byte "2000:FF zapise FF do pameti na adresu $2000", $00
msg_10:         .byte "2000.200F vypise HEX hodnoty z adres $2000-$200F", $00

;==============================================================================
; CODE
;==============================================================================
                .segment "CODE"

                .import _EWOZ  ; Import the entry point for the Woz Monitor

reset:          SEI         ; <--- PŘIDÁNO: Zakázat přerušení okamžitě po resetu
                ; LDX #$FF    ; Inicializace Stack Pointeru
                ; TXS
                JMP main
nmi:            RTI
irq:            RTI

main:
                JSR _acia_init
                JMP _bootloader_

;------------------------------------------------------------------------------
; ACIA Routines (from acia.asm)
;------------------------------------------------------------------------------

; void acia_init()
_acia_init:     pha
                lda #%00001011 ; No parity, No echo, TX INT disable RTS low, RX INT disable, DTR low
                sta ACIA_COMMAND
                lda #%00011111 ; 1 stop, 8 data, internal clock, 19200 baud
                sta ACIA_CONTROL
                LDA ACIA_DATA ; <--- PŘIDÁNO: Fiktivní čtení pro vyčištění RX bufferu a IRQ
                pla
                rts

; char acia_getc()
_acia_getc:
@wait_rxd_full: lda ACIA_STATUS
                and #ACIA_STATUS_RX_FULL
                beq @wait_rxd_full
                lda ACIA_DATA
                rts

; void acia_putc(char c)
_acia_putc:     pha
@wait_txd_empty:lda ACIA_STATUS
                and #ACIA_STATUS_TX_EMPTY
                beq @wait_txd_empty
                pla
                sta ACIA_DATA
                JSR DELAY_6551
                rts

; void acia_puts(const char * s) @in A/X
_acia_puts:     phay
                sta ptr1
                stx ptr1 + 1
                ldy #0
@next_char:     lda (ptr1),y
                beq @eos
                jsr _acia_putc
                iny
                bne @next_char
@eos:           play
                rts

; void acia_put_newline()
_acia_put_newline:
                pha
                lda #13
                jsr _acia_putc
                lda #10
                jsr _acia_putc
                pla
                rts

; Delay for buggy WDC 65C51
DELAY_6551:     phy
                phx
                ldy #4
MINIDLY:        ldx #$68
DELAY_1:        dex
                bne DELAY_1
                dey
                bne MINIDLY
                plx
                ply
                rts

;------------------------------------------------------------------------------
; Bootloader Logic (from ram_disk.asm)
;------------------------------------------------------------------------------

_bootloader_:
                JSR _acia_put_newline
                lda #<(msg_0)
                ldx #>(msg_0)
                jsr _acia_puts
                JSR _acia_put_newline
                lda #<(msg_2)
                ldx #>(msg_2)
                jsr _acia_puts
                JSR _acia_put_newline

_loop:
                jsr _acia_getc

                cmp #'w'
                beq _start_write
                cmp #'r'
                beq _start_read
                cmp #'H'
                beq _start_help
                cmp #'s'
                beq _start_program
                cmp #'m'
                beq _start_ewoz
                cmp #'0'
                beq _switch_b0
                cmp #'1'
                beq _switch_b1
                cmp #'2'
                beq _switch_b2

                jmp _loop

_start_program: jmp (RAMDISK_RESET_VECTOR)
_start_ewoz:    jmp _EWOZ
_start_help:    jmp _print_help
_start_read:    jmp _read_ram
_start_write:   jmp _write_to_ram

_switch_b0:     lda #0
                sta $CE00
                jmp _loop
_switch_b1:     lda #1
                sta $CE00
                jmp _loop
_switch_b2:     lda #2
                sta $CE00
                jmp _loop

_print_help:
                lda #<(msg_3)
                ldx #>(msg_3)
                jsr _acia_puts
                JSR _acia_put_newline
                lda #<(msg_4)
                ldx #>(msg_4)
                jsr _acia_puts
                JSR _acia_put_newline
                lda #<(msg_5)
                ldx #>(msg_5)
                jsr _acia_puts
                JSR _acia_put_newline
                lda #<(msg_6)
                ldx #>(msg_6)
                jsr _acia_puts
                JSR _acia_put_newline
                lda #<(msg_7)
                ldx #>(msg_7)
                jsr _acia_puts
                JSR _acia_put_newline
                lda #<(msg_8)
                ldx #>(msg_8)
                jsr _acia_puts
                JSR _acia_put_newline
                lda #<(msg_9)
                ldx #>(msg_9)
                jsr _acia_puts
                JSR _acia_put_newline
                lda #<(msg_10)
                ldx #>(msg_10)
                jsr _acia_puts
                JSR _acia_put_newline
                jmp _loop

_write_to_ram:
                lda #<(msg_1)
                ldx #>(msg_1)
                jsr _acia_puts

                ldy #0
                lda #<(RAMDISK)
                ldx #>(RAMDISK)
                sta ptr1
                stx ptr1 + 1

@write:         jsr _acia_getc
                sta (ptr1), y
                iny
                cpy #0
                bne @write_continue
                inc ptr1 + 1
                ; Check if we've filled the whole RAMDISK space ($6000-$7FFF)
                lda ptr1 + 1
                cmp #>RAMDISK_END + 1
                beq @write_done
@write_continue:
                jmp @write

@write_done:
                jmp (RAMDISK_RESET_VECTOR)

_read_ram:
                ldy #0
                lda #<(RAMDISK)
                ldx #>(RAMDISK)
                sta ptr1
                stx ptr1 + 1
@read_loop:
                lda (ptr1),y
                jsr _acia_putc
                iny
                bne @read_loop ; loop for 256 bytes

                inc ptr1 + 1
                lda ptr1 + 1
                cmp #>RAMDISK_END + 1
                bne @read_loop ; continue to next page
                
                jmp _loop ; finished