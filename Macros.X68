*-----------------------------------------------------------
* Title      :  Endless Runner
* Written by :  Mirella Glowinska
* Date       :  2023
* Description:  Functions
*-----------------------------------------------------------    

; LOCAL FUNCS
LOC_DRAW_CUBE MACRO
	move.w	D7, D1
	move.w	D7, D3
	
	swap 	D7
	
	move.w	D7, D2
	move.w	D7, D4
	
	swap 	D7
	
	sub.w	D5, D1
	sub.w	D5, D2
	add.w	D5, D3
	add.w	D5, D4
	
	ENDM
	
LOC_DRAW_RECT MACRO
	move.w	D7, D1
	move.w	D7, D3
	
	swap 	D7
	
	move.w	D7, D2
	move.w	D7, D4
	
	swap 	D7
	
	sub.w	D5, D1
	add.w	D5, D3	
	
	swap 	D5
	
	add.w	D5, D4
	sub.w	D5, D2
	
	swap	D5
	
	ENDM

LOC_DRAW_CIRCLE MACRO
	move.w	D7, D1
	move.w	D7, D3
	
	swap 	D7
	
	move.w	D7, D2
	move.w	D7, D4
	
	swap 	D7
	
	sub.w	D5, D1
	sub.w	D5, D2
	add.w	D5, D3
	add.w	D5, D4
	
	ENDM

DRAW_RECTANGLE MACRO
    move    \1,D1
    move    \2,D2
    move    \3,D3
    move    \4,D4
    
    move    #90,D0
    trap    #15
    ENDM
*-----------------------------------------------------------    

DELAY_GAME MACRO
	; framerate control
	moveq	#31, D0
	trap	#15
	IF.L D1 <EQ> #0 THEN ; check last cycles
		moveq 	#30, D0 
		trap	#15
		move.l	#0, cycles_last 
	ELSE ; if cycles are not overflowed
		move.l	cycles_last, D2
		move.l	cycles_spike, D3
		move.l  cycles_delay, D4
		sub.l	D2, D1 ; get difference from last cycle
		add.l   D4, D1 ; add fixed delay
		IF.L D3 <LE> D1 THEN
			REPEAT
				add.l #1, D3 ; simulate threshold
			UNTIL D3 <GE> D1 DO
		ENDI
		sub.l   D4, D1 ; remove delay
		sub.l   #4, D1 ; try lower the threshold
		move.l 	D1, cycles_spike
	ENDI
	
	moveq	#31, D0
	trap	#15
	move.l	D1, cycles_last ; set last cycle checkpoint
	CLEAR_REG
    ENDM
*-----------------------------------------------------
REFRESH_SCREEN MACRO
	IF.B using_double_buff <EQ> #1 THEN
		move	#94, D0		; repaint screen
		trap	#15
	ENDI	
	move	#11, D0		; clear screen                          
    move	#$FF00, D1
    trap	#15
   	ENDM
*-----------------------------------------------------
ENABLE_DOUBLE_BUFF MACRO
	move	#92,d0
	move	#17,d1
	trap	#15
	
	move.b	#1, using_double_buff	
	ENDM
*-----------------------------------------------------
CLEAR_REG MACRO
    clr.l   D0    
    clr.l   D1
    clr.l   D2
    clr.l   D3
    clr.l   D4
    clr.l   D5
    clr.l   D6
    clr.l   D7
    ENDM
*-----------------------------------------------------	
DISABLE_DOUBLE_BUFF MACRO
	move	#92,d0
	move	#16,d1
	trap	#15
	
	move.b	#0, using_double_buff
	ENDM
*-----------------------------------------------------
WRITE_EMPTY_LINE MACRO
	lea		EMPTY_STR, A1
	move	#14,D0            ; Display the NULL terminated string at (A1)
	trap	#15
	ENDM
*----------------------------------------------------
    *(Left X, Upper Y, Right X, Lower Y) 
    * LX = D1.W, UY = D2.W, RX = D3.W, LY = D4.W 
*---------------------------------------------------
DRAW_CIRCLE MACRO
    move    \1,D1
    move    \2,D2
    move    \3,D3
    move    \4,D4
    
    move    #88,D0
    trap    #15
    ENDM
    
*-----------------------------------------------------
*D1 X
*D2 Y
*----------------------------------------------------
DRAW_LINE  MACRO

    move    \1,D1
    move    \2,D2
    move    \3,D3
    move    \4,D4

    move    #84,D0
    trap    #15
    ENDM
