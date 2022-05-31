; Print.s
; Student names: Mehmet Uzgoren
; Last modification date: change this to the last modification date or look very silly
; Runs on TM4C123
; EE319K lab 7 device driver for any LCD
;
; As part of Lab 7, students need to implement these LCD_OutDec and LCD_OutFix
; This driver assumes two low-level LCD functions
; ST7735_OutChar   outputs a single 8-bit ASCII character
; ST7735_OutString outputs a null-terminated string 


	PRESERVE8
FP RN 11
COUNT EQU 0
NUM EQU 4
	
    IMPORT   ST7735_OutChar
    IMPORT   ST7735_OutString
    EXPORT   LCD_OutDec
    EXPORT   LCD_OutFix

    AREA    |.text|, CODE, READONLY, ALIGN=2
    THUMB

 
;-----------------------LCD_OutDec-----------------------
; Output a 32-bit number in unsigned decimal format
; Input: R0 (call by value) 32-bit unsigned number
; Output: none
; Invariables: This function must not permanently modify registers R4 to R11
; R0=0,    then output "0"
; R0=3,    then output "3"
; R0=89,   then output "89"
; R0=123,  then output "123"
; R0=9999, then output "9999"
; R0=4294967295, then output "4294967295"





LCD_OutDec
	 PUSH {R4-R9, R11, LR}
	 SUB SP, #8
	 CMP R0, #0
	 BEQ Zero

	 MOV FP, SP
	 STR R0, [FP, #NUM]
	 MOV R4, #0
	 STR R4, [FP, #COUNT]
	 MOV R5, #10
	 
loop
	 LDR R4, [FP, #NUM]
	 CMP R4, #0
	 BEQ Next
	 UDIV R6, R4, R5
	 MUL R7, R5, R6
	 SUB R8, R4, R7
	 PUSH {R8}
	 STR R6, [FP, #NUM]
	 LDR R6, [FP, #COUNT]
	 ADD R6, #1
	 STR R6, [FP, #COUNT]
	 B loop
	 
Next
	 LDR R4, [FP, #COUNT]
	 CMP R4, #0
	 BEQ Done	
	 POP {R0}
	 ADD R0, #0x30
	 BL ST7735_OutChar
	 SUB R4, #1
	 STR R4, [FP, #COUNT]
	 B Next
	 
Zero	
	 MOV R0, #0x30
	 BL ST7735_OutChar
	 
Done
	 ADD SP, #8
	 POP {R4-R9, R11, LR}
     BX  LR
	 
	  
;* * * * * * * * End of LCD_OutDec * * * * * * * *

; -----------------------LCD _OutFix----------------------
; Output characters to LCD display in fixed-point format
; unsigned decimal, resolution 0.001, range 0.000 to 9.999
; Inputs:  R0 is an unsigned 32-bit number
; Outputs: none
; E.g., R0=0,    then output "0.000"
;       R0=3,    then output "0.003"
;       R0=89,   then output "0.089"
;       R0=123,  then output "0.123"
;       R0=9999, then output "9.999"
;       R0>9999, then output "*.***"
; Invariables: This function must not permanently modify registers R4 to R11




LCD_OutFix
	 PUSH{R4-R9, R11, LR}
	
	 SUB SP, #8 ;Allocation
	
	 CMP R0, #0
	 BEQ EdgeZero
		
	 MOV R1, #9999															
	 CMP R0, R1
	 BHI EdgeHigher

	 MOV FP, SP ;New pointer for count and num values on stack
	 MOV R1, #0
	 STR R1, [FP, #COUNT] ;Count starts with 0
	 STR R0, [FP, #NUM] ;Num gets input R0
	 MOV R2, #10 ;Initialize R5 with 10 for modulus 
	
PushIntegers
	 LDR R1, [FP, #NUM] ;R4 gets num
	 CMP R1, #0 
	 BEQ AddZeros ;Loop finished when there are no more digits
	 UDIV R3, R1, R2 ;R6 gets quotient
	 MUL R4, R3, R2 ;Quotient *10
	 SUB R5, R1, R4 ; Remainder = Number - Quotient*10
	 PUSH {R5} ;Remainder (digit) gets pushed onto stack
	 STR R3, [FP, #NUM] ;Quotient gets stored into num
	 LDR R3, [FP, #COUNT] 
	 ADD R3, #1 
	 STR R3, [FP, #COUNT] ;Count is increased
	 B PushIntegers

AddZeros
	 MOV R6, #4
	 LDR R7, [FP, #COUNT] ;R2 gets amount of digits
	 MOV R8, #0; Flag
	 SUBS R6, R7 ;Finds the amount of zeros needed
	
CheckZeros
	 CMP R6, #0 ;Checks to see if there are anymore 0s needed
	 BEQ PopIntegers
	 MOV R0, #0x30
	 BL ST7735_OutChar
	 CMP R8, #0 ;If the program is on the first 0, it'll also print out a decimal point
	 BNE SkipDecimal
	 MOV R0, #0x2E
	 BL ST7735_OutChar

SkipDecimal
	 SUBS R6, #1
	 MOV R8, #1 ;Makes sure no more decimal points are printed
	 B CheckZeros

PopIntegers
	 LDR R6, [FP, #COUNT] ;R4 gets count
	 CMP R6, #0 ;Checks to see there are digits on the stack
	 BEQ OutFixDone
	 POP {R0} ;Pushes R0, which has the digit at the top of the stack
	 ADD R0, #0x30 ;Converts to ascii value
	 BL ST7735_OutChar
	 CMP R6, #4
	 BNE SkipDecimal2 
	 MOV R0, #0x2E
	 BL ST7735_OutChar ;If there are 4 digits, print a decimal point right after the first digit
	
SkipDecimal2	
	 SUB R6, #1 ;Count decrements
	 STR R6, [FP, #COUNT]
	 B PopIntegers
	
		
;Prints the zeros needed and the decimal point if the number of digits is < 4
;Input: None
;Output: None




;Edge case if R0 > 9999
;Inputs: None
;Outputs: None
EdgeHigher
	 
	 MOV R0, #0x2A
	 BL ST7735_OutChar
	 MOV R0, #0x2E
	 BL ST7735_OutChar
	 MOV R0, #0x2A
	 BL ST7735_OutChar
	 MOV R0, #0x2A
	 BL ST7735_OutChar
	 MOV R0, #0x2A
	 BL ST7735_OutChar
	 B OutFixDone

;Edge case if R0=0
;Inputs: None
;Outputs: None
EdgeZero
	 MOV R0, #0x30
	 BL ST7735_OutChar
	 MOV R0, #0x2E
	 BL ST7735_OutChar
	 MOV R0, #0x30
	 BL ST7735_OutChar
	 MOV R0, #0x30
	 BL ST7735_OutChar
	 MOV R0, #0x30
	 BL ST7735_OutChar
	
OutFixDone
	 ADD SP, #8 ;Re-allocation
	 POP {R4-R9, R11, LR}
	 BX LR
;* * * * * * * * End of LCD_OutFix * * * * * * * *

     ALIGN                           ; make sure the end of this section is aligned
     END                             ; end of file
