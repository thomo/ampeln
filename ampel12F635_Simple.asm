        LIST     P=12F635     					; Set processor 

#INCLUDE "P12F635.INC" 							; Include processor INC file

		__CONFIG _INTRC_OSC_NOCLKOUT&_PWRTE_ON&_WDT_OFF&_CP_OFF&_MCLRE_OFF     	; Set up config bits

;_ClkIn				EQU	.3686400				; Set Clockspeed (Mhz)


	CBLOCK	0x40

		PHASE
		DELAY
		DELAY1	
		
	ENDC

	
; Belegung PortC
	constant	LED_RD = H'01'					
	constant	LED_YE = H'02'
	constant	LED_GR = H'04'
	

#define SetBank0				BCF	STATUS,RP0
#define SetBank1				BSF	STATUS,RP0

; ************* RESET VECTOR ***************************
	org		0x00
	goto	LSTART

	org		0x10
LSTART 
	CLRW
	CLRF		PHASE							; Zaehler fuer Ampelphase setzen
	CLRF		PORTA

	SetBank1

	CLRW
	MOVWF		TRISA							; Port A auf OUTPUT

	SetBank0

	CLRW
	MOVWF       PORTA
	CALL 		LDELAY
	CALL 		LDELAY
	CALL 		LDELAY
    MOVLW		0xFF
	MOVWF       PORTA
	CALL 		LDELAY
	CALL 		LDELAY
	CALL 		LDELAY
   

LOOP
	MOVFW		PHASE
	ADDLW		0x01
	ANDLW		0x0F
	MOVWF		PHASE
	
	CALL		LPATTERN
	
	XORLW		0xFF
	MOVWF		PORTA

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
	ANDLW	H'0F'		; to limit the table
	ADDWF	PCL,F		; add offset to PC
	; Table
	RETLW	LED_RD
	RETLW	LED_RD
	RETLW	LED_RD
	RETLW	LED_RD
	RETLW	LED_RD |	LED_YE
	RETLW	LED_RD |	LED_YE
	RETLW				     	LED_GR
	RETLW				    	LED_GR
	RETLW				    	LED_GR
	RETLW					    LED_GR
	RETLW				    	LED_GR
	RETLW				    	LED_GR
	RETLW			    LED_YE
	RETLW	     		LED_YE
	RETLW		    	LED_YE
	RETLW			    LED_YE
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR
    RETLW   LED_RD | LED_YE | LED_GR

;------------------------------------------------------------------

	END
