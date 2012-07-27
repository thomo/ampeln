        LIST     P=16C84     					; Set processor to 16C84

#INCLUDE "P16C84.INC" 							; Include processor INC file

		__CONFIG _XT_OSC&_WDT_OFF&_CP_OFF     	; Set up config bits

_ClkIn				EQU	.3686400				; Set Clockspeed (Mhz)


	CBLOCK	0x0C

		FLAG
		PHASE
		DELAY
		DELAY1	
		
		W_TEMP
		STATUS_TEMP
		
		IFLAG
		FTA1									; Filterregister fuer TA1
		FTA2									; Filterregister fuer TA2

	ENDC

	constant	N_RD = H'04'
	constant	N_YE = H'02'
	constant	N_GR = H'01'
	constant	H_RD = H'08'
	constant	H_YE = H'10'
	constant	H_GR = H'20'
	
	constant    TA1  = H'01'
	constant    TA2  = H'02'

	constant	BIT_TA1 = 0
	constant	BIT_TA2 = 1
	
	constant    ZTA1 = H'01'
	
	
	

; ************* RESET VECTOR ***************************
	org		0x00
	goto	LSTART

; ************* INTERRUPT VECTOR ***********************
	org		0x04
	goto	LInterrupt



	org		0x10
LSTART 
	CLRW
	CLRF		PHASE							; Zaehler fuer Ampelphase setzen
	CLRF		PORTA
	CLRF		FLAG
	CLRF		FTA1
	CLRF		FTA2
	
	BSF			STATUS,RP0						; Select Bank1

	CLRW
	MOVWF		TRISB							; Port B auf OUTPUT
	MOVLW		0xFF
	MOVWF		TRISA							; Port A auf INPUT

	BCF			OPTION_REG,T0CS					; an OSC/4

	BSF			OPTION_REG,PS0
	BSF			OPTION_REG,PS1					; Teiler 256:1
	BSF			OPTION_REG,PS2

	BCF			OPTION_REG,PSA					; ueber Teiler
	
	BCF			STATUS,RP0						; Select Bank0
	
	CLRF		TMR0
	
	CLRF		INTCON
	
	BSF			INTCON,T0IE						; enable TMR0 Interrupt
	BSF			INTCON,GIE						; enable Interrupts

LOOP
	BTFSS		FLAG,BIT_TA1
	GOTO		NORMAL
	
NACHT											; Nachtmodus
												
	MOVLW		0x12							; H_YE | N_YE
	XORLW		0xFF
	MOVWF		PORTB

	CALL		LDELAY
	CALL		LDELAY
	CALL		LDELAY

	MOVLW		0x00
	XORLW		0xFF
	MOVWF		PORTB

	CALL		LDELAY
	CALL		LDELAY
	CALL		LDELAY

	GOTO		LOOP
	

NORMAL
	MOVFW		PHASE
	ADDLW		0x01
	ANDLW		0x1F
	MOVWF		PHASE
	
	CALL		LPATTERN
	
	XORLW		0xFF
	MOVWF		PORTB	
	CALL		LDELAY
	CALL		LDELAY
	CALL		LDELAY
	
	GOTO 		LOOP	


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

LPATTERN
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
	RLF		FTA1,F			; TA1 Filterregister linksschieben (FTA1)
	
	BTFSS	PORTA,BIT_TA1	; wenn TA1 gedrueckt, dann Bit in Filterregister setzen
	BSF		FTA1,0
	
	BTFSC	IFLAG,ZTA1		; letzter Zustand von ZTA1 == 0?
	GOTO	LTA1_1			; nein 
							; ja
	MOVFW	FTA1			;   => Vergleich, ob FTA1 jetzt == 0xFF (also TA1 gedrueckt)
	XORLW	0xFF
	BTFSS	STATUS,Z
	GOTO	LTA1_END		;      nein => fertig mit Taster 1
							; 	   ja
	MOVFW	FLAG			;		 => Zustand von FlagTA1 wechseln
	XORLW	TA1
	MOVWF	FLAG
	
	BSF		IFLAG,ZTA1		;			ZTA1 = 1

LTA1_1
							; nein, (also letzter Zustand von ZTA1 ist 1)
	MOVFW	FTA1			; Vergleich, ob FTA1 jetzt == 0x00 (also TA1 losgelassen)
	BTFSS	STATUS,Z
	GOTO	LTA1_END		; nein
							; ja
	BCF		IFLAG,ZTA1		;   => ZTA1 = 0

LTA1_END

LEndInterrupt
	BCF		INTCON,T0IF

	SWAPF	STATUS_TEMP,W
	MOVWF	STATUS
	SWAPF	W_TEMP,F
	SWAPF	W_TEMP,W

	RETFIE

	END