*-----------------------------------------------------
* Used:
* D1 - sound cue

* Cleared after:
* D1
PLAY_SOUND MACRO
    move    #75,D0           
    trap    #15
    clr.w   D1
    ENDM
*-----------------------------------------------------	
* Used:
* A0 - array pointer
* D7 - relative X/Y (word/word)

* Cleared after:
* D0-D4

* Max size: DB.W
DRAW_FROM_ARRAY MACRO
    clr.l   D0
    clr.l   D1
    clr.l   D2
    clr.l   D3
    clr.l   D4

   * read array of points
    move.w  (A0)+, D4           ;length
    move.w  (A0)+, D1           ;first x coordinate
    move.w  (A0)+, D2           ;first y coordinate
    add.w   #1, D3              ;increment counter
    
    * add player position to relative points
    add.w   D7, D1
    swap    D7
    add.w   D7, D2
    swap    D7
    
    * draw 
    move    #86, D0
    trap    #15
    
    REPEAT
        * get next points from array
        move.w  (A0)+, D1       ;x
        move.w  (A0)+, D2       ;y
        add.w   #1, D3          ;iteration counter increment
        
        * apply scale to points
        
        add.w   D7, D1          ;relative x
        swap    D7
        add.w   D7, D2          ;relative y
        swap    D7
        
        move    #85, D0
        trap    #15
    UNTIL D3 <GE> D4 DO
    clr.l   D0
    clr.l   D1
    clr.l   D2
    clr     D3
    clr.l   D4
    ENDM
	
*-----------------------------------------------------	
* Used:
* A0 - array pointer
* D5 - scale (word)
* D7 - relative X/Y (word/word)

* Cleared after:
* D0-D4

* Max size: DB.W
* image reflection
DRAW_SCALED_FROM_ARRAY MACRO
    clr.l   D0
    clr.l   D1
    clr.l   D2
    clr.l   D3
    clr.l   D4

   * read array of points
    move.w  (A0)+, D4           ;length
    move.w  (A0)+, D1           ;first x coordinate
    move.w  (A0)+, D2           ;first y coordinate
    add.w   #1, D3              ;increment counter
    
	* scale
	muls	D5, D1
	muls	D5, D2
	
    * add player position to relative points
    add.w   D7, D1
    swap    D7
    add.w   D7, D2
    swap    D7
    
    * draw 
    move    #86, D0
    trap    #15
    
    REPEAT
        * get next points from array
        move.w  (A0)+, D1       ;x
        move.w  (A0)+, D2       ;y
        add.w   #1, D3          ;iteration counter increment
        
        * scale
		muls	D5, D1
		muls	D5, D2
        
        add.w   D7, D1          ;relative x
        swap    D7
        add.w   D7, D2          ;relative y
        swap    D7
        
        move    #85, D0
        trap    #15
    UNTIL D3 <GE> D4 DO
    clr.l   D0
    clr.l   D1
    clr.l   D2
    clr     D3
    clr.l   D4
    ENDM
	
* Max size: DB.W
DRAW_NEG_SCALED_FROM_ARRAY MACRO
    clr.l   D0
    clr.l   D1
    clr.l   D2
    clr.l   D3
    clr.l   D4

   * read array of points
    move.w (A0)+, D4           ;length
    sub.w  (A0)+, D1           ;first x coordinate
    sub.w  (A0)+, D2           ;first y coordinate
    add.w   #1, D3              ;increment counter
    
	* scale
	mulu	D5, D1
	mulu	D5, D2
	
    * add player position to relative points
    add.w   D7, D1
    swap    D7
    add.w   D7, D2
    swap    D7
    
    * draw 
    move    #86, D0
    trap    #15
    
    REPEAT
		clr.l	D1
		clr.l	D1
		
        * get next points from array
        sub.w  (A0)+, D1       ;x
        sub.w  (A0)+, D2       ;y
        add.w   #1, D3          ;iteration counter increment
        
        * scale
		mulu	D5, D1
		mulu	D5, D2
        
        add.w   D7, D1          ;relative x
        swap    D7
        add.w   D7, D2          ;relative y
        swap    D7
        
        move    #85, D0
        trap    #15
    UNTIL D3 <GE> D4 DO
    clr.l   D0
    clr.l   D1
    clr.l   D2
    clr     D3
    clr.l   D4
    ENDM

