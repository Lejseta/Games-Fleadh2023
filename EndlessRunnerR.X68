;*-----------------------------------------------------------
* Title      :  Endless Runner
* Written by :  Mirella Glowinska
* Date       :  2023
* Description:
*-----------------------------------------------------------    

* All functions
    INCLUDE "./Macros.X68"

*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* Game start
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

START ORG    $2000      ; first instruction of program
    bsr INIT            ; load all necessary components    
    bsr MODELCONF       ; recalculate scale on the start (optimization)
    bsr MENU            ; create selection menu
    REFRESH_SCREEN
    bsr GAME_INIT       ; set game components/settings
    * Game loop
    REPEAT
        REFRESH_SCREEN
    
        bsr INPUT       ; check input
        bsr PHYSICS        ; calculate movement
        bsr DRAW        ; draw objects
        bsr DRAW_UI     ; UI draw
        
        ;bsr GIZMOS     ; debug drawing
        
        DELAY_GAME
        
    UNTIL.B collision <EQ> #1 DO
    REFRESH_SCREEN
    bsr ON_EXIT
    jmp START
    
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* Reset all the variables and display GAMEOVER & final game score
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
ON_EXIT:

    * Set default values
    move.b   #0,score_counter
    move.b   #$01,game_speed 
    move.b   #0,force_clock
    move.b   #1,grounded
    move.b   #0,jump_force_timer
    move.b   #2,obstacle_sp_scale
    move.b   #0,collision
    move.b   #0, motorframe_force
    move.b   #0, motorframe_y_offset
    move.b   #0, last_impact_force
    move.b   #0, fuel_picked_up
    ;move.b   #0, escape_game
    
    move.w   #0, speech_bubble_clock
    move.w   #540, human_x                   
    move.w   #1530,human_x_max
    move.w   #540,human_x_min
    move.w   #940, human_y  
    move.w   #0,force 
    move.w   #0,jump_force
    move.w   #28,jump_force_max
    move.w   #12,jump_force_min
    move.w   #2048,obstacle_x
    move.w   #100,fuel
    
    move.l   #0,distance_val
    
    *turn off voices and music
    move.l  #3, D2
    move.b  #MOTORBIKE_CUE, D1        
    move    #77, D0
    trap    #15
    
    move.b  #MUSIC_CUE, D1        
    move    #77, D0
    trap    #15
    
    DISABLE_DOUBLE_BUFF
    REFRESH_SCREEN
    PRINT_GAMEOVER
        
    move.l  #0,score                      ;finally clear game score
    
    move.l  #100,D1
    move.b  #23,D0                        ; delay 5 seconds
    trap    #15
    
    *reset processor cycles
    move    #30,D0
    trap    #15

    CLEAR_REG           
END_ON_EXIT:
    rts
    
    
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* load dependencies, files
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
INIT:
    DISABLE_DOUBLE_BUFF
    
    move.l  #3, D2
    move    #77, D0
        
    trap    #15
                
    lea     LANDSOUND_WAV, A1           ;load land.wav
    move    #TOUCH_GROUND_CUE, D1        ;sound cue
    move    #74,D0
    trap    #15
                    
    lea     MOTORBIKE_WAV, A1           
    move    #MOTORBIKE_CUE, D1            
    move    #74,D0
    trap    #15
    
    lea     MUSIC_WAV, A1           
    move    #MUSIC_CUE, D1            
    move    #74,D0
    trap    #15
    
    clr        D1
    move.w  screen_width, D1        ;set default aspect ratio    
    swap     D1
    move.w    screen_height, D1
    move    #33, D0
    trap    #15
    
    move    #2, D1
    move    #93, D0
    trap    #15

END_INIT:
    rts
    
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* Precalculate model points (width, height). Optimization
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
MODELCONF:
    CLEAR_REG
    IF.B models_rescaled <EQ> #1 THEN
        rts
    ELSE ; protect from rescalling again
        move.b  #1, models_rescaled
    ENDI
    
    ; for sure it's all clear
MOTORBIKE_RECALC:
    ; prepare starting point
    lea     HUMAN_SETTINGS, A0
    lea     MOTORBIKE_LEFT_TIRE, A1
    move.b  #8, D5
    RESCALE_SETTINGS
    RESCALE_VECTOR_ARRAYS

    lea     HUMAN_SETTINGS, A0    ; reset pointer    
    lea     MOTORBIKE_HUMAN_R, A1 ; same situation here
    RESCALE_VECTOR_ARRAYS
    
OBSTACLE_RECALC:    
    lea     CAR_SETTINGS, A0
    lea     CAR, A1
    move.b  #3, D5
    RESCALE_SETTINGS
    RESCALE_VECTOR_ARRAYS
       
    lea     CAR2_SETTINGS, A0
    lea     CAR2, A1
    move.b  #3, D5
    RESCALE_SETTINGS
    RESCALE_VECTOR_ARRAYS
    
    lea     STOP_SETTINGS, A0
    lea     SIGN, A1
    move.b  #5, D5
    RESCALE_SETTINGS
    RESCALE_VECTOR_ARRAYS
    
AIRPLANE_RECALC:    
    lea     AIRPLANE_SETTINGS, A0
    lea     AIRPLANE_FRAME, A1
    move.b  #5, D5
    RESCALE_SETTINGS
    RESCALE_VECTOR_ARRAYS
    
FUEL_RECALC:
    lea     FUEL_SETTINGS, A0
    lea     BOX, A1
    move.b  #3, D5
    RESCALE_SETTINGS
    RESCALE_VECTOR_ARRAYS
    
UI_RECALC:
    lea     UI_SETTINGS, A0
    lea     UI_MID, A1
    move.b  #2, D5
    RESCALE_SETTINGS
    RESCALE_VECTOR_ARRAYS

UI_MIRROR_RECALC:
    lea     MIRROR_SETTINGS, A0
    lea     RIGHT_MIRROR, A1
    move.b  #2, D5
    RESCALE_SETTINGS
    RESCALE_VECTOR_ARRAYS
    
    lea     SMALLER_MIRROR_SETTING, A0
    lea     S_RIGHT_MIRROR, A1 
    RESCALE_SETTINGS
    RESCALE_VECTOR_ARRAYS
    
UI_MIRROR_REFLECTIONS_RECALC:
    lea     CAR_REFLECTION_SETTINGS, A0
    lea     LEFT_CAR_FRAME_REFLECTION, A1
    move.b  #3, D5
    RESCALE_SETTINGS
    RESCALE_VECTOR_ARRAYS
    
    lea     AIRPLANE_REFLECTION_SETTINGS, A0
    lea     LEFT_AIRPLANE_FRAME_REFLECTION, A1
    move.b  #6, D5
    RESCALE_SETTINGS
    RESCALE_VECTOR_ARRAYS
    
END_MODELCONF:
    CLEAR_REG
    rts
    
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* load game values, configs
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GAME_INIT:
    GET_RANDOM_NUMBER   #1,#4,random_number 
    ENABLE_DOUBLE_BUFF
    
    move.l  #1, D2
    move.b  #MOTORBIKE_CUE, D1        
    move    #77, D0
    trap    #15
    
    move.b  #0, collision                       ; set collision flag

END_GAME_INIT:
    rts
    
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* menu
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
MENU:
    move.l  #1, D2
    move.b  #MUSIC_CUE, D1        
    move    #77, D0
    trap    #15

    REPEAT
    
        move    #11, D0                          ; set default cursor position
        move    #$0501,D1                        ;col row
        trap    #15

        move.l  #WHITE, D1
        move.l  #TITLE_FONT, D2                  
        move.b  #21, D0                          ;set font
        trap    #15
        *TITLE
        lea     TITLE, A1
        move    #14,D0
        trap    #15
        
       
        *OPTIONS
        move    #11,D0                          ; set default cursor position
        move    #$1306,D1                       ;col row
        trap    #15
        
        move.l  #WHITE, D1
        move.l  #DEFAULT_FONT, D2                 
        move.b  #21,D0                          ;set font
        trap    #15
        
        lea        OPTIONS, A1
        move    #14,D0                            ;Display the NULL terminated string at (A1)
        trap    #15
        
        lea        ENTER_NO, A1
        move    #14,D0
        trap    #15
    
        move    #5,D0                            ;Read a number from the keyboard into D1.L.
        trap    #15
        WRITE_EMPTY_LINE
        
        IF.B D1 <NE> #$031 THEN
            IF.B D1 <EQ> #$032 THEN               ; Author info
                bsr SETIINGS
            ENDI
            IF.B D1 <EQ> #$033 THEN
                *turn off voices and music
                move.l  #3, D2
                move.b  #MOTORBIKE_CUE, D1        
                move    #77, D0
                trap    #15
    
                move.b  #MUSIC_CUE, D1        
                move    #77, D0
                trap    #15
               STOP #$2700
               jmp PROGRAM_EXIT             
            ENDI
        ENDI
        WRITE_EMPTY_LINE
    UNTIL.B D1 <EQ> #$031 DO
    
END_MENU:
    ClEAR_REG

    rts
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* input checker
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

INPUT:       
BOOST:
    move.l  #$10, D1  ;shift
    move    #19,D0
    trap    #15
    
    move.l   D1,D7   ;save results

    IF.B  D7 <EQ> #$FF THEN
          move.b  #1, nitro
    ENDI
    IF.B D7 <EQ> #$00 THEN
        move.b  #0, nitro

    ENDI   
    
    CLEAR_REG
