        LIST     P=16F630     					; Set processor 

#INCLUDE "P16F630.INC" 							; Include processor INC file

		__CONFIG _INTRC_OSC_NOCLKOUT&_PWRTE_ON&_WDT_OFF&_CP_OFF&_MCLRE_OFF     	; Set up config bits

;_ClkIn				EQU	.3686400				; Set Clockspeed (Mhz)


	CBLOCK	0x20

		PHASE
		DELAY
		DELAY1	

		FLAG
		
		W_TEMP
		STATUS_TEMP
		
		FilterTA_RD								; Filterregister fuer Taster
		FilterTA_YE								; Filterregister fuer Taster
		FilterTA_GN								; Filterregister fuer Taster
		
		PORTC_TEMP
	ENDC

; in FLAG benutzte Bits
	constant RD		= 0                         ; == 1 gdw. Rot ON
	constant YE		= 1                         ; == 1 gdw. Gelb ON
	constant GN		= 2                         ; == 1 gdw. Gruen ON

#define _RD		FLAG, RD
#define _YE		FLAG, YE
#define _GN		FLAG, GN

RD_bit		EQU		1 << RD
YE_bit		EQU		1 << YE
GN_bit		EQU		1 << GN


; Belegung PortA
    constant    TA_AUTO = 4

#define _TA_AUTO                PORTA, TA_AUTO
   
    	
; Belegung PortC
	constant	TA_RD = 5					
	constant	TA_YE = 4					
	constant	TA_GN = 3
						
	constant	LED_RD = 0					
	constant	LED_YE = 1
	constant	LED_GN = 2
	
#define _TA_RD	                PORTC, TA_RD
#define _TA_YE	                PORTC, TA_YE
#define _TA_GN	                PORTC, TA_GN

LED_RD_bit      EQU     1 << LED_RD					
LED_YE_bit      EQU     1 << LED_YE
LED_GN_bit      EQU     1 << LED_GN


#define SetBank0				BCF	STATUS,RP0
#define SetBank1				BSF	STATUS,RP0

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
	CLRF        PORTA
	CLRF		PORTC

	MOVLW		0x07
	MOVWF		CMCON	

	SetBank1

	MOVLW		0xFF
	MOVWF		TRISA							; Port A auf INPUT
;	MOVWF		WPUA							; weak pull-ups on

	MOVLW       B'00111000'                     ; Input RC<5-3>, Output RC<2-0>
	MOVWF		TRISC							; Port C

	BCF			OPTION_REG,T0CS					; an OSC/4
	BSF			OPTION_REG,NOT_RAPU				; PortA Pull-Ups disabled

	BCF			OPTION_REG,PS0
	BSF			OPTION_REG,PS1					; Teiler 128:1
	BSF			OPTION_REG,PS2
	BCF			OPTION_REG,PSA					; ueber Teiler
	
	SetBank0
	
	CLRF		TMR0

	CLRF		INTCON
	BSF			INTCON,T0IE						; enable TMR0 Interrupt
	BSF			INTCON,GIE						; enable Interrupts

	CLRW
	MOVWF       PORTC

LOOP_AUTO
    BTFSS       _TA_AUTO
    GOTO        MANUAL

	MOVFW		PHASE
	ADDLW		0x01
	ANDLW		0x0F
	MOVWF		PHASE
	
	CALL		LPATTERN
	
	MOVWF		PORTC	

	CALL		LDELAY
	CALL		LDELAY
	CALL		LDELAY
	
	GOTO 		LOOP_AUTO

MANUAL
    CLRF        FLAG
        
LOOP_MANUAL
    BTFSC       _TA_AUTO
    GOTO        LOOP_AUTO
   
    CLRF        PORTC_TEMP

    BTFSC       _RD
    BSF         PORTC_TEMP, LED_RD
    BTFSC       _YE
    BSF         PORTC_TEMP, LED_YE
    BTFSC       _GN
    BSF         PORTC_TEMP, LED_GN
    
    MOVFW       PORTC_TEMP
    MOVWF       PORTC
    
    GOTO        LOOP_MANUAL

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
	ANDLW	H'0F'		                        ; to limit the table
	ADDWF	PCL,F		                        ; add offset to PC
	; Table
	RETLW	LED_RD_bit
	RETLW	LED_RD_bit
	RETLW	LED_RD_bit
	RETLW	LED_RD_bit
	RETLW	LED_RD_bit |	LED_YE_bit
	RETLW	LED_RD_bit |	LED_YE_bit
	RETLW				     	LED_GN_bit
	RETLW				    	LED_GN_bit
	RETLW				    	LED_GN_bit
	RETLW					    LED_GN_bit
	RETLW				    	LED_GN_bit
	RETLW				    	LED_GN_bit
	RETLW			    LED_YE_bit
	RETLW	     		LED_YE_bit
	RETLW		    	LED_YE_bit
	RETLW			    LED_YE_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit
    RETLW   LED_RD_bit | LED_YE_bit | LED_GN_bit

;------------------------------------------------------------------

LInterrupt
	MOVWF	W_TEMP
	SWAPF	STATUS,W
	BCF		STATUS,RP0
	MOVWF	STATUS_TEMP

	BCF		STATUS,C		                    ; Carry loeschen
	RLF		FilterTA_RD,F	                	; Taster-Filterregister linksschieben (FilterTA)
	BCF		STATUS,C		                    ; Carry loeschen
	RLF		FilterTA_YE,F	                	; Taster-Filterregister linksschieben (FilterTA)
	BCF		STATUS,C		                    ; Carry loeschen
	RLF		FilterTA_GN,F	                	; Taster-Filterregister linksschieben (FilterTA)
	
	BTFSS	_TA_RD			                	; wenn TA gedrueckt (TA = L)
	BSF		FilterTA_RD,0               		;   dann Bit in Filterregister setzen
	BTFSS	_TA_YE			                	; wenn TA gedrueckt (TA = L)
	BSF		FilterTA_YE,0               		;   dann Bit in Filterregister setzen
	BTFSS	_TA_GN			                	; wenn TA gedrueckt (TA = L)
	BSF		FilterTA_GN,0               		;   dann Bit in Filterregister setzen

LTA_UPDATE_RD
    MOVFW   FilterTA_RD
	XORLW	0xF0
	BTFSS	STATUS,Z
	GOTO	LTA_UPDATE_YE	                    ; nein => fertig mit Taster 
    
    MOVLW   RD_bit	
    XORWF   FLAG,F
    
LTA_UPDATE_YE
    MOVFW   FilterTA_YE
	XORLW	0xF0
	BTFSS	STATUS,Z
	GOTO	LTA_UPDATE_GN	                    ; nein => fertig mit Taster 
    
    MOVLW   YE_bit	
    XORWF   FLAG,F
    
LTA_UPDATE_GN
    MOVFW   FilterTA_GN
	XORLW	0xF0
	BTFSS	STATUS,Z
	GOTO	LTA_END                             ; nein => fertig mit Taster 
    
    MOVLW   GN_bit	
    XORWF   FLAG,F

LTA_END

LEndInterrupt
	BCF		INTCON,T0IF

	SWAPF	STATUS_TEMP,W
	MOVWF	STATUS
	SWAPF	W_TEMP,F
	SWAPF	W_TEMP,W

	RETFIE

	END