*-----------------------------------------------------
* Used:
* A0 - array pointer
* D5 - counter (byte)
* D7 - relative X/Y (word/word)

* Warning:
* D6 is cleared after

MULTI_DRAW_FROM_ARRAY MACRO
	clr.l	D6
	REPEAT
		DRAW_FROM_ARRAY
		add.b #1, D6
	UNTIL.B D6 <EQ> D5 DO
	clr		D6
	ENDM

*-----------------------------------------------------
* Used:
* D5 - scale (word)
* D6 - width,height (word,word) 
* D7 - X,Y (word,word)

* Cleared after:
* D3-D4

* Post:
* D5 - scale (byte)
* D6 - scaled width/scaled height (word,word)
* D7 - relative X,Y (word/word)

* Max size: DB.W
APPLY_POSITION_MODIFIERS MACRO
    * apply new scale to create relative position
    * Top/Left align
    sub.w   D6, D7
    swap    D6
    swap    D7
    sub.w   D6, D7
    swap    D6
    swap    D7
    ENDM
	
*-----------------------------------------------------
* Apply scale
* Used:	
* \1 - scale (DC.W)
* \2 - Width/Height (DC.W/DC.W), modified after

* Warning:
* Don't use D0

APPLY_SCALE MACRO
	* unpack width/height
	clr.l 	D0
	move.w  \2, D0  ; save x to D0
    clr.w	\2		; clear x part
	swap	\2		; set to y
    
	* multiply by scale
	muls	\1, D0
	muls	\1, \2
	
	* save results
	swap	\2		; set to cleared x
	move.w	D0, \2	; save it again
	clr.l 	D0
	
	ENDM
*-----------------------------------------------------
* Apply relative position (Top-Left align)
* Used:	
* \1 - Width/Height (DC.W/DC.W)
* \2 - X/Y position (DC.W/DC.W), modifier after (relative x/y)

* Warning:
* Don't use D0 and D1

APPLY_RELATIVE_POS MACRO
	sub.w	\1, \2	; substract x
	swap	\1
	swap	\2
	sub.w	\1, \2 	; substract y
	swap	\1
	swap	\2
	ENDM

*-----------------------------------------------------      
* Used:
* D6 - scaled width/scaled height (word,word)
* D7 - relative X,Y (word/word) (from Top-Left align)

* Post:
* D6 - relative X2,Y2 (word,word)
* D7 - relative X,Y (word/word)

* Max size: DB.W
TRANSFORM_SIZE_TO_POS MACRO
    add.w   D7, D6
    swap    D6
    swap    D7
    add.w   D7, D6
    swap    D6
    swap    D7
    
    ENDM
*-----------------------------------------------------      
* Used:
* A0 - Object reference

* Post:
* D5 - scale (word)
* D6 - width/height (word/word)
DECODE_OBJECT MACRO
    clr.l   D6
    clr.l   D5

    move.w  (A0)+, D5       ;scale
    move.w  (A0)+, D6       ;x
    swap    D6
    move.w  (A0)+, D6       ;y
    swap    D6
    ENDM
	
	
*-----------------------------------------------------      
* Used:
* \1 - Object reference (A)
* \2 - Out scale (DC.W)
* \3 - Out Width/Height (DC.W/DC.W)

* Post:
* D5 - scale (word)
* D6 - width/height (word/word)
NDECODE_OBJECT MACRO
    clr.l   \2
    clr.l   \3

    move.w  (\1)+, \2       ;scale
    move.w  (\1)+, \3       ;x
    swap    \3
    move.w  (\1)+, \3       ;y
    swap    \3
    ENDM

*-----------------------------------------------------
* Used:

PRINT_GAMEOVER MACRO
    
    move.l  #WHITE,D1
    move.l  #TITLE_FONT,D2
    move.b  #21,D0              ; set font
    trap    #15
    
    move    #11,D0              ; set default cursor position
    move    #$0802,D1           ; column , row 
    trap    #15

    lea     GAMEOVER,A1
    move    #14,D0
    trap    #15
    
    move.l  #WHITE,D1
    move.l  #DEFAULT_FONT,D2
    move.b  #21,D0              ; set font
    trap    #15

    
    move    #11,D0              ; set default cursor position
    move    #$1B08,D1           ; column , row 
    trap    #15
    *Clear registers to display correct number
    CLEAR_REG                  
    
    move    #3,D0               ; display number
    move    score, D1
    trap    #15
        
    move    #11,D0              ; set cursor position
    move    #$1508,D1           ; column , row 
    trap    #15
    
    lea     PLAYER_SCORE, A1
    move    #14, D0
    trap    #15
    
    ENDM
    
    
