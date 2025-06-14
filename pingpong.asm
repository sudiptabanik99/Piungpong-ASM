STACK SEGMENT PARA STACK
	DB 64 DUP(' ')
STACK ENDS

DATA SEGMENT PARA 'DATA'
	
	;WINDOW BOUNDARY
	WINDOW_X DW 140H ;X BOUNDARY'320p'
	WINDOW_Y DW 0C8H ;Y BOUNDARY'240p'
	BOUNCE_BOUNDARY_X DW 1H
	BOUNCE_BOUNDARY_Y DW 1H
	
	;TIME CREATE
	TIME_VAR DB 0
	
	;GAME STATUS(ACTIVE OR NOT)
	GAME_STATUS DB 01H ;(1= GAME ACTIVE)(0= GAME OVER)
	
	;WINNER STATUS
	WINNER_STATUS DB 00H
	
	;BALL SHAPE,SIZE,POSITION
	BALL_X DW 00H ;SET BALL POSITION X
	BALL_Y DW 00H ;SET BALL POSITION Y
	BALL_SIZE DW 06H;
	
	;BALL SPEED
	BALL_VX DW 07H ;X VELOCITY
	BALL_VY DW 02H ;Y VELOCITY
	
	;BALL POSITION RESET
	RESET_X DW 0A0H
	RESET_Y DW 64H
	
	;PADDLE POSITION
	PAD_LX DW 05H
	PAD_LY DW 060H
	PAD_RX DW 0135H
	PAD_RY DW 060H
	
	;PADDLE SIZE
	PAD_H DW 019H
	PAD_W DW 06H
	
	;PADDLE SPEED
	PAD_SPEED DW 13H
	
	;SCORE
	PADL_POINT DB 0
	PADR_POINT DB 0
	
	PADL_ROUND_POINT DB 0
	PADR_ROUND_POINT DB 0
	
	;DISPLAY STRING
	TEXT_PADL_POINT_U DB '0', '$' ;PLAYER1_POINT
	TEXT_PADL_POINT_D DB '0', '$' ;PLAYER1_POINT
	
	TEXT_PADR_POINT_U DB '0', '$' ;PLAYER2_POINT	
	TEXT_PADR_POINT_D DB '0', '$' ;PLAYER2_POINT
	
	TEXT_PADL_ROUND_POINT DB '0', '$'
	TEXT_PADR_ROUND_POINT DB '0', '$'
	
	TEXT_ROUND_WON DB 'ROUND WON', '$'
	TEXT_DASH DB '-', '$'
	TEXT_GAME_OVER DB 'GAME OVER', '$'
	TEXT_PLAYER_WIN DB 'PLAYER 0 WON THE MATCH', '$'
	TEXT_GAME_RESTART DB 'Press SPACE to restart', '$'
	TEXT_GAME_EXIT DB 'Press (E) to exit game', '$'
	
DATA ENDS

