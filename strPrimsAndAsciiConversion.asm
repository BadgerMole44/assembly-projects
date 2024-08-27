TITLE Designing, implementing, and calling low-level I/O macros and procedures

; Description: This program prompts the user ten times to enter a signed or unsigned whole number. After reading each input
;	the input string is converted to its signed decimal equivalent and stored in an array. 
;		If an input contains an anything other
;	than 0-9, '-' or '+' in the first character, or is a signed decimal value too large for a 32 bit register the user is notified
;	that the input is invalid and reprompted.
;		After ten valid signed decimal values are stored the values are converted to ASCII string and displayed back to the user
;	in the order they were entered. Using the array of signed decimal values the sum and truncated average are calculated, 
;	converted to ASCII strings, and displayed to the user. The program then displays a farewell message before ending.

INCLUDE Irvine32.inc
; ------------------------
; Macro Name: mGetString
; Goal: 
;		Prompt the user to enter a string. Use ReadString to read the string. Store the user entry at addressOfBuffer.
;			Store the length of the input (bytes) in addressOfByteCount. Max number of character to enter is 30.
; Preconditions: 
;		Params are OFFSET.
; Postconditions:
;		address of the user input string is at addressOfBuffer. The length of the input string in bytes is at
;		addressOfByteCount.
; Receives:
;		prompt				= promp displayed to user
;		addressOfBuffer		= Where to store the user input (must be an array of bytes)
;		ByteCount			= Where to store the number of bytes long the string is
; Registers changed (preserved and restored): 
;		EAX 
;		ECX	
;		EDX 
; ------------------------
mGetString	MACRO prompt:REQ, addressOfBuffer:REQ, ByteCount:REQ
	; preserve registers
	push	EAX
	push	ECX
	push	EDX
	; display prompt
	mov		EDX,		prompt
	call	WriteString
	; read and store the user input data
	mov		EDX,		addressOfBuffer
	mov		ECX,		30
	call	ReadString
	mov		byteCount,	EAX
	; restore registers
	pop		EDX
	pop		ECX
	pop		EAX
ENDM


; ------------------------
; Macro Name: mDisplayString
; Goal: 
;		Display the string param str_variable.
; Preconditions: 
;		Params are OFFSET. Do not use EDX as the argument.
; Receives:
;		str_variable = reference to the string to be displayed
; Registers changed (preserved and restored): 
;		EDX 
; ------------------------
mDisplayString MACRO str_variable:REQ
	; preserve registers
	push	EDX
	mov		EDX,	str_variable
	call	WriteString
	; restore registers
	pop		EDX
ENDM


	ARRAYSIZE = 10


.data
	title1			BYTE	"PROGRAMMING ASSIGNMENT 6: Designing low-level I/O Procedures",10,0
	name1			BYTE	"Written by: Keegan Forsythe",10,10,0

	directions1		BYTE	"Please provide 10 signed decimal integers one at a time.",10,0
	directions2		BYTE	"Signed decimal integers must be in the range [-2^31, (2^31)-1] inclusive. After ten valid numbers have been inputted the program will display the list of inputs, sum of inputs, and the average of inputs.",10,10,0

	prompt1			BYTE	"Please enter a signed number: ",0
	error1			BYTE	"Invalid entry: the entered value is not a signed number or is beyond the range.",10,0
	prompt2			BYTE	"Please enter another number: ",0

	inputStr		BYTE	30 DUP(0)
	byteCount		DWORD	?

	strValid		DWORD	0

	num				SDWORD	0
	numArray		SDWORD	ARRAYSIZE DUP(0)

	tmpStr			BYTE	12 DUP(0)
	outStr			BYTE	12 DUP(0)
	edgCase			BYTE	"-2147483648",0

	dispArray		BYTE	"You entered the following 10 valid numbers:",0
	seperator		BYTE	", ",0

	dispSum			BYTE	"The sum of these numbers is: ",0
	sum				SDWORD	0

	dispAvg			BYTE	"The truncated average is: ",0
	avg				SDWORD	0	

	farewell1		BYTE	"Thank you for using my program! Goodbye.",10,0


.code
main PROC
	; display the program title and programmer name
	mDisplayString	OFFSET title1
	mDisplayString	OFFSET name1
	; display the directions
	mDisplayString	OFFSET directions1
	mDisplayString	OFFSET directions2

; ------------------------
; get 10 valid integers and add them to a numArray
; ------------------------
	mov				ECX,	ARRAYSIZE		
	mov				EDI,	OFFSET numArray			; first address of SDWORD array where integer values will be stored.	
	