*-----------------------------------------------------
  ;Randomize number
* Used: 
* \1 - Offset (DC.W)
* \2 - Range (DC.W)
* \3 - Output (Register) NOT D1

* Cleared after:
* D0-D1

GET_RANDOM_NUMBER MACRO
	clr.l	D1
	clr.l	D0
	move	#8, D0
	trap	#15		; load system time on D1
	move.w  D1, D0  ; save only 16 bits
	clr.l   D1      ; clear remaining data
	exg     D1, D0  ; return values
		
	divs    \2, D1	; get random number from dividing
	clr.w	D1		; clear division
    swap    D1		; get modulo
	
	add.l	\1, D1	
    move.w  D1, \3	; save number on selected register
	
    ENDM
*-----------------------------------------------------
* unfilled cube
* Used:
* D7 - x/y	(DC.W/DC.W)
* D5 - scale (DC.W)

* Cleared after:
* D0-D4

DRAW_UCUBE MACRO
	LOC_DRAW_CUBE
	
	move    #90, D0
	trap	#15
		
	clr	D0
	clr	D1
	clr	D2
	clr	D3
	clr	D4
	
	ENDM

*-----------------------------------------------------
* filled cube
* Used:
* D7 - x/y	(DC.W/DC.W)
* D5 - scale (DC.W)

* Cleared after:
* D0-D4

DRAW_FCUBE MACRO
	LOC_DRAW_CUBE
	
	move    #87, D0
	trap	#15
		
	clr	D0
	clr	D1
	clr	D2
	clr	D3
	clr	D4
	
	ENDM
	
*-----------------------------------------------------
* filled rectangle
* Used:
* D7 - x/y	(DC.W/DC.W)
* D5 - width/height (DC.W/DC.W)

* Cleared after:
* D0-D4

DRAW_FRECT MACRO
	LOC_DRAW_RECT
	
	move    #87, D0
	trap	#15
		
	clr	D0
	clr	D1
	clr	D2
	clr	D3
	clr	D4
	
	ENDM

*-----------------------------------------------------
* filled circle
* Used:
* D7 - x/y	(DC.W/DC.W)
* D5 - scale (DC.W)

* Cleared after:
* D0-D4 

DRAW_FCIRCLE MACRO
	LOC_DRAW_CIRCLE
	
	move    #88, D0
	trap	#15
		
	clr	D0
	clr	D1
	clr	D2
	clr	D3
	clr	D4
	
	ENDM
*-----------------------------------------------------
* unfilled circle
* Used:
* D7 - x/y	(DC.W/DC.W)
* D5 - scale (DC.W)

* Cleared after:
* D0-D4

DRAW_UCIRCLE MACRO
	LOC_DRAW_CIRCLE
	
	move    #91, D0
	trap	#15
		
	clr	D0
	clr	D1
	clr	D2
	clr	D3
	clr	D4
	
	ENDM
*-----------------------------------------------------------    
* set background color
* Used:
* (DC.L) input

SET_BACKGROUND_COLOR MACRO
	move.l 	\1, D1
	move	#81, D0
	trap	#15
	ENDM	
*-----------------------------------------------------------    
* set foreground color
* Used:
* D1 - Color (DC.L)

SET_FOREGROUND_COLOR MACRO
	move.l 	\1, D1
	move	#80, D0
	trap	#15
	ENDM
*-----------------------------------------------------------    
* prepare enumeration data
* Used:
* \1 - Vector Array pointer (A)

* After:
* D0 - Lower 16 bits current counter / higher 16 bits counter limit

READ_VECTOR MACRO
	clr.l	D0
	move.w	(\1)+,D0
	ENDM
	
*-----------------------------------------------------------    
* move to next array position (use after READ_ARRAY)
* Used:
* \1 - Vector Array pointer (A)
* \2 - Data output (D), data format x,y (DC.W/DC.W)

READ_VECTOR_NEXT MACRO
	clr.l	\2
	move.w	(\1)+,\2
	swap	\2
	move.w	(\1)+,\2
	swap	\2
	
	swap	D0
	add.w	#1, D0
	swap	D0
	ENDM