CODE SEGMENT PARA 'DATA'

	MAIN PROC FAR
	ASSUME CS:CODE, DS:DATA, SS:STACK
	PUSH DS	     ;PUSH DS TO STACK
	SUB AX, AX   ;CLEAN AX
	PUSH AX      ;PUSH AX TO STACK
	MOV AX, DATA 
	MOV DS, AX   ;SAVE AX DATA TO DS
	POP AX       ;RELEASE
		
		;CALL CLEAR_SCREEN
		
		TIME_CHK:
			CMP GAME_STATUS, 00H
			JE GAME_OVER_DISPLAY
			MOV AH ,2CH ;GET SYSTEM TIME
			INT 21H 	;CH = hour CL = minute DH = second DL = 1/100 seconds
			
			CMP DL, TIME_VAR ;TIME CHANGE DETECT
			JE TIME_CHK		 ;CHECKS AGAIN IF NO TIME CHANGE
			MOV TIME_VAR,DL  ;UPDATE TIME
						
			CALL CLEAR_SCREEN
			
			CALL BALL_SHAPE
			CALL MOVE_BALL
			
			CALL PADDLE_DRAW
			CALL MOVE_PADDLE
			
			CALL UI_DESIGN
					
			JMP TIME_CHK		 ;AGAIN TIME CHECK	

			GAME_OVER_DISPLAY:
				CALL GAME_OVER_UI
				JMP TIME_CHK
		RET
		
	MAIN ENDP
	
	MOVE_BALL PROC NEAR
		 MOV AX, BALL_VX
		 ADD BALL_X,AX	 ;X MOVEMENT		
		
		 MOV AX, BOUNCE_BOUNDARY_X
		 CMP BALL_X,AX 		          
		 JLE PADR_ROUND_WIN       ;RESET TO CENTER IF COLLIDE LEFT BOUNDARY 
		
		 MOV AX, WINDOW_X		 ;RESET TO CENTER IF COLLIDE RIGHT BOUNDARY 
		 SUB AX, BALL_SIZE
		 SUB AX, BOUNCE_BOUNDARY_X
		 CMP BALL_X,AX
		 JGE PADL_ROUND_WIN		 ;REVERSE IF BALL_X > WINDOW_X - BALL_SIZE-BOUNCE_BOUNDARY_X
		 JMP MOVE_BALL_Y
		 
		 PADL_ROUND_WIN:
			INC PADL_ROUND_POINT
			CALL PAD_POINT_RESET
			CALL UPDATE_PADL_ROUND
			CMP PADL_ROUND_POINT, 05H
			JGE GAME_OVER
			CALL BALL_RESET
			RET
			
		 PADR_ROUND_WIN:
			
			INC PADR_ROUND_POINT
			CALL PAD_POINT_RESET
			CALL UPDATE_PADR_ROUND
			CMP PADR_ROUND_POINT, 05H
			JGE GAME_OVER
			CALL BALL_RESET
			RET	
			
			GAME_OVER:
				CMP PADL_ROUND_POINT, 05H
				JNL PADL_WIN
				JMP PADR_WIN
				PADL_WIN:	
					MOV WINNER_STATUS, 01H
					JMP GAME_OVER_CONTD
				PADR_WIN:
					MOV WINNER_STATUS, 02H
					NEG BALL_VX
					JMP GAME_OVER_CONTD
				GAME_OVER_CONTD:
					MOV PADL_ROUND_POINT, 00H
					MOV PADR_ROUND_POINT, 00H
					MOV PADL_POINT, 00H
					MOV PADR_POINT, 00H
					
					MOV BALL_X, 00H
					MOV BALL_Y, 00H
					
					CALL UPDATE_PADL_POINT
					CALL UPDATE_PADR_POINT
					CALL UPDATE_PADL_ROUND
					CALL UPDATE_PADR_ROUND
					
					MOV GAME_STATUS, 00H
			RET	
		 
		 MOVE_BALL_Y:
			 MOV AX, BALL_VY
			 ADD BALL_Y,AX	 ;Y MOVEMENT
		
		 MOV AX, BOUNCE_BOUNDARY_Y
		 CMP BALL_Y,AX 
		 JLE REV_Y         ;REVERSE MOVE IF BALL_X < 0
		
		 MOV AX, WINDOW_Y
		 SUB AX, BALL_SIZE
		 SUB AX, BOUNCE_BOUNDARY_Y
		 CMP BALL_Y,AX
		 JGE REV_Y		 ;REVERSE IF BALL_Y > WINDOW_Y - BALL_SIZE-BOUNCE_BOUNDARY_Y
		
		 XOR AX, AX
		 ;COLLISION DETECT ALGORITHM
		 ;maxx1 > minx2 && minx1 < maxx2 && maxy1 > miny1 && miny1 < maxy2
		 ;FOR PADR
		 ;(BALL_X+BALL_SIZE>PAD_RX) & (BALL_X<PAD_RX+PAD_W) & 
		 ;(BALL_Y+BALL_SIZE>PAD_RY) & (BALL_Y<PAD_RY+PAD_H)
		 ;PADR COLLISION DETECT
		 
		 MOV AX, BALL_X
		 ADD AX, BALL_SIZE
		 CMP AX, PAD_RX
		 JNG PADL_COL_DETECT
		 
		 MOV AX, PAD_RX
		 ADD AX, PAD_W
		 CMP BALL_X, AX
		 JNL PADL_COL_DETECT
		 
		 MOV AX, BALL_Y
		 ADD AX, BALL_SIZE
		 CMP AX, PAD_RY
		 JNG PADL_COL_DETECT
		 
		 MOV AX, PAD_RY
		 ADD AX, PAD_H
		 CMP BALL_Y, AX
		 JNL PADL_COL_DETECT		 
		 JMP REV_XR
		 
		 REV_Y:
			 NEG BALL_VY
			 RET
		 ;FOR PADL
		 ;(BALL_X+BALL_SIZE>PAD_LX) & (BALL_X<PAD_LX+PAD_W) & 
		 ;(BALL_Y+BALL_SIZE>PAD_LY) & (BALL_Y<PAD_LY+PAD_H)
		 ;PADL COLLISION DETECT
		 PADL_COL_DETECT:
		 MOV AX, BALL_X
		 ADD AX, BALL_SIZE
		 CMP AX, PAD_LX
		 JNG EXIT_COL_DETECT
		 
		 MOV AX, PAD_LX
		 ADD AX, PAD_W
		 CMP BALL_X, AX
		 JNL EXIT_COL_DETECT
		 
		 MOV AX, BALL_Y
		 ADD AX, BALL_SIZE
		 CMP AX, PAD_LY
		 JNG EXIT_COL_DETECT
		 
		 MOV AX, PAD_LY
		 ADD AX, PAD_H
		 CMP BALL_Y, AX
		 JNL EXIT_COL_DETECT 
		 JMP REV_XL
		 
		 
		 REV_XL: 
			 NEG BALL_VX ;BOUNCE BACK
			 INC PADL_POINT
			 CALL UPDATE_PADL_POINT
			 RET
		 REV_XR:
			 NEG BALL_VX ;BOUNCE BACK
			 INC PADR_POINT
			 CALL UPDATE_PADR_POINT
			 RET
		 
		 EXIT_COL_DETECT:
			RET
			
	MOVE_BALL ENDP
	
	BALL_RESET PROC NEAR
		MOV AX, RESET_X
		MOV BALL_X, AX
		
		MOV AX, RESET_Y
		MOV BALL_Y, AX	
			
		RET
	BALL_RESET ENDP
	
	CLEAR_SCREEN PROC NEAR
			MOV AH, 00H ;CONFIG SET VIDEO
			MOV AL, 13H ;VIDEO MODE SELECT
			INT 10H		;VIDEO INTERRUPT
			
			MOV AH, 0DH
			MOV BH, 00H ;BG COLOR
			MOV BL, 00H ;BLACK BG
			INT 10H
		RET
	CLEAR_SCREEN ENDP
	
	BALL_SHAPE PROC NEAR
		
		MOV CX, BALL_X
		MOV DX, BALL_Y	

		XY_SHAPE:
			MOV AH, 0CH ;CONFIG SET PIXEL WRITE
			MOV AL, 0FH ;WHITE PIXEL
			MOV BH, 00H
			INT 10H	
			
			INC CX			;INC = INCREAMENT
			MOV AX, BALL_X
			ADD AX,BALL_SIZE
			CMP AX,CX 		;COMPARES BALL_X WITH BALL_SIZE
			JG XY_SHAPE 	;JUMPS TO 'X_SHAPE' TILL BALL_X=BALL_X+BALL_SIZE
			
			MOV CX, BALL_X
			
			INC DX			;PROCEEDS TO INCREASE BALL_Y AFTER BALL_X INCREMENT FINISHES
			MOV AX, BALL_Y
			ADD AX,BALL_SIZE
			CMP AX,DX ;
			JG XY_SHAPE
		
		RET
	BALL_SHAPE ENDP
	
	PADDLE_DRAW PROC NEAR
		MOV CX, PAD_LX
		MOV DX, PAD_LY
		
		PADDLE_SHAPE_L:
			MOV AH, 0CH ;CONFIG SET PIXEL WRITE
			MOV AL, 0FH ;WHITE PIXEL
			MOV BH, 00H
			INT 10H	
			
			INC CX			
			MOV AX, PAD_LX
			ADD AX,PAD_W
			CMP AX,CX 		
			JG PADDLE_SHAPE_L 	
			
			MOV CX, PAD_LX
			
			INC DX			
			MOV AX, PAD_LY
			ADD AX, PAD_H
			CMP AX,DX ;
			JG PADDLE_SHAPE_L
			
		MOV CX, PAD_RX
		MOV DX, PAD_RY
		
		PADDLE_SHAPE_R:
			MOV AH, 0CH ;CONFIG SET PIXEL WRITE
			MOV AL, 0FH ;WHITE PIXEL
			MOV BH, 00H
			INT 10H	
			
			INC CX			
			MOV AX, PAD_RX
			ADD AX,PAD_W
			CMP AX,CX 		
			JG PADDLE_SHAPE_R 	
			
			MOV CX, PAD_RX
			
			INC DX			
			MOV AX, PAD_RY
			ADD AX, PAD_H
			CMP AX,DX ;
			JG PADDLE_SHAPE_R
		RET
	PADDLE_DRAW ENDP
	
	MOVE_PADDLE PROC NEAR
		 ;FOR PAD_LEFT
		 MOV AH, 01H
		 INT 16H
		 JZ PAD_RDETECT
	
		 MOV AH, 00H
		 INT 16H
		 
		 CMP AL, 77H ;'w'
		 JE MOVE_PADL_UP
		 CMP AL, 57H ;'W'
		 JE MOVE_PADL_UP
		 
		 CMP AL, 73H ;'s'
		 JE MOVE_PADL_DOWN
		 CMP AL, 53H ;'S'
		 JE MOVE_PADL_DOWN
		 JMP PAD_RDETECT
		 
		 
		 
		 MOVE_PADL_UP:
			MOV AX,PAD_SPEED
			SUB PAD_LY,AX
			MOV AX, BOUNCE_BOUNDARY_X
			CMP PAD_LY, AX
			JL FIX_PADL_TOP
			JMP PAD_RDETECT
			
			FIX_PADL_TOP:
				MOV AX, BOUNCE_BOUNDARY_X
				MOV PAD_LY, AX
				JMP PAD_RDETECT			
			
		 MOVE_PADL_DOWN:
			MOV AX,PAD_SPEED
			ADD PAD_LY,AX
			MOV AX, WINDOW_Y
			SUB AX, BOUNCE_BOUNDARY_X 
			SUB AX, PAD_H
			CMP AX, PAD_LY
			JL FIX_PADL_BOTTOM
			JMP PAD_RDETECT
			
			FIX_PADL_BOTTOM:
				MOV PAD_LY,AX								
				JMP PAD_RDETECT
						
	 ;FOR PAD RIGHT
	 PAD_RDETECT:
		 CMP AL, 06BH ;'k'
		 JE MOVE_PADR_DOWN
		 CMP AL, 04BH ;'K'
		 JE MOVE_PADR_DOWN
		 
		 CMP AL, 069H ;'i'
		 JE MOVE_PADR_UP
		 CMP AL, 049H ;'I'
		 JE MOVE_PADR_UP
		 JMP EXIT_PADR
		 
		 MOVE_PADR_UP:
			MOV AX,PAD_SPEED
			SUB PAD_RY,AX
			MOV AX, BOUNCE_BOUNDARY_X
			CMP PAD_RY, AX
			JL FIX_PADR_TOP
			JMP EXIT_PADR
			
			FIX_PADR_TOP:
				MOV AX, BOUNCE_BOUNDARY_X
				MOV PAD_RY, AX
				JMP EXIT_PADR			
			
		 MOVE_PADR_DOWN:
			MOV AX,PAD_SPEED
			ADD PAD_RY,AX
			MOV AX, WINDOW_Y
			SUB AX, BOUNCE_BOUNDARY_X 
			SUB AX, PAD_H
			CMP AX, PAD_RY
			JL FIX_PADR_BOTTOM
			JMP EXIT_PADR
			
			FIX_PADR_BOTTOM:
				MOV PAD_RY,AX								
				JMP EXIT_PADR
			 
	 EXIT_PADR:									 	
		RET
	MOVE_PADDLE ENDP
	
	UPDATE_PADL_POINT PROC NEAR
		XOR AX,AX
		MOV AL, PADL_POINT
		MOV BL, 0AH
		DIV BL
		ADD AL, 30H ;COVERTS VALUE TO ASCII
		ADD AH, 30H ;COVERTS VALUE TO ASCII
		MOV [TEXT_PADL_POINT_D], AL
		MOV [TEXT_PADL_POINT_U], AH
		RET
	UPDATE_PADL_POINT ENDP
	
	UPDATE_PADR_POINT PROC NEAR
		XOR AX,AX
		MOV AL, PADR_POINT
		MOV BL, 0AH
		DIV BL
		ADD AL, 30H ;COVERTS VALUE TO ASCII
		ADD AH, 30H ;COVERTS VALUE TO ASCII
		MOV [TEXT_PADR_POINT_D], AL
		MOV [TEXT_PADR_POINT_U], AH
		RET
	UPDATE_PADR_POINT ENDP
	
	UPDATE_PADL_ROUND PROC NEAR
		XOR AX,AX
		MOV AL, PADL_ROUND_POINT
		ADD AL, 30H ;COVERTS VALUE TO ASCII
		MOV [TEXT_PADL_ROUND_POINT], AL
		RET
	UPDATE_PADL_ROUND ENDP
	
	UPDATE_PADR_ROUND PROC NEAR
		XOR AX,AX
		MOV AL, PADR_ROUND_POINT
		ADD AL, 30H ;COVERTS VALUE TO ASCII
		MOV [TEXT_PADR_ROUND_POINT], AL
		RET
	UPDATE_PADR_ROUND ENDP
	
	
	UI_DESIGN PROC NEAR
	
		;PADL_POINT
		MOV AH, 02H  ;SET CURSOR POSITION
		MOV BH, 00H  ;SET PAGE NUMBER
		MOV DH, 04H  ;SET ROW
		MOV DL ,06H  ;SET COLUMN
		INT 10H
		
		MOV AH, 09H  ;WRITE STRING TO STANDARD OUTPUT
		LEA DX, TEXT_PADL_POINT_D  ;GIVES DX A STRING
		INT 21H   
		
		MOV AH, 02H  ;SET CURSOR POSITION
		MOV BH, 00H  ;SET PAGE NUMBER
		MOV DH, 04H  ;SET ROW
		MOV DL ,07H  ;SET COLUMN
		INT 10H
		
		MOV AH, 09H  ;WRITE STRING TO STANDARD OUTPUT
		LEA DX, TEXT_PADL_POINT_U  ;GIVES DX A STRING
		INT 21H

		;PADR_POINT
		MOV AH, 02H  ;SET CURSOR POSITION
		MOV BH, 00H  ;SET PAGE NUMBER
		MOV DH, 04H  ;SET ROW
		MOV DL, 021H  ;SET COLUMN
		INT 10H
		
		MOV AH, 09H  ;WRITE STRING TO STANDARD OUTPUT
		LEA DX, TEXT_PADR_POINT_D  ;GIVES DX A STRING
		INT 21H 
		
		;FOR RIGHT PADDLE
		MOV AH, 02H  ;SET CURSOR POSITION
		MOV BH, 00H  ;SET PAGE NUMBER
		MOV DH, 04H  ;SET ROW
		MOV DL, 022H  ;SET COLUMN
		INT 10H
		
		MOV AH, 09H  ;WRITE STRING TO STANDARD OUTPUT
		LEA DX, TEXT_PADR_POINT_U  ;GIVES DX A STRING
		INT 21H 
		
		;ROUND POINT
		;PADL ROUND POINT TEXT
		MOV AH, 02H  ;SET CURSOR POSITION
		MOV BH, 00H  ;SET PAGE NUMBER
		MOV DH, 04H  ;SET ROW
		MOV DL, 013H  ;SET COLUMN
		INT 10H
		
		MOV AH, 09H  ;WRITE STRING TO STANDARD OUTPUT
		LEA DX, TEXT_PADL_ROUND_POINT  ;GIVES DX A STRING
		INT 21H 
		
		;PADR ROUND POINT TEXT
		MOV AH, 02H  ;SET CURSOR POSITION
		MOV BH, 00H  ;SET PAGE NUMBER
		MOV DH, 04H  ;SET ROW
		MOV DL, 015H  ;SET COLUMN
		INT 10H
		
		MOV AH, 09H  ;WRITE STRING TO STANDARD OUTPUT
		LEA DX, TEXT_PADR_ROUND_POINT  ;GIVES DX A STRING
		INT 21H 
		
		;GENERAL TEXT
		MOV AH, 02H  ;SET CURSOR POSITION
		MOV BH, 00H  ;SET PAGE NUMBER
		MOV DH, 02H  ;SET ROW
		MOV DL, 010H  ;SET COLUMN
		INT 10H
		
		MOV AH, 09H  ;WRITE STRING TO STANDARD OUTPUT
		LEA DX, TEXT_ROUND_WON ;GIVES DX A STRING
		INT 21H
		
		MOV AH, 02H  ;SET CURSOR POSITION
		MOV BH, 00H  ;SET PAGE NUMBER
		MOV DH, 04H  ;SET ROW
		MOV DL, 014H  ;SET COLUMN
		INT 10H
		
		MOV AH, 09H  ;WRITE STRING TO STANDARD OUTPUT
		LEA DX, TEXT_DASH ;GIVES DX A STRING
		INT 21H 
		
		RET
	
	UI_DESIGN ENDP
	
	PAD_POINT_RESET PROC NEAR
		MOV PADL_POINT, 00H
		MOV PADR_POINT, 00H
		CALL UPDATE_PADL_POINT
		CALL UPDATE_PADR_POINT
		RET
	PAD_POINT_RESET ENDP
	
	GAME_OVER_UI PROC NEAR
		CALL CLEAR_SCREEN
		MOV AH, 02H  ;SET CURSOR POSITION
		MOV BH, 00H  ;SET PAGE NUMBER
		MOV DH, 04H  ;SET ROW
		MOV DL, 010H  ;SET COLUMN
		INT 10H
		
		MOV AH, 09H  ;WRITE STRING TO STANDARD OUTPUT
		LEA DX, TEXT_GAME_OVER ;GIVES DX A STRING
		INT 21H
	
		MOV AH, 02H  ;SET CURSOR POSITION
		MOV BH, 00H  ;SET PAGE NUMBER
		MOV DH, 05H  ;SET ROW
		MOV DL, 0AH  ;SET COLUMN
		INT 10H
		CALL UPDATE_WINNER_STATUS
		MOV AH, 09H  ;WRITE STRING TO STANDARD OUTPUT
		LEA DX, TEXT_PLAYER_WIN ;GIVES DX A STRING
		INT 21H
		
		MOV AH, 02H  ;SET CURSOR POSITION
		MOV BH, 00H  ;SET PAGE NUMBER
		MOV DH, 07H  ;SET ROW
		MOV DL, 0AH  ;SET COLUMN
		INT 10H
		
		MOV AH, 09H  ;WRITE STRING TO STANDARD OUTPUT
		LEA DX, TEXT_GAME_RESTART ;GIVES DX A STRING
		INT 21H
		
		MOV AH, 02H  ;SET CURSOR POSITION
		MOV BH, 00H  ;SET PAGE NUMBER
		MOV DH, 08H  ;SET ROW
		MOV DL, 0AH  ;SET COLUMN
		INT 10H
		
		MOV AH, 09H  ;WRITE STRING TO STANDARD OUTPUT
		LEA DX, TEXT_GAME_EXIT ;GIVES DX A STRING
		INT 21H
		
		;WAIT FOR KEYBOARD INPUT
		MOV AH, 00H
		INT 16H
		
		CMP AL, 020H ;'SPACE'
		JE GAME_RESTART
		
		CMP AL, 'E'
		JE GAME_EXIT
		CMP AL, 'e'
		JE GAME_EXIT
		
		RET
		
		GAME_RESTART:
			
			MOV PAD_LX, 05H
			MOV PAD_LY, 060H
			MOV PAD_RX, 0135H
			MOV PAD_RY, 060H
			
			MOV GAME_STATUS, 01H
			RET
		
		GAME_EXIT:
			MOV AH, 4CH
			INT 21H	
			
	GAME_OVER_UI ENDP
	
	UPDATE_WINNER_STATUS PROC NEAR
		MOV AL, WINNER_STATUS
		ADD AL, 30H
		MOV [TEXT_PLAYER_WIN+7], AL
		RET
	UPDATE_WINNER_STATUS ENDP
	
	

CODE ENDS
END 