_getAndStoreTenIntegers:
	; preserve place in the numArray and ECX loop counter
	
	push			ECX
	push			EDI

	; push params for ReadVal
	push			OFFSET inputStr					; empty string to store and read user input
	push			OFFSET prompt2					; prompt for user after error msg
	push			OFFSET prompt1					; regular message to prompt user
	push			OFFSET error1					; error msg for user
	push			byteCount						; where to store the length of the input string
	push			EDI								; address of where to store the converted integer value: address in SDWORD numArray
	push			strValid						; where to find the strings validity

	call			ReadVal							; read string value and store it as an int in numArray

	; clear input string
	mov				EDI,	OFFSET inputStr
	mov				ECX,	30
	mov				EAX,	0
	CLD
	REP				STOSB

	; prep for next loop
	pop				EDI								; retreive position in numArray
	add				EDI,	4						; move to the next position in numArray
	pop				ECX								; retreive loop counter
	loop			_getAndStoreTenIntegers
	call			CrLf
	
; ------------------------
; display the 10 stored signed decimal values back to the user as strings
; ------------------------
	; Display to user what's being shown
	mDisplayString	OFFSET dispArray
	call			CrLf

	mov				ESI,	OFFSET numArray			; first SDWORD signed decimal value 
	mov				ECX,	ARRAYSIZE				; number of SDWORDs in numArray
_displayTenIntegers:
	; preserve position in numArray and loop counter
	push			ESI
	push			ECX
	; push params for WriteVal
	push			OFFSET edgCase					; incase the entered number is -2^31
	push			OFFSET outStr					; where converted string will be stored (empty string)
	push			OFFSET tmpStr					; helps convert signed decimal to ASCII (empty string)
	push			[ESI]							; SDWORD signed decimal to convert to ASCII

	call			WriteVal

	; clear outStr
	mov				EDI,	OFFSET outStr
	mov				ECX,	12
	mov				EAX,	0
	CLD
	REP				STOSB
	; clear tmpStr
	mov				EDI,	OFFSET outStr
	mov				ECX,	12
	mov				EAX,	0
	CLD
	REP				STOSB
	; check if on the last loop
	pop				ECX
	cmp				ECX,	1
	jnz				_prepForNextInt					; if not on the last loop jump to _prepForNextInt
	call			CrLf							; if on last loop print a new line and exit loop.
	jmp				_continueDisplayTenIntegers
_prepForNextInt:
	mDisplayString	OFFSET seperator				; display a comma and a space
_continueDisplayTenIntegers:
	pop				ESI
	add				ESI,	4						; move to next address of num array
	loop			_displayTenIntegers

; ------------------------
; calculate the sum of the array: sum must be in the range [-2^31, (2^31)-1] to be SDWORD.
; ------------------------
	mDisplayString	OFFSET dispSum
	; prep
	mov				ESI,	OFFSET numArray			; first int of numArray
	mov				ECX,	ARRAYSIZE				; set ECX counter
_calcSum:
	mov				EAX,	[ESI]
	add				sum,	EAX						; add each value in num array to sum (sum is initially 0)
	add				ESI,	4						; move to next num in numArray
	loop			_calcSum
	
	; display the sum 
	push			OFFSET edgCase					; incase the entered number is -2^31
	push			OFFSET outStr					; where converted string will be stored (empty string)
	push			OFFSET tmpStr					; helps convert signed decimal to ASCII (empty string)
	push			sum								; SDWORD signed decimal to convert to ASCII

	call			WriteVal
	; clear outStr
	mov				EDI,	OFFSET outStr
	mov				ECX,	12
	mov				EAX,	0
	CLD
	REP				STOSB
	; clear tmpStr
	mov				EDI,	OFFSET outStr
	mov				ECX,	12
	mov				EAX,	0
	CLD
	REP				STOSB
	call			CrLf

; ------------------------
; calculate the average of the array: avg must be in the range [-2^31, (2^31)-1] to be SDWORD.
; ------------------------
	mDisplayString	OFFSET dispAvg
	; calculate the average
	mov				EAX,	sum
	mov				EDX,	0
	mov				EBX,	ARRAYSIZE
	CDQ
	idiv			EBX
	mov				avg,	EAX
	; display the average
	; display the sum 
	push			OFFSET edgCase					; incase the entered number is -2^31
	push			OFFSET outStr					; where converted string will be stored (empty string)
	push			OFFSET tmpStr					; helps convert signed decimal to ASCII (empty string)
	push			avg								; SDWORD signed decimal to convert to ASCII
	call			WriteVal
	; clear outStr
	mov				EDI,	OFFSET outStr
	mov				ECX,	12
	mov				EAX,	0
	CLD
	REP				STOSB
	; clear tmpStr
	mov				EDI,	OFFSET outStr
	mov				ECX,	12
	mov				EAX,	0
	CLD
	REP				STOSB
	call			CrLf
	call			CrLf
	; display the farewell message
	mDisplayString	OFFSET farewell1

	Invoke ExitProcess,0	