*-----------------------------------------------------------    
* check if array contains values
* \1 - Data temporary output

* After:
* D0 - If position is on the end of array, 0 (DC.L) is returned.

READ_CHECK MACRO
	clr.l	\1
	move.w	D0, \1	; move array length on selected register
	swap	D0		; swap to counter
	IF.W D0 <GE> \1 THEN ; position still in array
		clr.l	D0	    ; mark as end of array
	ELSE
		swap	D0
	ENDI
	clr.w	\1
	ENDM
	

*-----------------------------------------------------------    
* get value with swap
* Used:
* \0 - Data length (DC.B, DC.W)
* \1 - Read from and swap (D)
* \2 - Save to (D)

READ_SWAP MACRO
	move.\0	\1, \2
	swap	\1
	ENDM
	
*-----------------------------------------------------------    
* set value with swap
* Used:
* \0 - Data length (DC.B, DC.W)
* \1 - Read from (D)
* \2 - Save to and swap (D)

SAVE_SWAP MACRO
	move.\0 \1, \2
	swap	\2
	ENDM
*-----------------------------------------------------------    
* save counter in RAM memory

DUMP_VECTOR_VALUES MACRO
    move.l  D0, vector_cache
    clr.l	D0
	ENDM
*-----------------------------------------------------------    
* load counter from RAM memory

LOAD_VECTOR_VALUES MACRO
    move.l  vector_cache, D0
	ENDM
	
*-----------------------------------------------------------    
* save values to previous positions of vector
* \1 - Array position (A)
* \2 - Input x/y (DC.W/DC.W)

SAVE_VECTOR MACRO
	sub		#4, \1
	move.w	\2, (\1)+
	swap	\2	; to y
	move.w	\2, (\1)+
	swap	\2	; to x
	ENDM

*-----------------------------------------------------------    
* \1 - Unpack target (DC.L)
* \2 - first save location (DC.W)
* \3 - second save location (DC.W)

UNPACK_VALUES MACRO
	READ_SWAP.w	\1, \2
	READ_SWAP.w	\1, \3	
	ENDM

*-----------------------------------------------------------    
* \1 - first value (DC.L)
* \2 - second value (DC.W)
* \3 - Pack location (DC.W)

PACK_VALUES MACRO
	SAVE_SWAP.w	\1, \3
	SAVE_SWAP.w	\2, \3	
	ENDM

*-----------------------------------------------------------    
* \1 - Unpack target (DC.L)
* \2 - save location (DC.W)

UNPACK_HIGHER_BITS MACRO
    swap    \1
    move.w  \1, \2
    clr.w   \1
    swap    \1
	ENDM
	
*-----------------------------------------------------------    
* Rescales settings. Used along with [[RESCALE_VECTOR_ARRAYS]].
* Use only once.
* A0 - Object settings (An)

RESCALE_SETTINGS MACRO
	NDECODE_OBJECT A0, D6, D2
    UNPACK_HIGHER_BITS D2, D3       ; D2 - x, D3 - y
    ; apply scale  
    muls    D6, D2
    muls    D6, D3            
    ; save on 1 register
    swap    D2
    move.w  D3, D2
    swap    D2
    SAVE_VECTOR A0, D2 
	ENDM

*-----------------------------------------------------------    
* Rescales large amount of points in possible quickest way
* Use after [[RESCALE_SETTINGS]]
* A1 - Arrays first position (An)
* D5 - Arrays count (DC.B)

* Warning:
* Arrays have to be placed in sequence. Risky option.
	
RESCALE_VECTOR_ARRAYS MACRO   
    REPEAT
        * prepare read procedure
        READ_VECTOR A1
        READ_CHECK  D7
        REPEAT
            READ_VECTOR_NEXT A1, D2
            UNPACK_HIGHER_BITS D2, D3
            ; apply scale    
            muls    D6, D2
            muls    D6, D3
            ; save on 1 register
            swap    D2
            move.w  D3, D2
            swap    D2
            SAVE_VECTOR A1, D2
            ; check if end is reached
            READ_CHECK D7
        UNTIL.L D0 <EQ> #0 DO
            
        add.b   #1, temp_counter
    UNTIL.B temp_counter <EQ> D5 DO   
    move.b  #0, temp_counter
	ENDM







*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