MOVEMENT:
     move.l #'S'<<24+'A'<<16+'D'<<8+'W',D1
        
     move    #19,D0 
     trap    #15
     move.l  D1, D7  ;save results
     move.w  speech_bubble_clock,D3
     IF.B D3 <GE> #100 THEN
        * Jump
        IF.B jump_shock <EQ> #0 THEN
            IF.B grounded <EQ> #1 THEN
                IF.B D7 <EQ> #$FF THEN ;charge jump
                    move.w jump_force, D5
                    IF D5 <EQ> #0 THEN
                        move.w  jump_force_min, D5
                        move.w  D5, jump_force
                    ENDI
                    clr     D5
                ELSE                   ;jump on release
                    move.w jump_force, D5
                    IF D5 <GE> jump_force_min THEN
                        move.w  D5, force
                        move.w  D5, jump_force_last
                        move.b  #0, grounded
                        move.w  #0, jump_force
                        sub.w   #1, fuel
                    ENDI
                    clr     D5
                ENDI
            ENDI
        ENDI
        
        * Move right (d)
        move.b  #0, D7
        asr.l   #8, D7
    
        IF.B D7 <EQ> #$FF  THEN                            ;go right
            move.w  human_x, D5
            IF D5 <LT> human_x_max THEN
                add.w   #5, D5
                move.w  D5, human_x
                IF.B #1 <EQ> nitro THEN
                    add.w   #5, D5
                    move.w  D5, human_x
                ENDI
            ENDI
            clr.w   D5
        ENDI
        
         * Move left (a)
        move.b  #0, D7
        asr.l   #8, D7
        IF.B D7 <EQ> #$FF THEN                            ;go left
            move.w  human_x, D5
            IF D5 <GT> human_x_min THEN
                sub.w   #4, D5
                move.w  D5, human_x
                IF.B #1 <EQ> nitro THEN
                    sub.w   #5, D5
                    move.w  D5, human_x
                ENDI

            ENDI
            clr.w   D5
        ENDI
        
         * Faster falling (s)
        move.b  #0, D7
        asr.l   #8, D7
        IF.B D7 <EQ> #$FF THEN
            move.b  #0, force_clock     ;force flag
        ENDI
    ENDI
       
    clr     D0
    clr.l   D1
    clr.l   D7
    
END_INPUT:
    CLEAR_REG
    rts

*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* calculations, update every frame
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
PHYSICS:
CALC_JUMP_FORCE:
    move.w jump_force, D5

    IF.W D5 <GE> jump_force_min THEN
        IF.W D5 <LT> jump_force_max THEN
            move.b  jump_force_timer, D6
            add.b   #1, D6
            
            IF D6 <GE> #3 THEN
                add.w   #1, D5
                move.w  D5, jump_force
                move.b  #0, D6
            ENDI
            move.b  D6, jump_force_timer
            clr.l   D6
        ENDI
    ELSE
        move.b #0, jump_force_timer     ; reset timer
    ENDI
    CLEAR_REG
    
CALC_DISTANCE:
    move.w  distance_val, D7
    move.b  game_speed, D6
    add.l   D6, D7
    
    IF.L D7 <GE> #$EFFF THEN
        sub.l  #$EFFF, D7
    ENDI
    
    move    D7, distance_val
    CLEAR_REG
    
CALC_SCORE:
    move.b  score_counter, D6
    add.b  game_speed, D6
    IF.B D6 <GE> #10 THEN
        move    score, D7
        add     #1, D7
        sub.b   #10, D6
        move    D7, score
        clr.l   D7
    ENDI
    move.b  D6, score_counter
    CLEAR_REG
    
CALC_GAME_SPEED:
    move.b  game_speed, D6
    IF D6 <LT> #10 THEN
        move    score, D7
        move    #GAME_SPEED_CURVE, D5        ; game speed limit
        move    D6, D4          ; copy game speed
        muls    D4, D4          ; calculate power 2
        muls    D5, D4          ; calculate difficulty curve
    
        IF D7 <GE> D4 THEN
            add.b   #1, D6
            move.b  D6, game_speed
        ENDI
        clr.l   D7
        clr.l   D5
        clr.l   D4
    ENDI    
    CLEAR_REG

CALC_FORCE_UPDATE:
    move.b  force_clock, D1
    move.b  jitter_clock, D2
    
    IF D1 <EQ> #0 THEN
        move.b  #1, D1
    ELSE
        move.b  #0, D1
    ENDI
    
    * jitter speed
    IF D2 <EQ> #2 THEN        
        move.b  #0, D2
    ELSE
        add.b   #1, D2
    ENDI
    
    move.b  D1, force_clock
    move.b  D2, jitter_clock
 
    IF.B grounded <EQ> #0 THEN   ; If not grounded  
        move.w  force, D7
        move.w  human_y, D6
    
        IF D7 <GE> #0 THEN
            IF.B D1 <EQ> #1 THEN
                sub.w   #1, D7   ;lower the force
            ENDI
        ENDI 
        
        * human physics
        IF D7 <GT> #10 THEN
            move.w  D7, D5  ; temp calc
            sub.w   #10, D5
            sub.w   D5, D6
            clr.w   D5
        ELSE
            move.w  #10, D5 ; temp calc
            sub.w   D7, D5
            add.w   D5, D6
            clr.w   D5
        ENDI
        
        * land procedure
        IF D6 <GT> walking_level THEN         ;reset all values
            move    #TOUCH_GROUND_CUE, D1
            PLAY_SOUND
            
            move.w  walking_level, D6
            move.w  #0, D7
            move.b  #1, grounded
            move.b  #1, jump_shock            ;lock jump
            move.b  #3, motorframe_force
            move.w  jump_force_last, D0
            move.b  D0, last_impact_force
        ENDI
        
        move.w  D6, human_y
        move.w  D7, force
    ENDI   
    IF.B jump_shock <EQ> #1 THEN ; If grounded and shocked
        clr.l D7
        clr.l D6
        move.b  motorframe_force, D7
        move.b  motorframe_y_offset, D6
        move.b  last_impact_force, D4
                    
        IF.B D7 <GT> #0 THEN
            IF.B D2 <EQ> #0 THEN
                sub.b   #1, D7
            ENDI 
        ENDI
        
        * motorbike jitter
        IF.B D7 <GT> #10 THEN
            move.b  D7, D5  ; temp calc
            sub.b   #10, D5
            add.b   D5, D6
            
            IF.B D6 <GT> motorframe_y_max THEN
                move.b  motorframe_y_max, D6
            ENDI
            clr.w   D5
        ELSE
            move.b  #10, D5  ; temp calc
            sub.b   D7, D5
            sub.b   D5, D6
            
            IF.B D6 <LT> motorframe_y_min THEN
                move.b  motorframe_y_min, D6
                IF.B D4 <GT> #4 THEN
                    divs    #2, D4  ; lower impact force
                    move.b  D4, D7  ; set force jitter 
                    move.b  D4, last_impact_force ; set new impact force
                ENDI
            ENDI          
            clr.w   D5
        ENDI
            
        IF D4 <LE> #4 THEN
            move.b  #0, jump_shock  ; unlock jump
            move.b  #0, D7
            move.b  #10, D6
        ENDI
        
        move.b  D7, motorframe_force
        move.b  D6, motorframe_y_offset
        clr.w   D4     
    ENDI
   
    CLEAR_REG
    
CALC_FUEL_LEVEL:
    move.b  fuel_clock, D1
    move.b  game_speed, D0
    move.b  fuel_limit, D2
    IF.B #1 <EQ> nitro THEN
        move.b #40,D2
        move.b D2, fuel_limit
    ENDI
    IF.B #0 <EQ> nitro THEN
        move.b #100,D2
        move.b D2,fuel_limit
    ENDI
    divs    #2, D0    
    add.b   D0, D1
   
    IF D1 <GE> D2 THEN
        sub.b   D2, D1
        
        move.w  fuel, D3
        sub.w   #1, D3
        IF.W D3 <LE> #0 THEN
            move.w  #0, D3
            move.b  #1, collision
        ENDI
        move.w  D3, fuel
        clr.w   D3
    ENDI
    
    move.b  D1, fuel_clock
    clr.l   D2
    clr.l   D1
    clr.l   D0
   
CALC_CHECK_FUEL:   
    move.w  fuel_box_x, D4  
    move.b  game_speed, D0
    sub.w   D0, D4
    
    clr.b   D0
    
    IF.W D4 <LT> #0 THEN
        ; offset + range, save on register
        ; 4000   + 0-6000, save on D4
        GET_RANDOM_NUMBER #4000, #6000, D4
        GET_RANDOM_NUMBER #750, #100, D3
        move.w  D3, fuel_box_y
        move.b  #0, fuel_picked_up ; reset 
    ENDI
    move.w  D4, fuel_box_x
    clr.w   D4
    
CALC_AIRPLANE:
    move.w  airplane_x, D4
    move.b  game_speed, D0
    
    sub.w   D0, D4
    clr.b   D0
    
    IF.W D4 <LT> #0 THEN
        GET_RANDOM_NUMBER #2000, #4000, D4
        GET_RANDOM_NUMBER #650, #50, D3
        move.w  D3, airplane_y
        clr.w   D3
    ENDI
    move.w   D4, airplane_x
    clr.w    D4
    
CALC_OBSTACLE:
    move.w  obstacle_x, D4
    move.b  game_speed, D0
    move.b  obstacle_sp_scale, D7
    muls    D7, D0
    clr.b   D7
    
    sub.w   D0, D4
    clr.b   D0
    
    IF.W D4 <LT> #0 THEN ; obstacle type control
        GET_RANDOM_NUMBER #2000, #1000, D4
        GET_RANDOM_NUMBER #1, #3, D3

        IF.W D3 <EQ> #1 THEN 
            lea     CAR_SETTINGS, A6
            NDECODE_OBJECT A6, D2, D0
            move.b  #3, obstacle_arr_points
            lea     CAR, A0
            move.l  A0, obstacle_arr_ptr                
            move.w  #60, obstacle_coll_y_offset
        ELSE
            IF.W D3 <EQ> #2 THEN 
                lea     CAR2_SETTINGS, A6
                NDECODE_OBJECT A6, D2, D0
                move.b  #3, obstacle_arr_points
                lea     CAR2, A0
                move.l  A0, obstacle_arr_ptr
                move.w  #25, obstacle_coll_y_offset
            ENDI
            IF.W D3 <EQ> #3 THEN 
                lea     STOP_SETTINGS, A6
                NDECODE_OBJECT A6, D2, D0
                move.b  #5, obstacle_arr_points
                lea     SIGN, A0
                move.l  A0, obstacle_arr_ptr
                move.w  #0, obstacle_coll_y_offset
            ENDI
        ENDI
        move.w  D0, obstacle_width
        swap    D0
        move.w  D0, obstacle_height
        clr.l   D0
    ENDI

    move.w  D4, obstacle_x
    clr.w   D4
    