main ENDP



; ------------------------
; Procedure Name: ReadVal
; Goal: 
;		Prompts a user to input a signed decimal integer. Reads and stores the user input string. Converts the ASCII string to 
;			a signed integer value value. Stores the signed decimal value. Will detect if the input string is larger than SDWORD
;			and print an error mesg and reprompt.
; Preconditions: 
;		inputStr is empty. SDWORD at numAddress is empty
; Postconditions:
;		SDWORD at numAddress has signed decimal value.
; Receives:
;		[EBP+8]  = DWORD strValid: for use in convertAsciiToInt
;		[EBP+12] = SDWORD numAddress: for use in convertAsciiToInt location where the signed decimal is stored
;		[EBP+16] = DWORD OFFSET byteCount: for use by mGetString and convertAsciiToInt stores the length of the input string
;		[EBP+20] = BYTE OFFSET Error1: for use by mGetString
;		[EBP+24] = BYTE OFFSET prompt1: for use by mGetString
;		[EBP+28] = BYTE OFFSET prompt2: for error message
;		[EBP+32] = BYTE OFFSET inputStr: for use by mGetString and convertAsciiToInt stores the user strign input
; Registers changed (preserved and restored): 
;		EAX, EBX, ECX, EDX, ESI, EDI
; ------------------------
ReadVal PROC
		; Setup the stack frame
		push		EBP
		mov			EBP,		ESP
		; preserve all used registers
		push		EAX
		push		EBX
		push		ECX
		push		EDX
		push		ESI
		push		EDI
		; prep for mGetString
		mov			EDX,		[EBP+24]			; regular prompt OFFSET
		mov			EBX,		[EBP+32]			; inputStr OFFSET
		
		; invoke mGetString with regular prompt to get val
		mGetString	EDX, EBX, [EBP+16]
		jmp			 _prepForConversion

_invalidStr:
		;	print error msg			
		mDisplayString [EBP+20]
		;	clear input string
		mov			EDI,	[EBP+32]
		mov			ECX,	30
		mov			EAX,	0
		CLD
		REP			STOSB
		;	push params for mGetString with prompt 2
		mov			EDX,		[EBP+28]			; reprompt OFFSET
		mov			EBX,		[EBP+32]			; inputStr OFFSET
		; invoke mGetString with reprompt to get val
		mGetString	EDX, EBX, [EBP+16]
		jmp			 _prepForConversion

_prepForConversion:
		; params for convertAsciiToInt
		push		[EBP+8]							; strValid
		push		[EBP+12]						; numAddress (empty)
		push		[EBP+16]						; byteCount
		push		[EBP+32]						; strAddress (filled)
		
		call		convertAsciiToInt

		; check strValid: if 1 then a valid value has been stored. if 0 jmp _invalidStr.
		pop			EDX
		cmp			EDX,		1									
		jnz			_invalidStr

; restore used registers and EBP then return.
_finishProcedure:
		pop			EDI
		pop			ESI
		pop			EDX	
		pop			ECX		
		pop			EBX
		pop			EAX
		pop			EBP
		ret			28

ReadVal ENDP



; ------------------------
; Procedure Name: WriteVal
; Goal: 
;		Convert an SDWORD signed decimal value to an ASCII string representation. Display that ASCII string.
; Preconditions: 
;		outStr and tmpStr must be empty stings at least 12 bytes long. (SDWORD can be 11 chars long + null)
; Postconditions:
;		outStr contains the ASCII representation of numToConvert. tmpStr is not empty.
;		outStr is displayed.
; Receives:
;		[EBP+8]  = SDWORD numToConvert: for use in convertIntToAscii
;		[EBP+12] = BYTE OFFSET tmpStr: for use in convertIntToAscii and mDisplaySting 
;		[EBP+16] = BYTE OFFSET outStr: for use in convertIntToAscii 
;		[EBP+20] = BYTE OFFSET edgCase: for use in convertIntToAscii (optional)
; ------------------------
WriteVal PROC
		; Setup the stack frame
		push		EBP
		mov			EBP,		ESP

		; convert the stored int to an ASCII string using convertIntToAscii
		push		[EBP+20]
		push		[EBP+16]						; outStr
		push		[EBP+12]						; tmpStr
		push		[EBP+8]							; stored int

		call		convertIntToAscii

		; display the ASCII string
		mDisplayString [EBP+16]

		; restore EBP and return.
		pop			EBP
		ret			16
