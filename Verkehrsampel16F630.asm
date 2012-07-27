        LIST     P=16F630     					; Set processor 

#INCLUDE "P16F630.INC" 							; Include processor INC file

__CONFIG _INTRC_OSC_NOCLKOUT&_PWRTE_ON&_WDT_OFF&_CP_OFF&_MCLRE_OFF     	; Set up config bits

;_ClkIn				EQU	.3686400				; Set Clockspeed (Mhz)

    constant POWEROFF_TIME = 0x02

	CBLOCK	0x20

		FLAG
		PHASE
		
		NIGHT_OUTPUT
		
		DELAY
		DELAY1	
		
		LONGTIMER_L
		LONGTIMER_H
		
		W_TEMP
		STATUS_TEMP
		
		FilterTA								; Filterregister fuer Taster

	ENDC

; in FLAG benutzte Bits
	constant NIGHT_MODE     = 0 ; == 1 gdw. Nachtmodus
    constant SLEEP_MODE     = 1 ; == 1 gdw. Going to Sleep
    constant CHANGE_MODE    = 2 ; == 1 gdw. Wechsel zwischen Tag/Nacht
    
#define _NIGHT_MODE		FLAG, NIGHT_MODE
#define _SLEEP_MODE     FLAG, SLEEP_MODE
#define _CHANGE_MODE    FLAG, CHANGE_MODE
NIGHT_MODE_bit		EQU		1 << NIGHT_MODE
SLEEP_MODE_bit      EQU     1 << SLEEP_MODE
CHANGE_MODE_bit     EQU     1 << CHANGE_MODE

	
; Belegung PortA
	constant TA			= 2

#define _TA			PORTA, TA
TA_bit		EQU		1 << TA
	
; Belegung PortC
	constant	N_RD = H'01'					
	constant	N_YE = H'02'
	constant	N_GR = H'04'
	constant	H_RD = H'08'
	constant	H_YE = H'10'
	constant	H_GR = H'20'
	

#define SetBank0				BCF	STATUS,RP0
#define SetBank1				BSF	STATUS,RP0

; ************* RESET VECTOR ***************************
	org		0x00
	goto	LSTART

; ************* INTERRUPT VECTOR ***********************
	org		0x04
	goto	LInterrupt

; ************* MAIN ***********************************
	org		0x10
LSTART 
	CLRW
	CLRF		PHASE							; Zaehler fuer Ampelphase setzen
	CLRF		PORTA
	CLRF		FLAG
	CLRF		FilterTA
    
    CLRF        LONGTIMER_L
    CLRF        LONGTIMER_H
    
    MOVLW       H_YE | N_YE
    MOVWF       NIGHT_OUTPUT

	MOVLW		0x07
	MOVWF		CMCON	

	SetBank1

	CLRW
	MOVWF		TRISC							; Port C auf OUTPUT
	MOVLW		0xFF
	MOVWF		TRISA							; Port A auf INPUT
	
	BCF			OPTION_REG,T0CS					; an OSC/4
	
	BSF			OPTION_REG,PS0
	BSF			OPTION_REG,PS1					; Teiler 256:1
	BSF			OPTION_REG,PS2

	BCF			OPTION_REG,PSA					; Clk ueber PreScaler an Timer
	
	SetBank0
	
	CLRF		TMR0
	CLRF		INTCON
	
	BSF			INTCON,T0IE						; enable TMR0 Interrupt
	BSF			INTCON,GIE						; enable Interrupts

LOOP
    INCF        LONGTIMER_L
    BTFSC       STATUS, Z
    INCF        LONGTIMER_H
    
    MOVFW       LONGTIMER_H
    XORLW       POWEROFF_TIME
    BTFSC       STATUS, Z       
    GOTO        LSLEEP
    
    BTFSC       _SLEEP_MODE
    GOTO        LSLEEP
    
    BTFSC       _CHANGE_MODE
    GOTO        WECHSEL
    
	BTFSC		_NIGHT_MODE
    GOTO        NACHT
	GOTO		NORMAL
	
WECHSEL
	MOVLW		H_YE | N_YE
	MOVWF		PORTC

	CALL		LDELAY
	CALL		LDELAY
	CALL		LDELAY
    
    BCF         _CHANGE_MODE

	BTFSC		_NIGHT_MODE
    GOTO        NACHT
    
	CLRF		PHASE							; Zaehler fuer Ampelphase setzen
	GOTO		NORMAL
    
NACHT											; Nachtmodus
	MOVFW		NIGHT_OUTPUT
	XORLW	    H_YE | N_YE
	MOVWF       NIGHT_OUTPUT
	MOVWF		PORTC

	CALL		LDELAY
	CALL		LDELAY
	CALL		LDELAY

	GOTO		LOOP

NORMAL
	MOVFW		PHASE
	ADDLW		0x01
	ANDLW		0x1F
	MOVWF		PHASE
	
	CALL		LPATTERN_EAST

	MOVWF		PORTC	

	CALL		LDELAY
	CALL		LDELAY
	CALL		LDELAY
	
	GOTO 		LOOP	

LSLEEP
    BCF         FLAG, SLEEP_MODE
    
    CLRF        PORTC
    
	CLRF		INTCON                          ; Disable all interrupts and clear flags

    BCF         OPTION_REG,INTEDG               ; RA2 Interrupt on falling edge
    BSF         INTCON,INTE                     ; enable RA2 Interrupt On Change

	BCF			INTCON,GIE						; do not jump to interrupt after Wake Up
    
    SLEEP
    NOP

    CALL		LDELAY_SHORT
    
    BTFSC       _TA                             ; Check if realy pressed
    GOTO        LSLEEP

    CLRF        LONGTIMER_L
    CLRF        LONGTIMER_H
	CLRF		PHASE							; Zaehler fuer Ampelphase setzen
	CLRF		FLAG
	
	MOVLW       B'11111110'                     ; Filter vorladen, um Umschalten nach Wake-Up zu verhindern
	MOVWF		FilterTA
                                                
	CLRF		INTCON                          ; reinitialize interrupts after wake-up
	BSF			INTCON,T0IE						; enable TMR0 Interrupt
	BSF			INTCON,GIE						; enable Interrupts
    
    GOTO        LOOP

