        LIST     P=12F629     					; Set processor 

#INCLUDE "P12F629.INC" 						; Include processor INC file

		__CONFIG _INTRC_OSC_NOCLKOUT&_PWRTE_ON&_WDT_OFF&_CP_OFF&_MCLRE_OFF     	; Set up config bits

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
	CLRF		GPIO

	SetBank1

	CLRW
	MOVWF		TRISIO							; Port auf OUTPUT

	SetBank0

	CLRW
	MOVWF       GPIO
	CALL 		LDELAY
	CALL 		LDELAY
	CALL 		LDELAY
    MOVLW		0xFF
	MOVWF       GPIO
	CALL 		LDELAY
	CALL 		LDELAY
	CALL 		LDELAY
   

LOOP
	MOVFW		PHASE
	ADDLW		0x01
	ANDLW		0x1F
	MOVWF		PHASE
	
	CALL		LPATTERN
	
	XORLW		0xFF
	MOVWF		GPIO

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
	ADDWF	PCL,F		; add offset to PC
	; Table
	RETLW	LED_RD
	RETLW	LED_RD
	RETLW	LED_RD
	RETLW	LED_RD
	RETLW	LED_RD
	RETLW	LED_RD
	RETLW	LED_RD
	RETLW	LED_RD |	LED_YE
	RETLW	LED_RD |	LED_YE
	RETLW	LED_RD |	LED_YE
	RETLW	LED_RD |	LED_YE
	RETLW	LED_RD |	LED_YE
	RETLW	LED_RD |	LED_YE
	RETLW				LED_YE
	RETLW				LED_YE
	RETLW				LED_YE
	RETLW				LED_YE
	RETLW	    		LED_YE
	RETLW		   		LED_YE
	RETLW				LED_YE
	RETLW				LED_YE |      	LED_GR
	RETLW				LED_YE |      	LED_GR
	RETLW				LED_YE |      	LED_GR
	RETLW				LED_YE |      	LED_GR
	RETLW				LED_YE |      	LED_GR
	RETLW				LED_YE |      	LED_GR
	RETLW						    	LED_GR
	RETLW						    	LED_GR
	RETLW						    	LED_GR
	RETLW						    	LED_GR
	RETLW						    	LED_GR
	RETLW								LED_GR
	RETLW				    			LED_GR
	RETLW				    			LED_GR
	RETLW				    			LED_GR
	RETLW				    			LED_GR
	RETLW				    			LED_GR
	RETLW				    			LED_GR
	RETLW				    			LED_GR

;------------------------------------------------------------------

	END