WriteVal ENDP



; ------------------------
; Procedure Name: ConvertAsciiToInt
; Goal: 
;		Takes a string of ASCII numerical characters and converts the string to the integer it represents. 
; Preconditions: 
;		[EBP+8] must be a string of only ASCII characters. The first character may be + or - to indicate sign.
;		[EBP+16] memory location to calculate and store integer. the value at the location must be 0.
; Postconditions:
;		[EBP+16] memory location to calculate and store integer. Must be size SDWORD 
;		[EBP+20] is the valid str indicator:
;			set if the string is valid
;			clear if invalid: too big for SDWORD or non numerical ascii characters are in the string other than '+' and '-' 
;				at the beginning of the string.
; Receives:
;		[EBP+8]  = OFFSET strAddress (string of ASCII numerical characters)
;		[EBP+12] = DWORD byteCount (length of the strAddress in bytes)
;		[EBP+16] = SDWORD numAddress (where the converted integer is returned and stored) 
;		[EBP+20] = BYTE	strValid (where the validity indicator is returned and stored)
; Returns on the stack:
;		[EBP+20] = DWORD	strValid (set if valid clear if invalid)
; Registers changed (preserved and restored): 
;		EAX, EBX, ECX, EDX, ESI, EDI
; ------------------------
ConvertAsciiToInt PROC
		; Setup the stack frame
		push		EBP
		mov			EBP,		ESP
		; preserve all used registers
		push		EAX
		push		EBX
		push		ECX
		push		EDX
		push		ESI
		push		EDI
		
		mov			ESI,		[EBP+8]				; beginning address of string
		mov			ECX,		0				

		; move the first char of the string into EAX
		mov			EAX,		0					
		CLD											; primitives will increment addresses
		lodsb										; place the first char in EAX.
		; check if the first char is a sign ('+' or '-'). Sign Indicator: push 1 to negate final int push 0 otherwise.
		cmp			AL,		45					; is there a '-'
		jnz			_checkPositive				
		; There is a '-' 
		push		1								; sign indicator: indicates to negate the final answer
		inc			ECX								; move to next char
		mov			EAX,		0
		lodsb
		jmp			_validateCharLoop

_checkPositive: 
		push		0								; sign indicator: indicates to not negate the final answer
		cmp			AL,		43					; is there a '+'
		jnz			_validateCharLoop
		; There is a '+'
		inc			ECX								; move to next char
		mov			EAX,		0
		lodsb
		
; Validate that the character is an ASCII representation of a numerical digit
_validateCharLoop:

		cmp			AL,		48					; check if the ASCII char is below 48 (0)
		jb			_invalidStr					
		cmp			AL,		57					; check if the ASCII char is above 57 (9)
		ja			_invalidStr
		
		; The character is a valid ASCII representation of a digit 1-9.
		; convert the ASCII char to the correct numerical digit val				
		sub			AL,		48
		push		EAX								; preserve digit value
		; multiply the current total by 10
		mov			EDX,		[EBP+16]			; current total stored in memory (num)
		mov			EAX,		[EDX]
		mov			EBX,		10
		imul		EBX
		; add the digit val to the current total
		pop			EBX								; retreive digit value
		add			EAX,		EBX

		; check that the ASCII can be represented by 1 SDWORD.
		; check if the product is greater than 2^31 - 1 (too big for SDWORD)
		cmp			EAX,		2147483647
		jbe			_continueCharLoop				; product is below 2^31 - 1 so its valid
		; check if the product is -2^31
		cmp			EAX,		2147483648			
		jnz			_invalidStr						; if EAX not equal 2^31 jump to invalidStr 
		pop			EDX								; retrieve sign indicator
		push		EDX								; preserve sign indicator
		cmp			EDX,		1
		jnz			_invalidStr						; if the product is 2^31 and sign indicator is not negative its invalid

_continueCharLoop:
		mov			EDX,		[EBP+16]
		mov			[EDX],		EAX					; store the current total

		; check if all numbers in the string have been converted
		inc			ECX
		cmp			ECX,		[EBP+12]			; if ECX reaches byteCount exit loop		
		jae			_checkSign
		; prep for next loop
		mov			EAX,		0					; make sure EAX is clear
		CLD
		lodsb										; move to the next char in the string
		jmp			_validateCharLoop				; continue loop 