CALC_COLLIDERS:
    * get human position
    move.w  human_x, D7
    swap    D7
    move.w  human_y, D7
    swap    D7
    
    * read human constants
    lea     HUMAN_SETTINGS, A0
    
    DECODE_OBJECT
    
    clr.l   D5      ; clear scale (not used)    
    clr.w   D6      ; remove width
    swap    D6      ; get height (the same value)
    divs    #2, D6  ; get center relative point (also it's radius)
    sub.w   D6, D7  ; sub radius to create x center
    swap    D7
    sub.w   D6, D7
    swap    D7
    
    * get obstacle
    move.w  obstacle_x, D1 ; x
    IF.W D1 <LE> screen_width THEN
    swap    D1
    move.w  walking_level, D1   ; y
    add.w   obstacle_coll_y_offset, D1
    ; without swap
    move.w  obstacle_width, D2

    divs    #2, D2  ; divide by 2 to get relative center point
    sub.w   D2, D1  ; set y to the center
    swap    D1
    sub.w   D2, D1  ; set x to the center
        
    * sphere colliders (obstacle)
    * (from https://flatredball.com/documentation/tutorials/math/circle-collision/)
    * free D0, D3, D4, D5
    
    move.w  D6, D0  ; set human radius
    add.w   D2, D0  ; add obstacle radius
    mulu    D0, D0  ; pow2
    
    move.w  D1, D3  ; set obstacle x center
    sub.w   D7, D3  ; sub human x center
    swap    D7  
    swap    D1
    
    move.w  D1, D4  ; set obstacle y center
    sub.w   D7, D4  ; sub human y center
    swap    D1  
    swap    D7
   
    muls    D3, D3  ; pow2 signed   
    muls    D4, D4  ; pow2 signed
    
    move.l  D3, D5
    add.l   D4, D5
   
    IF.L D5 <LE> D0 THEN
        * collision occured
        move.b  #1, collision
    ENDI
    
    clr.l   D0
    clr.l   D1
    clr.l   D2
    clr.l   D3
    clr.l   D4
    clr.l   D5
    ENDI
    
    IF.B fuel_picked_up <EQ> #0 THEN ; calculate fuel
    * get fuel
    move.w  fuel_box_x, D1 ; x
    swap    D1
    move.w  fuel_box_y, D1 ; y
    ; without swap, not necessary
    
    lea     FUEL_SETTINGS, A0
    move.w  (A0)+, D2   ; skip scale
    move.w  (A0)+, D2   ; width
    divs    #2, D2      ; get radius from width
    
    sub.w   D2, D1  ; set y to the center
    swap    D1
    sub.w   D2, D1  ; set x to the center
           
    * sphere colliders (fuel)    
    move.w  D6, D0  ; set human radius
    add.w   D2, D0  ; add obstacle radius
    mulu    D0, D0  ; pow2
    
    move.w  D1, D3  ; set obstacle x center
    sub.w   D7, D3  ; sub human x center
    swap    D7  
    swap    D1
    
    move.w  D1, D4  ; set obstacle y center
    sub.w   D7, D4  ; sub human y center
    swap    D1  
    swap    D7
   
    muls    D3, D3  ; pow2 signed   
    muls    D4, D4  ; pow2 signed
    
    move.l  D3, D5  ; save first pow2 on D5
    add.l   D4, D5  ; add second pow2
   
    IF.L D5 <LE> D0 THEN ; check if pows are lower than total radius
        * collision occured
        move.b  #1, fuel_picked_up
        move.w  #100, fuel 
        add.w   #50, score          ; adding 50 points
        move.b  #0, fuel_color_clock
       
    ENDI
    
    clr.l   D0
    clr.l   D1
    clr.l   D2
    clr.l   D3
    clr.l   D4
    clr.l   D5
    ENDI ; calculate fuel or not
    
    move.w  airplane_x,D1
    IF.W D1 <LT> screen_width THEN
    *sphere colliders (airplane)
    *get airplane x and y
    swap    D1
    move.w  airplane_y,D1
    
    lea     AIRPLANE_SETTINGS, A0
    move.w  (A0)+, D2   ; skip scale
    move.w  (A0)+, D2   ; width
    divs    #2, D2      ; get radius from width
    
    sub.w   D2, D1      ; set y to the center
    swap    D1
    sub.w   D2, D1      ; set x to the center
           
    * sphere colliders (airplane)    
    move.w  D6, D0      ; set human radius
    add.w   D2, D0      ; add obstacle radius
    mulu    D0, D0      ; pow2
    
    move.w  D1, D3      ; set obstacle x center
    sub.w   D7, D3      ; sub human x center
    swap    D7  
    swap    D1
    
    move.w  D1, D4     ; set obstacle y center
    sub.w   D7, D4     ; sub human y center
    swap    D1  
    swap    D7
   
    muls    D3, D3     ; pow2 signed   
    muls    D4, D4     ; pow2 signed
    
    move.l  D3, D5     ; save first pow2 on D5
    add.l   D4, D5     ; add second pow2
   
    IF.L D5 <LE> D0 THEN ; check if pows are lower than total radius
        * collision occured
        move.b  #1, collision
    ENDI
    
    clr.l   D0
    clr.l   D1
    clr.l   D2
    clr.l   D3
    clr.l   D4
    clr.l   D5
    ENDI

    CLEAR_REG
    
END_PHYSICS:
    CLEAR_REG
    rts    

*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* draw every frame
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

CALC_TEST_VECTOR:
    lea  STARS_ARRAY,A6     ; stars array
    
    * prepare read procedure
    READ_VECTOR A6
    READ_CHECK  D1
    REPEAT
        * read next position of array
        READ_VECTOR_NEXT A6, D1
        UNPACK_VALUES D1, D2, D3
        * save counter to RAM memory
        DUMP_VECTOR_VALUES
        
        move.b  game_speed, D0
        IF D2 <LE> #0 THEN  
            * reset star position
            move.w  #1920, D2
            GET_RANDOM_NUMBER #100, #300, D3
        ELSE
            * decrease x position
            sub.w   D0, D2
        ENDI
        
        * save changed values
        PACK_VALUES D2, D3, D7 ; (x,y, target)
        SAVE_VECTOR A6, D7
        
        lea  STAR_SETTINGS, A0  ; star model settings
    
        NDECODE_OBJECT A0, D5, D6
        APPLY_POSITION_MODIFIERS
        
        lea STAR, A0            ; star model vectors       
        DRAW_FROM_ARRAY
        
        CLEAR_REG
        
        * load counter from memory
        LOAD_VECTOR_VALUES
        * prevent from reading out of bounds
        READ_CHECK  D1
    UNTIL.L D0 <EQ> #0 DO
    
    CLEAR_REG
    
DRAW:
DRAW_BACKGROUND:
    move.b  #1,D1
    move    #93,D0
    trap    #15
    *hardcoded stars
    move.w  #500, D7      
    swap    D7
    move.w  #570, D7
    swap    D7
        
    lea     STAR_SETTINGS, A0        
    DECODE_OBJECT
    APPLY_POSITION_MODIFIERS
    
    lea     STAR, A0
    * they are placed together in RAM
    DRAW_FROM_ARRAY
    
    move.w  #800, D7      
    swap    D7
    move.w  #650, D7
    swap    D7
        
    lea     STAR_SETTINGS, A0        
    DECODE_OBJECT
    APPLY_POSITION_MODIFIERS
    
    lea     STAR, A0
    DRAW_FROM_ARRAY
    
    move.w  #1000, D7      
    swap    D7
    move.w  #560, D7
    swap    D7
        
    lea     STAR_SETTINGS, A0        
    DECODE_OBJECT
    APPLY_POSITION_MODIFIERS
    
    lea     STAR, A0
    DRAW_FROM_ARRAY
    

    move.w  #1200, D7      
    swap    D7
    move.w  #700, D7
    swap    D7
        
    lea     STAR_SETTINGS, A0        
    DECODE_OBJECT
    APPLY_POSITION_MODIFIERS
    
    lea     STAR, A0
    DRAW_FROM_ARRAY

    move.w  #1440, D7      
    swap    D7
    move.w  #550, D7
    swap    D7
        
    lea     STAR_SETTINGS, A0        
    DECODE_OBJECT
    APPLY_POSITION_MODIFIERS
    
    lea     STAR, A0
    DRAW_FROM_ARRAY
    
    move.w  #430, D7      
    swap    D7
    move.w  #740, D7
    swap    D7
        
    lea     STAR_SETTINGS, A0        
    DECODE_OBJECT
    APPLY_POSITION_MODIFIERS
    
    lea     STAR, A0
    DRAW_FROM_ARRAY
    ;set up pen again 
    move.b  #2,D1
    move    #93,D0
    trap    #15      
DRAW_FLOOR:
    * Bottom layer
    move    #0, D1                ;X1
    move    floor_level, D2       ;Y1
    move    screen_width, D3      ;X2 
    move    floor_level, D4       ;Y2
    
    move    #84,D0
    trap    #15
    
    * Upper layer
    move    #0, D1                ;X1
    move    upper_floor_level, D2 ;Y1
    move    screen_width, D3      ;X2 
    move    upper_floor_level, D4 ;Y2
    
    move    #84,D0
    trap    #15
    
    * Floor details
    clr.l   D7
    clr.l   D6                      ;clear 32 bits (because of ignoring 16 upper bits in moving)
    
    move.b  floor_clock, D6
    add.b   game_speed, D6
    add.b   obstacle_sp_scale, D6

    move.b  detail_offset, D5
    
    IF.B D6 <GE> D5 THEN
        sub.b   D5, D6        
    ENDI
    
    move.b  D6, floor_clock
    clr.l   D7

    move    screen_height, D4    ;Y2
    move    floor_level, D2      ;Y1
    REPEAT
        add.b   #1, D7           ;counter
        
        move    D7, D1           ;X1
        muls    D5, D1           ;Multiply by offset
        sub     D6, D1    
        move    D1, D3
        sub     D5, D3           ;X2
       
        move    #84,D0
        trap    #15
    UNTIL.B D7 <GE> D5 DO    
    CLEAR_REG
    
DRAW_OBSTACLE:  
    move.w  obstacle_x, D7      ;x
    swap    D7
    move.w  walking_level, D7   ;y
    swap    D7
    
    move.w  obstacle_width, D6
    swap    D6
    move.w  obstacle_height, D6
    swap    D6
    APPLY_POSITION_MODIFIERS
    clr.l   D6
    
    move.l  obstacle_arr_ptr, A0
    move.b  obstacle_arr_points, D5
    clr     D0
    * Macro works with custom drawing parts count
    MULTI_DRAW_FROM_ARRAY
    clr     D0
    CLEAR_REG   
DRAW_FUEL:    
    IF.B fuel_picked_up <EQ> #0 THEN
        move.w  fuel_box_x, D7      
        swap    D7
        move.w  fuel_box_y, D7
        swap    D7
        
        lea     FUEL_SETTINGS, A0
            
        DECODE_OBJECT
        APPLY_POSITION_MODIFIERS
    
        lea     BOX, A0
        DRAW_FROM_ARRAY
    
        lea     F_L, A0
        DRAW_FROM_ARRAY
        
        lea    F_HOLDER, A0
        DRAW_FROM_ARRAY
   
        CLEAR_REG  
    ENDI  
       
DRAW_AIRPLANE:
    move.w  airplane_x, D7      
    IF.W D7 <LT> screen_width AND D7 <GE> ui_width THEN
    swap    D7
    move.w  airplane_y, D7
    swap    D7
        
    lea     AIRPLANE_SETTINGS, A0        
    DECODE_OBJECT
    APPLY_POSITION_MODIFIERS
    
    lea     AIRPLANE_FRAME, A0
    * they are placed together in RAM
    DRAW_FROM_ARRAY
    DRAW_FROM_ARRAY
    DRAW_FROM_ARRAY
    DRAW_FROM_ARRAY
    DRAW_FROM_ARRAY
    CLEAR_REG 
    ENDI
    clr.l   D7   

DRAW_PLAYER:
DRAW_MOTORBIKE_FRAME:
    
    * get and pack human position
    move.w  human_x, D7
    swap    D7
    move.w  human_y, D7
    swap    D7
    
    * read human constants
    lea     HUMAN_SETTINGS, A0
        
    DECODE_OBJECT
    APPLY_POSITION_MODIFIERS
    
    move.b  grounded,D4
    IF.B D4 <EQ> #1 THEN
        * get drawing arrays
        lea     MOTORBIKE_LEFT_TIRE, A0
        DRAW_FROM_ARRAY ; left tire
        DRAW_FROM_ARRAY ; right tire
        DRAW_FROM_ARRAY ; left suspension
        DRAW_FROM_ARRAY ; right suspension
           
        move.b  motorframe_y_offset, D0
    
        * jitter effect    
        IF.B jump_shock <EQ> #1 THEN
            swap    D7
            IF.B D0 <GT> 10 THEN
                add.w   D0, D7          
            ELSE
                sub.w   D0, D7
            ENDI
            swap    D7
        ENDI
    
        lea     MOTORBIKE_FRAME, A0
        DRAW_FROM_ARRAY ; motorbike frame
        DRAW_FROM_ARRAY ; human
        DRAW_FROM_ARRAY ; human helmet
        DRAW_FROM_ARRAY ; back
    ELSE
        lea     MOTORBIKE_HUMAN_R, A0
        DRAW_FROM_ARRAY ; left tire
        DRAW_FROM_ARRAY ; right tire
        DRAW_FROM_ARRAY ; left suspension
        DRAW_FROM_ARRAY ; right suspension        
        DRAW_FROM_ARRAY ; left tire
        DRAW_FROM_ARRAY ; right tire
        DRAW_FROM_ARRAY ; left suspension
        DRAW_FROM_ARRAY ; right suspension
    ENDI
    CLEAR_REG

END_DRAW:
    CLEAR_REG
    rts
    
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* Draw UI
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

DRAW_UI:
    * get and pack I position
    move.w  top_ui_x, D7
    swap    D7
    move.w  top_ui_y, D7
    swap    D7
    
    * read UI constants
    lea     UI_SETTINGS, A0
        
    DECODE_OBJECT
    APPLY_POSITION_MODIFIERS
    
    lea     UI_DOWN, A0
    DRAW_FROM_ARRAY
    
    CLEAR_REG
    
DRAW_FRAME_UI:
     *line joining
    DRAW_LINE   #1015,#150,#885,#150
    *right circle frame
    DRAW_CIRCLE #1000,#50,#1350,#400 
    DRAW_CIRCLE #1020,#70,#1330,#380
    *left circle frame
    DRAW_CIRCLE #550,#50,#900,#400 
    DRAW_CIRCLE #570,#70,#880,#380
    
    *-------draw clock right--------
    DRAW_LINE   #1045,#220,#1020,#220
    DRAW_LINE   #1330,#220,#1305,#220
    *45 deg  right clock
    DRAW_LINE   #1305,#170,#1315,#165
    *stright 
    DRAW_LINE   #1175,#75,#1175,#95 
    *45 deg left
    DRAW_LINE   #1040,#165,#1050,#170
   
    
    *--------draw clock left------
    DRAW_LINE   #570,#220,#595,#220
    DRAW_LINE   #850,#220,#875,#220
    
    *45 deg right clock
    DRAW_LINE   #825,#135,#840,#123
    DRAW_LINE   #850,#170,#860,#165
    *stright 
    DRAW_LINE   #725,#75,#725,#95 
    *45 deg left
    DRAW_LINE   #610,#123,#625,#135 
    DRAW_LINE   #590,#165,#600,#170
   
    clr.l D1
    clr.l D2
    clr.l D3
    clr.l D4
    
    *---draw steering wheel--------
    *bottom
    DRAW_LINE   #550,#510,#1350,#510
    *right 
    DRAW_LINE   #1280,#420,#1350,#420
    *deg
    DRAW_LINE  #1350,#420,#1400,#390
    DRAW_LINE  #1350,#510,#1400,#480
    DRAW_LINE  #1400,#390,#1520,#330
    DRAW_LINE  #1400,#480,#1520,#420
    *left
    DRAW_LINE   #555,#420,#625,#420
    *deg
    DRAW_LINE  #505,#390,#555,#420
    DRAW_LINE  #503,#480,#553,#510
    DRAW_LINE  #400,#330,#505,#390
    DRAW_LINE  #400,#420,#505,#480
   
    clr.l D1
    clr.l D2
    clr.l D3
    clr.l D4
    *---------draw btn-------------
    move.l  button_coordynates, D7
    move.w  button_width, D5
    SET_BACKGROUND_COLOR #WHITE      
   
    DRAW_FCIRCLE   
    SET_BACKGROUND_COLOR #BLACK
    sub.w   #10, D5
    DRAW_FCIRCLE
     
    DRAW_CIRCLE #915,#405,#993,#330
    
    *--------draw masking----------
    SET_BACKGROUND_COLOR #WHITE   
    DRAW_CIRCLE #1150,#530,#1090,#430
    DRAW_CIRCLE #760,#530,#820,#430
    SET_BACKGROUND_COLOR #BLACK
    DRAW_CIRCLE #1135,#475,#1105,#445
    DRAW_CIRCLE #1135,#490,#1105,#520
    
    DRAW_CIRCLE #775,#475,#805,#445
    DRAW_CIRCLE #775,#490,#805,#520
       
    CLEAR_REG
    
DRAW_UI_FUEL_BAR:
    move.l  top_ui_left_center, D7
    move.w  top_ui_center_width, D5
    
    move.w  fuel, D6 
    muls    #3, D6
    
    IF.W D6 <GT> #255 THEN
        SET_BACKGROUND_COLOR #LIME
    ELSE
        move.l  #LIME, D1
        move.b  #255, D0
        sub.b   D6, D0
        * from green to red
        add.w   D0, D1
        lsl.l   #8, D0
        sub.w   D0, D1
        SET_BACKGROUND_COLOR D1
        
    ENDI
    
    sub.w   #2, D5 
    * meter circle
    DRAW_FCIRCLE  
    
    sub.w   #40, D5
    SET_BACKGROUND_COLOR #BLACK
    DRAW_FCIRCLE
     
    CLEAR_REG

DRAW_UI_JUMP_BAR:
   
    move.l  top_ui_right_center, D7
    move.w  top_ui_center_width, D5
    move.w  jump_force, D3
     
    IF.B jump_shock <EQ> #0 THEN
        IF.W D3 <GE> jump_force_min THEN
            move.w  jump_force,D2
            sub.w   jump_force_min, D2
            muls.w  #13, D2
            SET_BACKGROUND_COLOR #GREEN 
            IF.W D2 <GT> #70 THEN
                SET_BACKGROUND_COLOR #ORANGE 
            ENDI
            IF.W D2 <GT> #150 THEN
                SET_BACKGROUND_COLOR #RED
                clr.l   D0
            ENDI        
            move.w  D2, D6  ; save results
            DRAW_FCIRCLE
        ENDI
    ENDI
   
    ; mask
    SET_BACKGROUND_COLOR #BLACK
    SET_FOREGROUND_COLOR #BLACK
    move.w  D7, D1
    move.w  D7, D3
    swap    D7
    move.w  D7, D2
    move.w  D7, D4
   
    sub.w   D5, D1
    add.w   D5, D3
    sub.w   D5, D2
    
    add.w   D6, D1
    
    move    #87, D0
    trap    #15
    
    clr.l   D0
    clr.l   D1
    clr.l   D2
    clr.l   D3
    clr.l   D4
             
    SET_FOREGROUND_COLOR #WHITE 
    sub.w   #20, D5
    DRAW_FCIRCLE
    
    DRAW_LINE  #1075,#222,#1115,#222
    DRAW_LINE  #1235,#222,#1280,#222
       
    SET_BACKGROUND_COLOR #BLACK
    CLEAR_REG

DRAW_UI_CIRCLES:
    SET_FOREGROUND_COLOR #WHITE
    move.l  top_ui_left_center, D7
    move.w  top_ui_center_width, D5 ; scale 
    DRAW_UCIRCLE
    
    move.l  top_ui_right_center, D7
    DRAW_UCIRCLE
    sub.w   #40, D5
    DRAW_FCIRCLE
    
    CLEAR_REG

DRAW_UI_MASK:
    *right
    move.l  top_ui_right_center, D7
    move.w  top_ui_center_width, D5 ; height
    divs    #2, D5
    swap    D7
    add.w   D5, D7
    swap    D7
    swap    D5
    move.w  top_ui_center_width, D5 ; width
    
    SET_FOREGROUND_COLOR #BLACK
    DRAW_FRECT
    *left
    clr.l   D7
    clr.l   D5                      ;to avoid wrong calculations
    move.l  top_ui_left_center, D7
    move.w  top_ui_center_width, D5 ; height
    divs    #2, D5
    swap    D7
    add.w   D5, D7
    swap    D7
    swap    D5
    move.w  top_ui_center_width, D5 ; width
    DRAW_FRECT
    SET_FOREGROUND_COLOR #WHITE
        
    CLEAR_REG
    
DRAW_UI_TIPS:
    *tip
    *x1,y1,x2,y2  x2,y2 constant
    DRAW_LINE   #1180,#170,#1185,#310 
    DRAW_LINE   #1165,#310,#1180,#170 
    *right
    DRAW_CIRCLE #1150,#250,#1200,#300
    *screws
    DRAW_CIRCLE #1100,#260,#1120,#280
    DRAW_LINE   #1105,#280,#1116,#260 
    DRAW_LINE   #1105,#260,#1116,#280 

    DRAW_CIRCLE #1230,#260,#1250,#280
    DRAW_LINE   #1235,#280,#1245,#260 
    DRAW_LINE   #1235,#260,#1245,#280 
    *left
    
    *x1,y1,x2,y2  x2,y2 constant
    DRAW_LINE    #730,#170,#735,#310  
    DRAW_LINE    #715,#310,#730,#170 
    *right
    DRAW_CIRCLE #700,#250,#750,#300
    *screws
    DRAW_CIRCLE #650,#260,#670,#280
    DRAW_LINE   #655,#280,#665,#260 
    DRAW_LINE   #655,#260,#665,#280 

    DRAW_CIRCLE  #780,#260,#800,#280
    DRAW_LINE    #785,#280,#795,#260 
    DRAW_LINE    #785,#260,#795,#280 

   
    clr.l D1
    clr.l D2
    clr.l D3
    clr.l D4
    
    *RIGH GUAG (METER)
    *45 deg right clock later to avoid glitch;
    DRAW_LINE   #1270,#135,#1285,#123
    DRAW_LINE   #1235,#100,#1240, #90
    DRAW_LINE   #780,#100,#785,#90
    *45 deg left
    DRAW_LINE   #1065,#123,#1080,#135 
    DRAW_LINE   #1115,#100,#1110, #90 
    DRAW_LINE  #665,#100,#660, #90 
    CLEAR_REG
    
DRAW_UI_COLUMNS:
    move.w  ui_width, D7
    move    #87, D0
        
    * left column
    move.w  #0, D1
    move.w  #0, D2
    move.w  D7, D3
    move.w  screen_height, D4
    
    trap    #15
    
    * right column
    move.w  screen_width, D1
    move.w  #0, D2
    move.w  D1, D3
    move.w  screen_height, D4
    sub.w   D7, D3
    
    trap    #15
   *--------------------------------------    
DRAW_UI_SCORE:
    move.l  #WHITE,D1   
    move.l  #SCORE_FONT,D2
    move    #21,D0
    trap    #15
    
    move    #11,D0                              ; set default cursor position
    move    #$3701,D1                           ; column, row
    trap    #15
    
    ;move    #11,D0                              ; set default cursor position
    ;move    #$4101,D1                           ; column, row
    ;trap    #15
     IF.B fuel_color_clock <LT> #100 THEN 
        move.l  #LIME, D1
        move.l  #SCORE_FONT, D2                 
        move.b  #21,D0                          ;set font
        trap    #15
        add.b  #1, fuel_color_clock
    ENDI 

    clr.l   D1                                  ; to do not get wrong score 
    move    #3,D0                               ; display number
    move    score, D1
    trap    #15
        
    move    #11,D0                              ; set cursor position
    move    #$3001,D1                           ; column, row
    trap    #15
    
    lea     PLAYER_SCORE, A1
    move    #14, D0
    trap    #15
    CLEAR_REG
    
DRAW_UI_FUEL:
    move.l  #WHITE,D1   
    move.l  #MENU_FONT,D2
    move    #21,D0
    trap    #15
    
    move    #11,D0
    move    #$2C0D,D1                           ;column 14, row 1
    trap    #15                                 ;display number
       
   IF.B fuel_color_clock <LT> #100 THEN
        move.l  #LIME, D1
        move.l  #MENU_FONT, D2                 
        move.b  #21,D0                          ;set font
        trap    #15
        add.b   #1, fuel_color_clock
    ENDI 
    
    lea     PLAYER_FUEL,A1
    move    #14,D0
    trap    #15 
    
    move    #11,D0                              ; set default cursor position
    move    #$320D,D1                           
    trap    #15
    clr.l   D1
    move    #3,D0                               ; display number
    move    fuel, D1
    trap    #15
    clr.l   D1
    
    move    #1,D1
    move    #93,D0
    trap    #15
    DRAW_RECTANGLE #650, #310, #810,#335 
  
    CLEAR_REG
DRAW_JUMP_UI:
    move.l  #WHITE, D1
    move.l  #MENU_FONT, D2                 
    move.b  #21,D0                              ;set font
    trap    #15
    
    move    #11,D0                              ; set default cursor position
    move    #$4A0D,D1                           
    trap    #15

    lea      PLAYER_JUMP,A1
    move     #14,D0
    trap     #15      
    DRAW_RECTANGLE #1100, #310, #1263,#335 
    CLEAR_REG
    
DRAW_UI_GAME_SPEED:
   
    move    #11,D0                              ; set default cursor position
    move    #$3F0F,D1                          
    trap    #15
    clr.l   D1                                  ;to get right level
    clr.l   D2  
    
    move    #3,D0                               ; display number
    move.b  game_speed, D1
    trap    #15
    
    move.l  #WHITE,D1   
    move.l  #LEVEL_FONT,D2

    move    #21,D0
    trap    #15    
    move    #11,D0                              ; set cursor position
    move    #$470B,D1                           
    trap    #15
    
    lea     GAME_SPEED_LEVEL, A1
    move    #14, D0
    trap    #15
    
    CLEAR_REG
DRAW_UI_MIRRORS:
        move    #2,D1
        move    #93,D0
        trap    #15
        *RIGHT
        move.w  mirror_right_x, D7      
        swap    D7
        move.w  mirror_right_y, D7
        swap    D7
        
        lea     MIRROR_SETTINGS, A0
            
        DECODE_OBJECT
        APPLY_POSITION_MODIFIERS
    
        lea     RIGHT_MIRROR, A0
        DRAW_FROM_ARRAY
        *smaller mirror
        
        move.w  mirror_right_x, D7 
        sub.w   #20,D7     
        swap    D7
        move.w  mirror_right_y, D7
        sub.w   #22,D7
        swap    D7
        
        lea     MIRROR_SETTINGS, A0
        lea     SMALLER_MIRROR_SETTING,A0
        DECODE_OBJECT
        APPLY_POSITION_MODIFIERS

        lea     S_RIGHT_MIRROR, A0
        DRAW_FROM_ARRAY
        
        *LEFT
        move.w  mirror_left_x, D7      
        swap    D7
        move.w  mirror_left_y, D7
        swap    D7
        
        lea     MIRROR_SETTINGS, A0
            
        DECODE_OBJECT
        APPLY_POSITION_MODIFIERS
    
        lea     LEFT_MIRROR, A0
        DRAW_FROM_ARRAY
        *smaller mirror
        
        move.w  mirror_left_x, D7 
        sub.w   #20,D7     
        swap    D7
        move.w  mirror_left_y, D7
        sub.w   #22,D7
        swap    D7
        
        lea     MIRROR_SETTINGS, A0
        lea     SMALLER_MIRROR_SETTING,A0
        DECODE_OBJECT
        APPLY_POSITION_MODIFIERS

        lea     S_LEFT_MIRROR, A0
        DRAW_FROM_ARRAY
        *mirrors fixing
        DRAW_LINE   #360,#310,#400,#400 
        DRAW_LINE   #360,#430,#400,#450 
        
        DRAW_LINE   #1520,#400,#1562,#310 
        DRAW_LINE   #1520,#450,#1560,#430
        *image inside
        DRAW_LINE   #40,#300,#330,#300 
        DRAW_LINE   #1590,#300,#1880,#300   
        
         
        move.w  #200, D7      
        swap    D7
        move.w  #250, D7
        swap    D7
        
        lea     STAR_SETTINGS, A0        
        DECODE_OBJECT
        APPLY_POSITION_MODIFIERS
    
        lea     STAR, A0
        DRAW_FROM_ARRAY
        
        move.w  #100, D7      
        swap    D7
        move.w  #190, D7
        swap    D7
        
        lea     STAR_SETTINGS, A0        
        DECODE_OBJECT
        APPLY_POSITION_MODIFIERS
    
        lea     STAR, A0
        DRAW_FROM_ARRAY
        
        
        move.w  #1690, D7      
        swap    D7
        move.w  #250, D7
        swap    D7
        
        lea     STAR_SETTINGS, A0        
        DECODE_OBJECT
        APPLY_POSITION_MODIFIERS
    
        lea     STAR, A0
        DRAW_FROM_ARRAY
        
        move.w  #1800, D7      
        swap    D7
        move.w  #190, D7
        swap    D7
        
        lea     STAR_SETTINGS, A0        
        DECODE_OBJECT
        APPLY_POSITION_MODIFIERS
        
        lea     STAR, A0
        DRAW_FROM_ARRAY
        


        CLEAR_REG 

*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* speech bubble
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

    move.w  speech_bubble_clock,D7
   
    IF.W  D7 <LE> #100 THEN
        move.l  #WHITE, D1
        move.l  #SMALL_FONT, D2                  
        move.b  #21, D0                          ;set font
        trap    #15

        DRAW_CIRCLE #420,#700,#600,#790
        DRAW_CIRCLE #500,#800,#510,#810
        DRAW_CIRCLE #500,#830,#510,#840
        clr.l D1
        clr.l D2
        clr.l D3
        clr.l D4
        move    #11,D0                          ; set default cursor position
        move    #$3731,D1                       ;col row
        trap    #15
        
        IF.W    random_number  <EQ> #1 THEN 
            lea        BUBBLE_SPEECH_1, A1
            move    #14,D0
            trap    #15
            
            move    #11,D0                          ; set default cursor position
            move    #$3832,D1                       ;col row
            trap    #15
            
            lea        BUBBLE_SPEECH_11, A1
            move    #14,D0
            trap    #15     
        ENDI
        IF.W    random_number  <EQ> #2 THEN 
            lea        BUBBLE_SPEECH_2, A1
            move    #14,D0
            trap    #15     
        ENDI
          IF.W    random_number  <EQ> #3 THEN 
            lea        BUBBLE_SPEECH_3, A1
            move    #14,D0
            trap    #15
             
            move    #11,D0                          ; set default cursor position
            move    #$3832,D1                       ;col row
            trap    #15
            
            lea        BUBBLE_SPEECH_33, A1
            move    #14,D0
            trap    #15     
        ENDI
          IF.W    random_number  <EQ> #4 THEN 
            lea        BUBBLE_SPEECH_4, A1
            move    #14,D0
            trap    #15
            move    #11,D0                          ; set default cursor position
            move    #$3832,D1                       ;col row
            trap    #15
            lea        BUBBLE_SPEECH_44, A1
            move    #14,D0
            trap    #15     
        ENDI    
        
        add.w  #1, D7
    ENDI 
    move.w D7,speech_bubble_clock 
END_DRAW_UI
    CLEAR_REG
    rts
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* Debug drawings, like colliders visualization
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
GIZMOS:
    move.l  #BLUE, D1
    move    #80, D0
    IF.B collision <EQ> #1 THEN
        move.l  #RED, D1
    ENDI
    trap    #15
    
GIZMOS_MOTORBIKE:
    * get human position
    move.w  human_x, D7
    swap    D7
    move.w  human_y, D7
    swap    D7
    
    * read human settings
    lea     HUMAN_SETTINGS, A0
    
    DECODE_OBJECT
    
    move.w  D7, D1 
    swap    D7
    move.w  D7, D2
    swap    D7
    
    APPLY_POSITION_MODIFIERS
    
    move.w  D7, D3
    swap    D7
    move.w  D7, D4
    swap    D7
        
    move    #91, D0
    trap    #15
    
    CLEAR_REG
    
GIZMOS_OBSTACLE:
    move.w  obstacle_x, D7
    swap    D7
    move.w  walking_level, D7  ;Y1
    add.w   obstacle_coll_y_offset, D7
    swap    D7
   
    * read obstacle settings    
    move.w  D7, D1 
    swap    D7
    move.w  D7, D2
    swap    D7
    
    move.w  obstacle_width, D6
    swap    D6
    move.w  obstacle_height, D6
    swap    D6
    APPLY_POSITION_MODIFIERS
    
    move.w  D7, D3
    swap    D7
    move.w  D7, D4
    swap    D7
        
    move    #91, D0
    trap    #15
    CLEAR_REG

GIZMOS_FUEL: 
    move.w  fuel_box_x, D7
    swap    D7
    move.w  fuel_box_y, D7
    swap    D7
    
    lea     FUEL_SETTINGS, A0
        
    DECODE_OBJECT
    APPLY_POSITION_MODIFIERS
    TRANSFORM_SIZE_TO_POS
    
    move.w  D7, D1
    swap    D7
    move.w  D7, D2
    swap    D7
    move.w  D6, D3
    swap    D6
    move.w  D6, D4
    swap    D6   
    
    move    #91, D0
    trap    #15
    
    CLEAR_REG
    
AIRPLANE_GIZMOS:
    move.w  airplane_x, D7
    swap    D7
    move.w  airplane_y, D7
    swap    D7
    
    lea     AIRPLANE_SETTINGS, A0
        
    DECODE_OBJECT
    APPLY_POSITION_MODIFIERS
    TRANSFORM_SIZE_TO_POS
       
    move.w  D7, D1 
    swap    D7
    move.w  D7, D2
    swap    D7
    move.w  D6, D3
    swap    D6
    move.w  D6, D4
    swap    D6   
    
    move    #91, D0
    trap    #15
   
END_GIZMOS:
    SET_FOREGROUND_COLOR #WHITE
    CLEAR_REG
    rts
LOADING_SCREEN:
    CLEAR_REG
    move.w  loading_screen_clock,D7
    IF.W D7 <LE>  #100 THEN
    IF.B loading_screen_showed <EQ> #0  THEN
    
        move.b  #1,D1
        move    #93,D0
        trap    #15
        *hardcoded stars
        move.w  #500, D7      
        swap    D7
        move.w  #570, D7
        swap    D7
        
        lea     STAR_SETTINGS, A0        
        DECODE_OBJECT
        APPLY_POSITION_MODIFIERS
    
        lea     STAR, A0
        * they are placed together in RAM
        DRAW_FROM_ARRAY
        clr.l   D1
        clr.l   D2
        clr.l   D3
        clr.l   D4
        
        move    #800,D1
        move    #200,D2
        move    #1100,D3
        move    #500,D4
        
        move    #88,D0
        trap    #15
        
        move    #850,D1
        move    #250,D2
        move    #1050,D3
        move    #450,D4
        
        move    #88,D0
        trap    #15
        clr.l  D1
        clr.l  D2
        clr.l  D3
        clr.l  D4 
        DRAW_LINE #850,#350,#1045,#350
        DRAW_LINE #950,#250,#950,#450
        DRAW_LINE #880,#280,#1017,#415
        DRAW_LINE #880,#415,#1017,#280
        move    #11, D0                          ; set default cursor position
        move    #$100D,D1                        ;col row
        trap    #15
        
        move.b  #1, loading_screen_showed
        lea        LOADING_TEXT, A1
        move    #14,D0
        trap    #15
            
        ;move.l  #100,D1
        ;move.b  #23,D0                        ; delay 5 seconds
        ;trap    #15  
        REFRESH_SCREEN
        clr.l    D7
    ENDI
    add.w  #1,D7    
    ENDI
    move.w D7, loading_screen_clock 
    ;move.l  #3, D2
    ;move.b  #MUSIC_CUE, D1        
    ;move    #77, D0
    ;trap    #15
END_LOADING_SCREEN
    CLEAR_REG
    rts
SETIINGS:
    REFRESH_SCREEN 
    *OPTIONS        

    REPEAT
        REFRESH_SCREEN
        
        lea    GRAPHICS_SETTINGS, A1
        move    #14,D0                           ;Display the NULL terminated string at (A1)
        trap    #15
         IF.B  low_picked <EQ> #1 THEN
            move.l  #RED, D1
            move.l  #DEFAULT_FONT, D2                 
            move.b  #21,D0                       ;set font
            trap    #15
            move.b  #0, high_picked
        ENDI
         

        lea     LOW, A1
        move    #14,D0                          
        trap    #15
        
        move.l  #WHITE, D1
        move.l  #DEFAULT_FONT, D2                 
        move.b  #21,D0                         
        trap    #15
        
        IF.B  high_picked <EQ> #1 THEN
            move.l  #BLUE, D1
            move.l  #DEFAULT_FONT, D2                 
            move.b  #21,D0                       
            trap    #15
            move.b  #0,  low_picked

        ENDI
        lea        HIGH, A1
        move    #14,D0                           
        trap    #15
        
        move.l  #WHITE, D1
        move.l  #DEFAULT_FONT, D2                 
        move.b  #21,D0                           ;set font
        trap    #15
        
        lea        ENTER_NO, A1
        move    #14,D0
        trap    #15
    
        move    #5,D0                            ;Read a number from the keyboard into D1.L.
        trap    #15
        ;WRITE_EMPTY_LINE
        
        
        IF.B D1 <EQ> #$032 THEN                    
            move.b #1,high_picked
            move.b #0,low_picked
            move.l  #500,cycles_delay
    
        ENDI
        
        IF.B D1 <EQ> #$031 THEN
            move.b #1,low_picked
            move.b #0,high_picked
            move.l  #0,cycles_delay
        ENDI

        WRITE_EMPTY_LINE
    UNTIL.B D1 <EQ> #ESCAPE DO
    REFRESH_SCREEN
END_SETTINGS:
    CLEAR_REG
    rts
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* values, memory data
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-----------------------------------------------------
* consts and strings
*-----------------------------------------------------
CR                  EQU      $0D            ;Carriage Return
LF                  EQU      $0A            ;Line feed
ESCAPE              EQU     $1B         

RED                 EQU $000000FF
LIME                EQU $0000FF00
GREEN               EQU $00008000
BLUE                EQU $00FF0000
ORANGE              EQU $0000AAFF   
BLACK               EQU $00000000
WHITE               EQU $00FFFFFF
LEVEL_FONT          EQU $03100070
MENU_FONT           EQU $04120001
SCORE_FONT          EQU $04150001
SCORE2_FONT         EQU $04170001
DEFAULT_FONT        EQU $02300000
TITLE_FONT          EQU $02700000
SMALL_FONT          EQU $00000000

GAME_SPEED_CURVE    EQU 80
TITLE               DC.B 'MIDNIGHT WHEELS',CR,LF,0
EMPTY_STR            DC.B '',CR,LF,0
OPTIONS             DC.B 'PRESS 1 TO PLAY',CR,LF
                    DC.B '                   PRESS 2 FOR OPTIONS',CR,LF
                    DC.B '                   PRESS 3 TO EXIT',CR,LF
                    DC.B '                            ',CR,LF
                    DC.B '                   Select option',CR,LF,0
                    
LOADING_TEXT        DC.B 'PREPARING MOTORCYCLE...',CR,LF,0

ENTER_NO             DC.B '               Please enter a number ',0

AUTHOR_NAME          DC.B 'W  JUMP',CR,LF
                    DC.B 'A  LEFT',CR,LF
                    DC.B 'D  RIGHT',CR,LF,0
BUBBLE_SPEECH_1     DC.B '   Press SHIFT',CR,LF,0
BUBBLE_SPEECH_11    DC.B '  to speed up',CR,LF,0

BUBBLE_SPEECH_2     DC.B '   I am speed!',CR,LF,0
BUBBLE_SPEECH_3     DC.B ' Press A W and D',CR,LF,0
BUBBLE_SPEECH_33    DC.B '    to move',CR,LF,0
BUBBLE_SPEECH_4     DC.B 'Every jump consumes',CR,LF,0
BUBBLE_SPEECH_44    DC.B 'one point of fuel',CR,LF,0
PLAYER_SCORE        DC.B 'Score:',CR,LF,0
GAME_SPEED_LEVEL    DC.B 'Level',CR,LF,0
PLAYER_FUEL         DC.B 'Fuel:',CR,LF,0
PLAYER_JUMP         DC.B 'Jump Power',CR,LF,0
GAMEOVER            DC.B 'GAME OVER',CR,LF,0
GRAPHICS_SETTINGS   DC.B 'GRAPHICS SETTINGS',CR,LF,0
LOW                 DC.B '1. LOW',CR,LF,0
HIGH                DC.B '2. HIGH',CR,LF,0
*-----------------------------------------------------
* audio register indexes
*-----------------------------------------------------
TOUCH_GROUND_CUE     EQU     0
LANDSOUND_WAV        DC.B    'land.wav',0
MOTORBIKE_CUE         EQU    1
MOTORBIKE_WAV        DC.B    'engine1.wav',0
MUSIC_CUE             EQU    2
MUSIC_WAV            DC.B    'music.wav',0
*-----------------------------------------------------
* values
*-----------------------------------------------------
fuel_color_clock    DC.B    100
*-----------------------------------------------------
low_picked          DC.B    0
high_picked         DC.B    0
*-----------------------------------------------------
loading_screen_showed DC.B  0
*-----------------------------------------------------
random_number       DC.W    0
*-----------------------------------------------------
loading_screen_clock DC.W   0
*-----------------------------------------------------
speech_bubble_clock DC.W    0
*-----------------------------------------------------
using_double_buff   DC.B    0
screen_width        DC.W    1920
screen_height       DC.W    1080
ui_width            DC.W    400
*-----------------------------------------------------
walking_level       DC.W    940
floor_level         DC.W    950
upper_floor_level   DC.W    930
detail_offset       DC.B    50
floor_clock         DC.B    0
*-----------------------------------------------------
fuel_clock          DC.B    0
fuel_limit          DC.B    100 ; decreasing fuel if clock reach this value
score_counter       DC.B    0
game_speed          DC.B    1
fuel                DC.W    100
distance_val        DC.L    0
score               DC.L    0
*-----------------------------------------------------
motorframe_force    DC.B    0     ; max 8, 4 < falling
motorframe_y_offset DC.B    0
motorframe_y_max    DC.B    20     ; 11-20
motorframe_y_min    DC.B    0     ; 0-10
*-----------------------------------------------------
human_x             DC.W    540
human_x_max         DC.W    1530
human_x_min         DC.W    540
human_y             DC.W    940
*-----------------------------------------------------
force               DC.W    0
force_clock         DC.B    0
jitter_clock        DC.B    0
grounded            DC.B    1
last_impact_force   DC.B    0
*-----------------------------------------------------
collision           DC.B    0
*-----------------------------------------------------
nitro               DC.B    0
*-----------------------------------------------------
jump_force          DC.W    0
jump_force_max      DC.W    28
jump_force_min      DC.W    12
jump_force_last     DC.W    0
jump_force_timer    DC.B    0
jump_shock          DC.B    0     ; block jump
*-----------------------------------------------------
fuel_box_x          DC.W    0
fuel_box_y          DC.W    0
fuel_picked_up      DC.B    0
*-----------------------------------------------------
obstacle_sp_scale   DC.B    2
obstacle_arr_points DC.B    3   ; basic
obstacle_x          DC.W    0
obstacle_type       DC.W    1
obstacle_width      DC.W    0
obstacle_height     DC.W    0
obstacle_coll_y_offset  DC.W    0
obstacle_arr_ptr    DC.L    $00000000
*-----------------------------------------------------
airplane_x          DC.W    1200
airplane_y          DC.W    750
*----------------------------------------------------
mirror_right_x      DC.W    1950
mirror_right_y      DC.W    550
mirror_left_x       DC.W    390
mirror_left_y       DC.W    550
*-----------------------------------------------------
star_x              DC.W    800
star_y              DC.W    600
*-----------------------------------------------------
top_ui_x            DC.W    1550
top_ui_y            DC.W    590
top_ui_left_center  DC.L    $00DF02D4
top_ui_right_center DC.L    $00DF0499
top_ui_center_width DC.W    100
*-----------------------------------------------------
button_coordynates  DC.L    $016F03BA
button_width        DC.W    60
*-----------------------------------------------------
cycles_last         DC.L    0
cycles_spike        DC.L    0
cycles_delay        DC.L    500 ; good delay
*-----------------------------------------------------
vector_cache        DC.L    0
*-----------------------------------------------------
left_car_reflection_x   DC.W 200
left_car_reflection_y   DC.W 300
car_max_reflection      DC.W 400
car_reflection_scale    DC.W 50
*-----------------------------------------------------
left_airplane_reflection_x DC.W 150
left_airplane_reflection_y DC.W 300
airplane_refelction_diff   DC.W 0

right_airplane_reflection_x DC.W 1870
right_airplane_reflection_y DC.W 300
*-----------------------------------------------------
temp_counter        DC.B    0
models_rescaled     DC.B    0
*-----------------------------------------------------
STARS_ARRAY DC.W 15
    DC.W 100,50, 200,50, 300,50, 500,50, 600,50, 700,50, 800,50, 1000,50
    DC.W 1010,50, 1200,50, 1300,50, 1400,50, 1500,50, 1600,50, 1700,50

*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
* drawings/models
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*-----------------------------------------------------
* Model Settings
*-----------------------------------------------------

FUEL_SETTINGS
    DC.W    1   ; scale on D5
    DC.W    40  ; width
    DC.W    40  ; height
AIRPLANE_SETTINGS
   DC.W     3
   DC.W     40
   DC.W     40
HUMAN_SETTINGS
    DC.W    2   ; scale on D5
    DC.W    40  ; width on D6
    DC.W    40  ; height on D6
UI_SETTINGS    
    DC.W    10
    DC.W    120
    DC.W    60
MIRROR_SETTINGS
    DC.W    11
    DC.W    40
    DC.W    40
SMALLER_MIRROR_SETTING
    DC.W    10
    DC.W    40
    DC.W    40
STAR_SETTINGS
    DC.W    2
    DC.W    10
    DC.W    10
CAR_SETTINGS
    DC.W    3
    DC.W    40
    DC.W    40
CAR2_SETTINGS
    DC.W    2
    DC.W    40
    DC.W    40
STOP_SETTINGS
    DC.W    2
    DC.W    64
    DC.W    64
CAR_REFLECTION_SETTINGS
    DC.W    1
    DC.W    20
    DC.W    20
AIRPLANE_REFLECTION_SETTINGS
    DC.W    6
    DC.W    20
    DC.W    20
*-----------------------------------------------------
* Models
*-----------------------------------------------------

MOTORBIKE_LEFT_TIRE DC.W 17
    DC.W 8,40, 11,40, 13,39, 14,38, 15,36, 15,33, 14,31, 13,30
    DC.W 11,29, 8,29, 6,30, 5,31, 4,33, 4,36, 5,38, 6,39
    DC.W 8,40    
MOTORBIKE_RIGHT_TIRE DC.W 14
    DC.W 27,33, 27,36, 28,38, 29,39, 31,40, 34,40, 36,39, 37,38
    DC.W 38,36, 38,33, 37,31, 36,30, 34,29, 31,29  
MOTORBIKE_LEFT_SUS DC.W 5
    DC.W 9,34, 16,32, 16,33, 10,35, 9,34
MOTORBIKE_RIGHT_SUS DC.W 5
    DC.W 28,31, 32,35, 33,35, 33,34, 28,31    
MOTORBIKE_FRAME DC.W 30
    DC.W 3,20, 11,21, 15,23, 22,23, 26,21, 27,20, 28,18, 27,17
    DC.W 28,16, 30,19, 29,21, 30,24, 37,28, 37,29, 33,28, 31,28
    DC.W 28,31, 27,33, 25,34, 17,34, 16,33, 16,32, 13,29, 10,28
    DC.W 6,29, 4,29, 7,26, 7,25, 4,23, 3,20
MOTORBIKE_HUMAN DC.W 32
    DC.W 19,33, 22,27, 18,21, 19,19, 22,17, 26,21, 27,20, 23,16
    DC.W 23,15, 24,14, 25,15, 26,15, 27,14, 28,12, 27,10, 25,9
    DC.W 23,10, 22,12, 22,13, 21,14, 20,14, 17,16, 15,19, 14,21
    DC.W 14,22, 15,23, 16,23, 17,24, 20,27, 18,31, 18,32, 19,19
HELMET DC.W 5
    DC.W 25,13, 27,14, 28,12, 26,12, 25,13 
MOTORBIKE_BACK DC.W 4
    DC.W 5,28, 2,28, 3,27, 5,28  
*-----------------------------------------------------
* Rotated Motorbike
MOTORBIKE_HUMAN_R DC.W 31
    DC.W 22,28, 20,22, 14,20, 13,17, 15,14, 20,15, 21,14, 15,12
    DC.W 15,11, 16,10, 17,10, 17,9, 17,6, 15,5, 12,6, 12,8
    DC.W 12,10, 13,11, 13,12, 11,13, 10,16, 10,19, 10,22, 11,23
    DC.W 13,23, 14,22, 15,22, 19,23, 20,27, 20,28,  22,28
MOTORBIKE_HELMET_R DC.W 5
    DC.W 15,9, 17,9, 17,7, 15,8, 15,9
MOTORBIKE_FRAME_R DC.W 30
    DC.W 1,27, 8,24, 13,23, 18,19, 20,15, 21,14, 21,12, 19,11
    DC.W 19,10, 23,11, 23,14, 26,15, 33,15, 34,16, 30,16, 29,18
    DC.W 28,22, 28,24, 27,27, 21,31, 19,30, 18,29, 14,29, 11,30
    DC.W 9,33, 7,34, 8,30, 7,29, 4,29, 1,27
MOTORBIKE_RIGHTSUS_R DC.W 5
    DC.W 28,21, 33,20, 35,19, 33,19, 28,20
MOTORBIKE_LEFTSUS_R DC.W 5
    DC.W 13,34, 18,30, 19,31, 15,34, 13,34
MOTRBIKE_PIPE DC.W 4
    DC.W 8,32, 4,33, 5,32,  8,32  
MOROBIKE_RIGHT_TIRE_R DC.W 15
    DC.W 28,20, 28,23, 29,25, 30,26, 32,27, 35,27, 37,26, 38,25
    DC.W 39,21, 39,20, 38,18, 37,17, 35,16, 32,16, 28,20
MOTORBIKE_LEFT_TIRE_R DC.W 17
    DC.W 13,40, 16,40, 18,39, 19,38, 20,36, 20,34, 19,31, 18,30
    DC.W 16,29, 13,29, 11,30, 10,31, 9,33, 9,37, 10,38, 11,39
    DC.W 13,40
*-----------------------------------------------------
AIRPLANE_FRAME DC.W 13
    DC.W 2,22, 3,21, 8,19, 28,19, 31,17, 35,11, 37,11, 37,13
    DC.W 34,22, 31,24, 3,24, 2,23, 2,22
    
AIRPLANE_LEFT_WING DC.W 6
    DC.W 16,22, 19,25, 20,26, 19,27, 17,26, 13,22
    
AIRPLANE_RIGHT_DOOR DC.W 5
    DC.W 24,21, 24,23, 25,23, 25,21, 24,21
 
AIRPLANE_LEFT_DOOR DC.W 5
    DC.W 9,21, 9,23, 10,23, 10,21, 9,21 

AIRPLANE_FRONT_WINDOW DC.W 5
    DC.W 2,22, 3,21, 6,21, 5,22, 2,22
*-----------------------------------------------------
UI_MID DC.W 20
    DC.W 30,40, 37,39, 43,36, 47,32, 49,28, 49,22, 48,16, 47,13
    DC.W 50,15, 57,17, 63,17, 70,15, 73,13, 72,16, 71,22, 71,28
    DC.W 73,32, 78,36, 84,39, 90,40

UI_DOWN DC.W 14
    DC.W 30,40, 28,42, 27,45, 27,47, 28,48, 53,48, 57,47, 62,47
    DC.W 66,48, 92,48, 93,47, 93,44, 92,42, 90,40
*-----------------------------------------------------
BOX DC.W 19
    DC.W 5,13, 5,35, 7,37, 28,37, 30,35, 30,5, 28,4, 14,4
    DC.W 11,7, 9,4, 10,3, 10,1, 7,4, 7,5, 6,6, 6,7
    DC.W 7,6, 9,9, 5,13
F_L    DC.W 11
    DC.W 23,17, 14,17, 14,32, 17,32, 17,26, 20,26, 20,23, 17,23
    DC.W 17,20, 23,20, 23,17
F_HOLDER DC.W 5
    DC.W 16,5, 26,5, 26,8, 13,8, 16,5
*----------------------------------------------------
RIGHT_MIRROR DC.W 10
    DC.W 5,32, 5,18, 17,4, 20,3, 36,2, 37,4, 35,18, 33,20, 14,32, 5,32
LEFT_MIRROR DC.W  10
    DC.W  37,32, 37,18, 26,4, 23,3, 6,2, 5,4, 7,18, 9,20, 28,32, 37,32

S_RIGHT_MIRROR DC.W 10
    DC.W 5,32, 5,18, 17,4, 20,3, 36,2, 37,4, 35,18, 33,20, 14,32, 5,32
S_LEFT_MIRROR DC.W  10
    DC.W  37,32, 37,18, 26,4, 23,3, 6,2, 5,4, 7,18, 9,20, 28,32, 37,32   
*---------------------------------------------------
LEFT_CAR_FRAME_REFLECTION DC.W 6
    DC.W 20,2, 12,2, 6,10, 6,18, 7,19, 20,19
LEFT_CAR_WINDOW_REFLECTION DC.W 4
    DC.W 20,3, 12,3, 8,9, 20,9
LEFT_CAR_LIGHT_REFLECTION DC.W 5
    DC.W 7,14, 7,12, 12,13, 11,14, 7,14 
*----------------------------------------------------
LEFT_AIRPLANE_FRAME_REFLECTION DC.W 6
    DC.W 20,4, 17,4, 14,7, 14,13, 17,16, 20,16 
LEFT_AIRPLANE_WINDOW_REFLECTION DC.W 4
    DC.W 20,10, 15,10, 16,8, 20,8 
LEFT_AIRPLANE_WING_REFLECTION DC.W 3
    DC.W 14,13, 1,8, 16,15
*----------------------------------------------------    
RIGHT_AIRPLANE_FRAME_REFLECTION DC.W 5
    DC.W 3,4, 6,7, 6,13, 3,16, 3,16
RIGHT_AIRPLANE_WINDOW_REFLECTION DC.W 4
    DC.W 1,10, 5,10, 4,8, 1,8
RIGHT_AIRPLANE_WING_REFLECTION DC.W 3
    DC.W 6,13, 20,8, 4,15 
*----------------------------------------------------
STAR DC.W 11
    DC.W 4,4, 5,1, 6,4, 9,4, 7,6, 8,9, 5,7, 2,9
    DC.W 3,6, 1,4, 4,4
*---------------------------------------------------
CAR DC.W 24
    DC.W 16,27, 10,31, 2,34, 1,37, 1,39, 7,39, 7,36, 8,35
    DC.W 11,35, 12,36, 12,39, 28,39, 28,36, 29,35, 32,35, 33,36
    DC.W 33,39, 40,39, 40,36, 39,36, 39,31, 30,31, 25,27, 16,27
CARLT DC.W 3
    DC.W 7,39, 8,40, 11,40
CARRT DC.W 3
    DC.W 28,39, 29,40, 32,40
*----------------------------------------------------
CAR2 DC.W 14
    DC.W 4,33, 39,33, 40,31, 40,27, 38,26, 33,25, 30,21, 28,20
    DC.W 14,20, 11,21, 9,24, 1,28, 1,32, 4,33
CAR2LT DC.W 9
    DC.W 6,33, 6,35, 7,37, 8,38, 10,39, 13,39, 15,38, 16,37
    DC.W 17,35
CAR2RT DC.W 9
    DC.W 25,33, 25,35, 26,37, 27,38, 29,39, 32,39, 34,38, 35,37
    DC.W 36,35 
*----------------------------------------------------
SIGN DC.W 33
    DC.W 31,64, 31,24, 29,24, 26,23, 24,22, 23,21, 22,19, 21,16
    DC.W 21,12, 21,8, 22,5, 23,3, 24,2, 26,1, 29,0, 37,0
    DC.W 40,1, 42,2, 43,3, 44,5, 45,8, 45,12, 45,16, 44,19
    DC.W 43,21, 42,22, 40,23, 37,24, 35,24, 31,24, 35,24, 35,64
    DC.W 31,64

STOP_T DC.W 4
    DC.W 29,9, 33,9, 31,9, 31,15

STOP_S DC.W 6
    DC.W 28,9, 24,9, 24,12, 28,12, 28,15, 24,15
STOP_P DC.W 6
    DC.W 39,9, 42,9, 42,12, 39,12, 39,15, 39,9
STOP_O DC.W 9
    DC.W 35,9, 34,10, 34,14, 35,15, 37,15, 38,14, 38,10, 37,9
    DC.W 35,9 
*-----------------------------------------------------
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
PROGRAM_EXIT:
    END    START
*xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