LDELAY_SHORT
    MOVLW       0x20
    MOVWF       DELAY
    GOTO        LDELAY1
    
LDELAY	
	CLRF		DELAY
LDELAY1	
	CLRF		DELAY1	
LDELAY2
	DECFSZ		DELAY1,F
	GOTO		LDELAY2

	DECFSZ		DELAY,F
	GOTO		LDELAY1
	
	RETURN	

LPATTERN_EAST
	ANDLW	H'1F'		; to limit the table
	ADDWF	PCL,F		; add offset to PC
	; Table
	RETLW	H_RD | 					N_RD	
	RETLW	H_RD | 					N_RD	
	RETLW	H_RD |	H_YE | 			N_RD
	RETLW	H_RD |	H_YE | 			N_RD
	RETLW					H_GR | 	N_RD
	RETLW					H_GR | 	N_RD
	RETLW					H_GR | 	N_RD
	RETLW					H_GR | 	N_RD
	RETLW					H_GR | 	N_RD
	RETLW					H_GR | 	N_RD
	RETLW					H_GR | 	N_RD
	RETLW					H_GR | 	N_RD
	RETLW					H_GR | 	N_RD
	RETLW					H_GR | 	N_RD
	RETLW			H_YE | 	H_GR | 	N_RD
	RETLW			H_YE | 	H_GR | 	N_RD
	RETLW			H_YE | 			N_RD
	RETLW			H_YE | 			N_RD
	RETLW   H_RD | 					N_RD
	RETLW   H_RD | 					N_RD
	RETLW	H_RD | 					N_RD |	N_YE
	RETLW	H_RD | 					N_RD |	N_YE
	RETLW	H_RD | 									N_GR
	RETLW	H_RD | 									N_GR
	RETLW	H_RD | 									N_GR
	RETLW	H_RD | 									N_GR
	RETLW	H_RD | 									N_GR
	RETLW	H_RD | 									N_GR
	RETLW	H_RD | 							N_YE | 	N_GR
	RETLW	H_RD | 							N_YE | 	N_GR
	RETLW	H_RD | 							N_YE
	RETLW	H_RD | 							N_YE
;------------------------------------------------------------------


LInterrupt
	MOVWF	W_TEMP
	SWAPF	STATUS,W
	BCF		STATUS,RP0
	MOVWF	STATUS_TEMP

	BCF		STATUS,C		; Carry loeschen
	RLF		FilterTA,F		; Taster-Filterregister linksschieben (FilterTA)
	
	BTFSS	_TA				; wenn TA gedrueckt (TA = L)
	BSF		FilterTA,0		;   dann Bit in Filterregister setzen
	
; 
; FilterTA 
;   0000 0000  -> nicht gedrückt
;   0000 0010  -> glitch -> Filter löschen
;   0000 1100  -> kurz gedrückt -> Tag/Nacht wechseln
;   0001 1100  -> kurz gedrückt -> Tag/Nacht wechseln
;   0011 1100  -> kurz gedrückt -> Tag/Nacht wechseln
;   1111 1111  -> lang gedrückt -> aus
;   Rest -> Status unverändert

LCHECK
    BTFSC   _CHANGE_MODE    ; nur weiter, wenn _CHANGE_MODE nicht gesetzt
    GOTO    LCHECK_END      
    
    MOVFW   FilterTA        ; Taster losgelassen
    XORLW   B'00000000'
    BTFSC   STATUS,Z
    GOTO    LCHECK_END      ; fertig
    
    MOVFW   FilterTA        ; Prüfen auf Glitch
    XORLW   B'00000010'
    BTFSS   STATUS,Z
    GOTO    LCHECK_SHORT_1
    
    CLRF    FilterTA
    GOTO    LCHECK_END      ; fertig
    
LCHECK_SHORT_1              ; Prüfen auf kurzen Tastendruck
    MOVFW   FilterTA    
    XORLW   B'00001100'
    BTFSC   STATUS,Z
    GOTO    LCHECK_FOUND_SHORT
    
    MOVFW   FilterTA    
    XORLW   B'00011100'
    BTFSC   STATUS,Z
    GOTO    LCHECK_FOUND_SHORT

    MOVFW   FilterTA    
    XORLW   B'00111100'
    BTFSS   STATUS,Z
    GOTO    LCHECK_LONG
    
LCHECK_FOUND_SHORT          ; Zustand von NIGHT_MODE wechseln
    BSF     _CHANGE_MODE
    
	MOVFW	FLAG			
	XORLW	NIGHT_MODE_bit
	MOVWF	FLAG
	GOTO	LCHECK_END
    
LCHECK_LONG
	MOVFW	FilterTA		; Prüfen auf langen Tastendruck
	XORLW	B'11111111'
	BTFSS	STATUS,Z
	GOTO	LCHECK_END		; nein => fertig mit Taster 

LCHECK_FOUND_LONG
    BSF     FLAG, SLEEP_MODE
	GOTO	LCHECK_END		; nein => fertig mit Taster 

LCHECK_END

LEndInterrupt
	BCF		INTCON,T0IF

	SWAPF	STATUS_TEMP,W
	MOVWF	STATUS
	SWAPF	W_TEMP,F
	SWAPF	W_TEMP,W

	RETFIE

	END