_checkSign:
		pop			EBX								; get the sign indicator
		cmp			EBX,		1					; check if the int is supposed to be negative
		jnz			_setStrValid					; if sign indicator clear jmp and do not negate
		; negate the int
		mov			ESI,		[EBP+16]
		mov			EAX,		[ESI]
		neg			EAX
		mov			[ESI],		EAX

_setStrValid:
		mov			EBX,			1
		mov			[EBP+20],		EBX				; set strValid to 1 (indicate valid)
		jmp			_finishProcedure

_invalidStr:
		mov			EBX,		0
		mov			[EBP+20],	EBX
		mov			EDI,		[EBP+16]			; set numAddress back to 0 because no valid int
		mov			EAX,		0
		mov			[EDI],		EAX

		pop			EAX								; remove sign indicator

; restore used registers and EBP then return.
_finishProcedure:
		pop			EDI
		pop			ESI
		pop			EDX	
		pop			ECX		
		pop			EBX
		pop			EAX
		pop			EBP
		ret			12
ConvertAsciiToInt ENDP



; ------------------------
; Procedure Name: ConvertIntToAscii
; Goal: 
;		Takes a valid signed integer value and converts it to it ASCII character representation
; Preconditions: 
;		Int must be able to fit into one register.
;		empty outputString must be 12 bytes long
; Postconditions:
;		the empty string is filled with ASCII chars that represent the int.
; Receives:
;		[EBP+8]  = SDWORD Int signed decimal value to convert to string
;		[EBP+12] = BYTE OFFSET empty tmpString
;		[EBP+16] = BYTE OFFSET empty outputString 
;		[EBP+20] = BYTE OFFSET edgCase: when SDWORD Int is -2^31
; Registers changed (preserved and restored): 
;		EAX, EBX, ECX, EDX, EDI, ESI
; ------------------------
ConvertIntToAscii PROC
		; Setup the stack frame
		push		EBP
		mov			EBP,		ESP
		; preserve all used registers
		push		EAX
		push		EBX
		push		ECX
		push		EDX
		push		ESI
		push		EDI

		mov			EDI,		[EBP+16]			; first address of the output string
		mov			EAX,		[EBP+8]				; signed decimal value
		; EDGE CASE: is the signed decimal exactly -2^31.
		cmp			EAX,		-2147483648
		jnz			_regularCases					; if no jump to regular cases
		; if yes set outputString to -2^31 using edgCase
		mov			ESI,		[EBP+20]
		mov			ECX,		12
		CLD
		REP			MOVSB
		jmp			_finishProcedure

_regularCases:
		; does the signed decimal require a '-' at the first address of the string?
		cmp			EAX,		2147483647
		jbe			_prep							; No: the signed decimal is non-negative	
		mov			EBX,		45
		mov			[EDI],		EBX					; Yes: place a '-' at the first position in the string
		inc			EDI								; move to the next addrss of the string
		neg			EAX								; negate the int for ease of converting to ASCII

_prep:
		push		EDI								; preserve the current address of the output string
		mov			EDI,		[EBP+12]			; first address of temp string
		mov			ECX,		0					; tracks num of chars in tmp string to move to output str
_convertIntToAsciiLoop:
		; divide the int by 10
		mov			EDX,		0
		mov			EBX,		10
		div			EBX								; single digit value in EDX
		add			EDX,		48					; convert the single digit value to ASCII
		; store the ASCII in the tmp string and move to the next address of tmp string
		mov			[EDI],		EDX			
		mov			EDX,		0					; clear EDX
		inc			EDI								
		inc			ECX								; track len of tmp str
		; if at the end of the signed decimal value stop the loop
		cmp			EAX,		0
		ja			_convertIntToAsciiLoop

		; prep for _buildStrLoop
		dec			EDI
		mov			ESI,		EDI					; current address of tmp string
		pop			EDI								; retreive the current address of the output string
_buildStrLoop:
		mov			EAX,		0					; clear accumulator
		; moving backwards through tmp string place each value into output string in order
		STD											; move backwards through the tmp string
		LODSB										; load the ASCII char from the tmp string into AL
		CLD											; move forawrd through output string
		STOSB										; store the value in AL in the output string
		loop		_buildStrLoop					; loop till all values in the tmp string have been moved


; restore used registers and EBP then return.
_finishProcedure:
		pop			EDI
		pop			ESI
		pop			EDX	
		pop			ECX		
		pop			EBX
		pop			EAX
		pop			EBP
		ret			16
ConvertIntToAscii ENDP
END main
