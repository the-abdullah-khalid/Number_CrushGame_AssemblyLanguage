
.model small
.stack 100h

.data

	x word ?				; To set x-coordinate for any object
	y word ?				; To set y-coordinate for any object
	color byte ?				; To set color of objects
	randomNumber byte ?			; Generated random number
	randomRange word ?			; Range of random number
	time_delay word ?			; To set delay time
	string byte 2 dup('$')			; String in which number will be saved for displaying in pixels
	count byte 0
	recHeight word ?
	recWidth word ?
	slope word ?				; Slope of diagonal line
	temp_cx word ?		; Used in rectangle in place of push-pop
	
	; ***************
	; Grid array data
	; ***************
	
	rows word 10				; Rows of grid (2D-Array)
	columns word 10				; Columns of grid (2D-Array)
	gridArray byte 10 dup(10 dup(0))	; 2D-Array for keeping track on backend
	
	; ******************
	; Swap function data
	; ******************
	
	toSwapRow word ?			; Row number of element to be swapped
	toSwapColumn word ?			; Column number of element to be swapped
	withSwapRow word ?			; Row number of element to swap with
	withSwapColumn word ?			; Column number of element to swap with
	toIndex word ?				; Index of element to be swapped
	withIndex word ?			; Index of element to swap with
	swapped byte ?				; Flag set if numbers are swapped and not otherwise
	bombed byte ?				; Set if destruction happens
	
	; *************
	; Box draw data
	; *************
	
	comx word ?				; End x-coordinate of box
	comy word ?				; End y-coordinate of box
	boxHeight word ?			; Height of box
	boxWidth word ?				; Width of box
	startx word 10 dup(10 dup(0))		; 2D-Arrays consisting of starting and ending coordinates of boxes of grid
	starty word 10 dup(10 dup(0))
	endx word 10 dup(10 dup(0))
	endy word 10 dup(10 dup(0))
	
	; *****************
	; Profile menu data
	; *****************
	
	profile_input byte "ENTER PROFILE:  $"
	profile byte 100 dup('$')			; To store user profile
	profile_limit byte "MAXIMUM 12 CHARACTERS$"
	count_profile byte 0
	
	; ********************
	; Score and Moves Data
	; ********************
	
	score_line byte "SCORE:$"
	score word ?
	moves_line byte "MOVES:$"
	moves word ?
	name_line byte "NAME:$"
	numberString byte 100 dup('$')
	
	; ********************
	; Levels display lines
	; ********************
	
	level1_line byte "LEVEL-1 $"
	level2_line byte "LEVEL-2 $"
	level3_line byte "LEVEL-3 $"
	hScore_line byte "Highest Score: $"
	score1 word ?			; Score of level 1
	score2 word ?			; Score of level 2
	score3 word ?			; Score of level 3
	hScore word ?			; Highest score
	
	; **********
	; Mouse Data
	; **********
	
	click byte ?
	flag byte ?
	mstartx word ?
	mstarty word ?
	mendx word ?
	mendy word ?
	
	; ****************
	; Update grid data
	; ****************
	
	targetNumber byte ?			; Number which is being compared for combo formation
	secTarget byte ?			; Number with which target is swapped (It is also checked for combo formation)
	updated byte ?				; Flag set if after swapping combos are formed and array is updated (Of target)
	updatedSec byte ?			; Flag set if after swapping combos are formed and array is updated (Of secondary target)
	rightCount byte ?			; If right side has same numbers as target, we will keep their count
	leftCount byte ?			; If left side has same numbers as target, we will keep their count
	upCount byte ?				; If up side has same numbers as target, we will keep their count
	downCount byte ?			; If down side has same numbers as target, we will keep their count
	level2rows word ?
	level2columns word ?
	level_delay word ?
	
	; ******************
	; File handling data
	; ******************
	
	file_name byte "Output.txt", '0'
	file_handle word ?
	string_final byte 2 dup('$')
	str_endl byte 10, 13, '$'
	
.code

; ===================================================================================================================================================================

	; **************
	; Main procedure
	; **************

	main proc

		mov ax, @data
		mov ds, ax
		
		call playerProfile
		
		call level1
		mov ax, score
		mov score1, ax
		
		call level2
		mov ax, score
		mov score2, ax
		
		call level3
		mov ax, score
		mov score3, ax
		
		call gameOutputFile
		
		mov ah, 4ch
		int 21h

	main endp
	
; ===================================================================================================================================================================

	; ***************
	; Level 1 of game
	; ***************
	
	level1 proc
	
		mov moves, 0
		mov score, 0
		mov randomRange, 6
		mov level_delay, 50
		call populateGridArray		; Populating grid array
		call clearScreen		; Selecting screen mode
		call drawBoard			; Drawing board of level1
		call drawLevelInfo		; Displaying level info
		
		; *****************************************************
		; Mouse simulation and level-1 gameplay started started
		; *****************************************************
		
		mov flag, 0
		
		simulation:
		
			mov ax,01	; Displays the mouse cursor
			int 33h
		
			mov ax, 03
			int 33h
			
			mov x, cx	; Saving coordinates of mouse
			mov y, dx
			mov click, bl	; Saving mouse click
			
			cmp click, 0	; Checking if mouse is clicked or not
			je check_key	; If mouse is not clicked
			
			; ******************************************************************
			; Saving start coordinated where mouse is clicked for the first time
			; ******************************************************************
			
			cmp flag, 0
			je save_starts
			jmp next
			
			save_starts:
			
				mov ax, x
				mov mstartx, ax
				mov ax, y
				mov mstarty, ax
				mov flag, 1
			
			; *************************************
			; While mouse is clicked this loop runs
			; *************************************
			
			mouseClicked:
			
				mov ax,01	; Displays the mouse cursor
				int 33h
			
				mov ax, 03
				int 33h
				
				mov x, cx	; Saving coordinates of mouse
				mov y, dx
			
				cmp bl, 0
				je end_mouseClicked
			
			jmp mouseClicked
			end_mouseClicked:
			
			; ***************************************************
			; Saving end coordinates of where mouse click is left
			; ***************************************************
				
			next:
			
				mov ax, x
				mov mendx, ax
				mov ax, y
				mov mendy, ax
				
				mov flag, 0
				
			; #############################################################################################################################################
				
			call boxToSwap
			call boxToSwapWith
			call swap
			
			cmp swapped, 1		; If number is swapped draw board again
			je draw_board
			
			cmp bombed, 1
			je draw_board
			
			jmp update_level_info
			
			draw_board:
			
				inc moves
			
				call drawBoard
				
				cmp bombed, 1
				je update_level_info
				
				call updateGrid
				
				cmp updated, 1
				je draw_board2
				
				cmp updatedSec, 1
				je draw_board2
				
				jmp update_level_info
				
				draw_board2:
				
					add score, 3
					call drawBoard
					
			update_level_info:
			
				call drawLevelInfo		; Displaying level info
				
				cmp moves, 15			; End level 1 if moves reach 15
				je return
			
			; #############################################################################################################################################
				
			; ****************
			; Esc key for exit
			; ****************
			
			check_key:	; If mouse is not clicked, check for esc key
				
				mov ah, 01	; Check for key input
				int 16h
					
				jz simulation	; If not key is pressed

				mov ah, 0
				int 16h

				cmp ah, 01	; If esc key is pressed
				jne simulation
				
		return:
		
			mov ax, score		; Saving score of level 1
			mov score1, ax
	
			ret
	
	level1 endp
	
; ===================================================================================================================================================================
	
	; ***************
	; Level 2 of game
	; ***************
	
	level2 proc
	
		call clearScreen
		call Print_LvlComp
	
		mov moves, 0
		mov score, 0
		mov randomRange, 6
		mov level_delay, 50
		call populateGridArray		; Populating grid array
		call clearScreen		; Selecting screen mode
		call drawBoardLevel2		; Drawing board of level1
		call drawLevelInfo2		; Displaying level info
		
		; *****************************************************
		; Mouse simulation and level-1 gameplay started started
		; *****************************************************
		
		mov flag, 0
		
		simulation:
		
			mov ax,01	; Displays the mouse cursor
			int 33h
		
			mov ax, 03
			int 33h
			
			mov x, cx	; Saving coordinates of mouse
			mov y, dx
			mov click, bl	; Saving mouse click
			
			cmp click, 0	; Checking if mouse is clicked or not
			je check_key	; If mouse is not clicked
			
			; ******************************************************************
			; Saving start coordinated where mouse is clicked for the first time
			; ******************************************************************
			
			cmp flag, 0
			je save_starts
			jmp next
			
			save_starts:
			
				mov ax, x
				mov mstartx, ax
				mov ax, y
				mov mstarty, ax
				mov flag, 1
			
			; *************************************
			; While mouse is clicked this loop runs
			; *************************************
			
			mouseClicked:
			
				mov ax,01	; Displays the mouse cursor
				int 33h
			
				mov ax, 03
				int 33h
				
				mov x, cx	; Saving coordinates of mouse
				mov y, dx
			
				cmp bl, 0
				je end_mouseClicked
			
			jmp mouseClicked
			end_mouseClicked:
			
			; ***************************************************
			; Saving end coordinates of where mouse click is left
			; ***************************************************
				
			next:
			
				mov ax, x
				mov mendx, ax
				mov ax, y
				mov mendy, ax
				
				mov flag, 0
				
			; #############################################################################################################################################
				
			call boxToSwap
			call boxToSwapWith
			call swap
			
			cmp swapped, 1		; If number is swapped draw board again
			je draw_board
			
			cmp bombed, 1
			je draw_board
			
			jmp update_level_info
			
			draw_board:
			
				inc moves
			
				call drawBoardLevel2
				
				cmp bombed, 1
				je update_level_info
				
				call updateGrid
				
				cmp updated, 1
				je draw_board2
				
				cmp updatedSec, 1
				je draw_board2
				
				jmp update_level_info
				
				draw_board2:
				
					add score, 3
					call drawBoardLevel2
					
			update_level_info:
			
				call drawLevelInfo2		; Displaying level info
				
				cmp moves, 15			; End level 1 if moves reach 15
				je return
			
			; #############################################################################################################################################
				
			; ****************
			; Esc key for exit
			; ****************
			
			check_key:	; If mouse is not clicked, check for esc key
				
				mov ah, 01	; Check for key input
				int 16h
					
				jz simulation	; If not key is pressed

				mov ah, 0
				int 16h

				cmp ah, 01	; If esc key is pressed
				jne simulation
				
		return:
		
			mov ax, score		; Saving score of level 2
			mov score3, ax
	
			ret
	
	level2 endp
	
; ===================================================================================================================================================================

	; ***************
	; Level 3 of game
	; ***************
	
	level3 proc
	
		call clearScreen
		call Print_LvlComp
	
		mov moves, 0
		mov score, 0
		mov randomRange, 7
		mov level_delay, 40
		call populateGridArray		; Populating grid array
		call clearScreen		; Selecting screen mode
		call drawBoard			; Drawing board of level1
		call drawLevelInfo3		; Displaying level info
		
		; *****************************************************
		; Mouse simulation and level-1 gameplay started started
		; *****************************************************
		
		mov flag, 0
		
		simulation:
		
			mov ax,01	; Displays the mouse cursor
			int 33h
		
			mov ax, 03
			int 33h
			
			mov x, cx	; Saving coordinates of mouse
			mov y, dx
			mov click, bl	; Saving mouse click
			
			cmp click, 0	; Checking if mouse is clicked or not
			je check_key	; If mouse is not clicked
			
			; ******************************************************************
			; Saving start coordinated where mouse is clicked for the first time
			; ******************************************************************
			
			cmp flag, 0
			je save_starts
			jmp next
			
			save_starts:
			
				mov ax, x
				mov mstartx, ax
				mov ax, y
				mov mstarty, ax
				mov flag, 1
			
			; *************************************
			; While mouse is clicked this loop runs
			; *************************************
			
			mouseClicked:
			
				mov ax,01	; Displays the mouse cursor
				int 33h
			
				mov ax, 03
				int 33h
				
				mov x, cx	; Saving coordinates of mouse
				mov y, dx
			
				cmp bl, 0
				je end_mouseClicked
			
			jmp mouseClicked
			end_mouseClicked:
			
			; ***************************************************
			; Saving end coordinates of where mouse click is left
			; ***************************************************
				
			next:
			
				mov ax, x
				mov mendx, ax
				mov ax, y
				mov mendy, ax
				
				mov flag, 0
				
			; #############################################################################################################################################
				
			call boxToSwap
			call boxToSwapWith
			call swap
			
			cmp swapped, 1		; If number is swapped draw board again
			je draw_board
			
			cmp bombed, 1
			je draw_board
			
			jmp update_level_info
			
			draw_board:
			
				inc moves
			
				call drawBoard
				
				cmp bombed, 1
				je update_level_info
				
				call updateGrid
				
				cmp updated, 1
				je draw_board2
				
				cmp updatedSec, 1
				je draw_board2
				
				jmp update_level_info
				
				draw_board2:
				
					add score, 3
					call drawBoard
					
			update_level_info:
			
				call drawLevelInfo3		; Displaying level info
				
				cmp moves, 15			; End level 1 if moves reach 15
				je return
			
			; #############################################################################################################################################
				
			; ****************
			; Esc key for exit
			; ****************
			
			check_key:	; If mouse is not clicked, check for esc key
				
				mov ah, 01	; Check for key input
				int 16h
					
				jz simulation	; If not key is pressed

				mov ah, 0
				int 16h

				cmp ah, 01	; If esc key is pressed
				jne simulation
				
		return:
		
			mov ax, score		; Saving score of level 2
			mov score3, ax
	
			ret
	
	level3 endp
	
; ===================================================================================================================================================================

	; **************************
	; To calculate highest score
	; **************************

	calculateHighScore proc
	
		mov ax, score1
		cmp ax, score2
		jg check_score3
		
		mov ax, score2
		cmp ax, score3
		jg cal_high
		
		mov ax, score3
		jmp cal_high
		
		check_score3:
		
			cmp ax, score1
			cmp ax, score3
			jg cal_high
			
			mov ax, score3
			
			
		cal_high:
		
			mov hScore, ax
	
		ret
	
	calculateHighScore endp

; ===================================================================================================================================================================

	; ************************************
	; Method to output game scores to file
	; ************************************

	gameOutputFile proc
	
		call calculateHighScore
		
		mov ah, 3Dh		; Function to open file
		mov al, 2
		mov dx, offset file_name
		int 21h
		
		jc print_error
		mov file_handle, ax	; Saving file handle
	
		mov di, offset profile
		call outputToFile
		
		; ************************
		; Writing score of level 1
		; ************************
		
		mov di, offset level1_line
		call outputToFile
		
		mov ax, score1			; Converting score to a string
		mov si, offset numberString
		call saveNumberStr
		mov di, offset numberString
		call outputToFile
		
		; ************************
		; Writing score of level 2
		; ************************
		
		mov di, offset level2_line
		call outputToFile
		
		mov ax, score2			; Converting score to a string
		mov si, offset numberString
		call saveNumberStr
		mov di, offset numberString
		call outputToFile
		
		; ************************
		; Writing score of level 3
		; ************************
		
		mov di, offset level3_line
		call outputToFile
		
		mov ax, score3			; Converting score to a string
		mov si, offset numberString
		call saveNumberStr
		mov di, offset numberString
		call outputToFile
		
		; *****************************
		; Writing highest score to file
		; *****************************
		
		mov di, offset hScore_line
		call outputToFile
		
		mov ax, hScore			; Converting score to a string
		mov si, offset numberString
		call saveNumberStr
		mov di, offset numberString
		call outputToFile
	
		jmp exit
		
		print_error:
		
			mov ah, 02
			mov dl, 'X'
			int 21h
			
		exit:
	
		ret
	
	gameOutputFile endp

; ===================================================================================================================================================================
	
	; ************************
	; Method to output to file
	; ************************
	
	outputToFile proc
		
		mov ah, 42h		; Move pointer to end of file
		mov al, 02h
		mov bx, file_handle
		mov cx, 0
		mov dx, 0
		int 21h
		
		write_digits:
			
			mov al, [di]
			cmp al, '$'
			je end_write_digits
				
			mov al, [di]
			mov string_final[0], al
				
			mov ah, 40h			; Function to write to file
			mov dx, offset string_final
			mov bx, file_handle
			mov cx, 1
			int 21h
				
			inc di
				
		jmp write_digits
				
		end_write_digits:
		
		mov dx, offset str_endl		; Next line in file
		mov ah, 40h
		mov bx, file_handle
		mov cx, 1
		int 21h
	
		ret
	
	outputToFile endp
	
; ===================================================================================================================================================================

	; **********************************************
	; To draw name, score etc on screen (of level 2)
	; **********************************************
	
	drawLevelInfo2 proc
	
		; **********************
		; Displaying name on top
		; **********************
	
		mov color, 2
		mov si, offset name_line
		mov x, 9
		mov y, 2
		call displayScreenStr
		
		mov color, 9
		mov si, offset profile
		mov x, 15
		call displayScreenStr
		
		; ***********************
		; Displaying level on top
		; ***********************
	
		mov color, 07
		mov si, offset level2_line
		mov x, 64
		mov y, 13
		call displayScreenStr
		
		; **************************
		; Displaying score on screen
		; **************************
		
		mov numberString[0], '$'
		mov numberString[1], '$'
		mov numberString[2], '$'
		
		mov color, 2
		mov si, offset score_line
		mov x, 29
		mov y, 2
		call displayScreenStr
		
		mov ax, score			; Converting score to a string
		mov si, offset numberString
		call saveNumberStr
		
		mov color, 9
		mov si, offset numberString
		add x, 7
		call displayScreenStr
		
		; **************************
		; Displaying moves on screen
		; **************************
		
		mov numberString[0], '$'
		mov numberString[1], '$'
		mov numberString[2], '$'
		
		mov color, 2
		mov si, offset moves_line
		mov x, 48
		mov y, 2
		call displayScreenStr
		
		mov ax, moves			; Converting score to a string
		mov si, offset numberString
		call saveNumberStr
		
		mov color, 9
		mov si, offset numberString
		add x, 7
		call displayScreenStr
	
		ret
	
	drawLevelInfo2 endp
	
; ===================================================================================================================================================================

	; *****************
	; Draw level2 board
	; *****************
	
	drawBoardLevel2 proc
	
		; *********************************
		; Displaying black grid array first
		; *********************************
		
		mov x, 10			; Drawing grid array as pixels on screen
		mov y, 5
		call displayGridArrayPixelBlack
		
		; **********************
		; Drawing colorful board
		; **********************
	
		mov x, 185			; Drawing board (Grid) on screen
		mov y, 72
		mov color, 01
		mov boxWidth, 39
		mov boxHeight, 32
		call drawGridLevel2
		
		mov x, 25			; Drawing grid array as pixels on screen (Part 1, 3)
		mov y, 5
		call displayGridArrayPixelLevel2Part1
		
		mov x, 10
		mov y, 11
		mov si, 3
		mov di, 0			; Drawing grid array as pixels on screen (Part 2)
		mov level2rows, 3
		mov level2Columns, 9
		call displayGridArrayPixelLevel2Part2
	
		ret
	
	drawBoardLevel2 endp
	
; ===================================================================================================================================================================

	; *****************************
	; Method to draw grid (Level 2)
	; *****************************
	
	drawGridLevel2 proc
	
		push ax
		push bx
		push cx
		push dx
		
		; **************************
		; Displaying part 1 of boxes
		; **************************
		
		mov bx, 6
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxWidth		; Calculating new x-coordinate for next box
		add x, ax 
		
		mov bx, 8
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxWidth		; Calculating new x-coordinate for next box
		add x, ax 
		
		mov bx, 10
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxHeight			; Calculating new y-coordinate for next box
		add y, ax
		
		mov x, 185
		
		mov bx, 26
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxWidth		; Calculating new x-coordinate for next box
		add x, ax 
		
		mov bx, 28
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxWidth		; Calculating new x-coordinate for next box
		add x, ax 
		
		mov bx, 30
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxHeight			; Calculating new y-coordinate for next box
		add y, ax
		
		mov x, 185
		
		mov bx, 46
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxWidth		; Calculating new x-coordinate for next box
		add x, ax 
		
		mov bx, 48
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxWidth		; Calculating new x-coordinate for next box
		add x, ax 
		
		mov bx, 50
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxHeight			; Calculating new y-coordinate for next box
		add y, ax
		
		
		
		; **************************
		; Displaying part 2 of boxes
		; **************************
		
		mov x, 68
		mov cx, 3
		mov si, 3
		
		outerLoop2:
		
			push cx
			push x
		
			mov cx, 9
			mov di, 0
			
			innerLoop2:
			
				mov dx, 0			; Calculating 2D array index (current row * columns + current column)
				mov ax, si
				mov bx, columns
				mul bx
				add ax, di
				mov bx, 2
				mul bx
				mov bx, ax
				
				call drawBox			; Drawing box
				
				mov ax, x			; Saving starting and ending coordinates of current box
				mov startx[bx], ax
				mov ax, y
				mov starty[bx], ax
				mov ax, comx
				mov endx[bx], ax
				mov ax, comy
				mov endy[bx], ax
				
				mov ax, boxWidth		; Calculating new x-coordinate for next box
				add x, ax
				
				inc di
			
			loop innerLoop2
		
			pop x	
			pop cx
			
			mov ax, boxHeight			; Calculating new y-coordinate for next box
			add y, ax
			
			inc si
		
		loop outerLoop2
		
		; **************************
		; Displaying part 3 of boxes
		; **************************
		
		mov x, 185
		
		mov bx, 126
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxWidth		; Calculating new x-coordinate for next box
		add x, ax 
		
		mov bx, 128
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxWidth		; Calculating new x-coordinate for next box
		add x, ax 
		
		mov bx, 130
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxHeight			; Calculating new y-coordinate for next box
		add y, ax
		
		mov x, 185
		
		mov bx, 146
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxWidth		; Calculating new x-coordinate for next box
		add x, ax 
		
		mov bx, 148
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxWidth		; Calculating new x-coordinate for next box
		add x, ax 
		
		mov bx, 150
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxHeight			; Calculating new y-coordinate for next box
		add y, ax
		
		mov x, 185
		
		mov bx, 166
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxWidth		; Calculating new x-coordinate for next box
		add x, ax 
		
		mov bx, 168
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxWidth		; Calculating new x-coordinate for next box
		add x, ax 
		
		mov bx, 170
		call drawBox
		mov ax, x			; Saving starting and ending coordinates of current box
		mov startx[bx], ax
		mov ax, y
		mov starty[bx], ax
		mov ax, comx
		mov endx[bx], ax
		mov ax, comy
		mov endy[bx], ax
		mov ax, boxHeight			; Calculating new y-coordinate for next box
		
		return:
		
		pop dx
		pop cx
		pop bx
		pop ax
	
		ret
	
	drawGridLevel2 endp
	
; ===================================================================================================================================================================
	
	; **********************************************************************
	; To display grid array with random numbers as pixels on screen (Part 2)
	; **********************************************************************
	
	displayGridArrayPixelLevel2Part2 proc
			
			mov cx, level2rows
			
			outer_loop:
			
				cmp cx, 0
				je end_outer_loop
			
				push cx
				push x
				
				mov cx, level2Columns
				mov di, 0
				
				inner_loop:
				
					mov dx, 0		; Calculating 2D array index (current row * columns + current column)
					mov ax, si
					mov bx, columns
					mul bx
					add ax, di
					mov bx, ax
					
					push si
					mov ah, 0
					mov al, gridArray[bx]
					
					cmp al, '1'
					je colorOne
					
					cmp al, '2'
					je colorTwo
					
					cmp al, '3'
					je colorThree
					
					cmp al, '4'
					je colorFour
					
					cmp al, '5'
					je colorFive
					
					cmp al, 'B'
					je colorBee
					
					cmp al, 'X'
					je colorX
					
					mov color, 15
					jmp next
					
					colorOne:
					
						mov color, 5
						jmp next
						
					colorTwo:
					
						mov color, 3
						jmp next
						
					colorThree:
					
						mov color, 2
						jmp next
						
					colorFour:
					
						mov color, 7
						jmp next
					
					colorFive:
					
						mov color, 6
						jmp next
						
					colorBee:
					
						mov color, 8
						jmp next
						
					colorX:
					
						mov color, 10
						jmp next
					
					next:
					
						mov string[0], al
						mov si, offset string
						call displayScreenStr
						pop si
						
						add x, 5
						
						inc di
				
				loop inner_loop
				
				pop x
				pop cx
				
				inc si
				dec cx
				
				add y, 2
			
			jmp outer_loop
			
			end_outer_loop:
			
		ret
	
	displayGridArrayPixelLevel2Part2 endp
	
; ===================================================================================================================================================================
	
	; *****************************************
	; Set color of numbers to display on screen
	; *****************************************
	
	setColor proc
	
		check_for_color:
			
				cmp al, '1'
				je colorOne
					
				cmp al, '2'
				je colorTwo
					
				cmp al, '3'
				je colorThree
					
				cmp al, '4'
				je colorFour
					
				cmp al, '5'
				je colorFive
					
				cmp al, 'B'
				je colorBee
					
				cmp al, 'X'
				je colorX
					
				mov color, 15
				jmp next
					
				colorOne:
					
					mov color, 5
					jmp next
						
				colorTwo:
					
					mov color, 3
					jmp next
						
				colorThree:
					
					mov color, 2
					jmp next
						
				colorFour:
					
					mov color, 7
					jmp next
					
				colorFive:
					
					mov color, 6
					jmp next
						
				colorBee:
					
					mov color, 8
					jmp next
						
				colorX:
					
					mov color, 10
					jmp next
					
		next:
		
			mov string[0], al			; Displaying after setting color
			mov si, offset string
			call displayScreenStr
	
		ret
	
	setColor endp
	
; ===================================================================================================================================================================	
	
	; *************************************************************************
	; To display grid array with random numbers as pixels on screen (Part 1, 3)
	; *************************************************************************
	
	displayGridArrayPixelLevel2Part1 proc
	
			; *******************************
			; Displaying part 1 of grid array
			; *******************************
			
			mov bx, 3
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add x, 5
			
			mov bx, 4
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add x, 5
			
			mov bx, 5
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add y, 2
			
			mov x, 25
			
			mov bx, 13
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add x, 5
			
			mov bx, 14
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add x, 5
			
			mov bx, 15
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add y, 2
			
			mov x, 25
			
			mov bx, 23
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add x, 5
			
			mov bx, 24
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add x, 5
			
			mov bx, 25
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			
			; *******************************
			; Displaying part 3 of grid array
			; *******************************
			
			mov x, 25
			add y, 8
			
			mov bx, 63
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add x, 5
			
			mov bx, 64
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add x, 5
			
			mov bx, 65
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add y, 2
			
			mov x, 25
			
			mov bx, 73
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add x, 5
			
			mov bx, 74
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add x, 5
			
			mov bx, 75
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add y, 2
			
			mov x, 25
			
			mov bx, 83
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add x, 5
			
			mov bx, 84
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			add x, 5
			
			mov bx, 85
			mov ah, 0
			mov al, gridArray[bx]
			call setColor
			
			ret
	
	displayGridArrayPixelLevel2Part1 endp
	
; ===================================================================================================================================================================

	; **********************************************
	; To draw name, score etc on screen (of level 3)
	; **********************************************
	
	drawLevelInfo3 proc
	
		; **********************
		; Displaying name on top
		; **********************
	
		mov color, 2
		mov si, offset name_line
		mov x, 9
		mov y, 2
		call displayScreenStr
		
		mov color, 9
		mov si, offset profile
		mov x, 15
		call displayScreenStr
		
		; ***********************
		; Displaying level on top
		; ***********************
	
		mov color, 07
		mov si, offset level3_line
		mov x, 64
		mov y, 13
		call displayScreenStr
		
		; **************************
		; Displaying score on screen
		; **************************
		
		mov numberString[0], '$'
		mov numberString[1], '$'
		mov numberString[2], '$'
		
		mov color, 2
		mov si, offset score_line
		mov x, 29
		mov y, 2
		call displayScreenStr
		
		mov ax, score			; Converting score to a string
		mov si, offset numberString
		call saveNumberStr
		
		mov color, 9
		mov si, offset numberString
		add x, 7
		call displayScreenStr
		
		; **************************
		; Displaying moves on screen
		; **************************
		
		mov numberString[0], '$'
		mov numberString[1], '$'
		mov numberString[2], '$'
		
		mov color, 2
		mov si, offset moves_line
		mov x, 48
		mov y, 2
		call displayScreenStr
		
		mov ax, moves			; Converting score to a string
		mov si, offset numberString
		call saveNumberStr
		
		mov color, 9
		mov si, offset numberString
		add x, 7
		call displayScreenStr
	
		ret
	
	drawLevelInfo3 endp
	
; ===================================================================================================================================================================

	; ****************************************
	; Clearing all numbes if swapped with bomb
	; ****************************************

	bombDestruction proc
	
		mov cx, rows
		mov si, 0
		mov di, 0
			
		outer_loop:
			
			push cx
				
			mov cx, columns
			mov di, 0
				
			inner_loop:
				
				mov dx, 0		; Calculating 2D array index (current row * columns + current column)
				mov ax, si
				mov bx, columns
				mul bx
				add ax, di
				mov bx, ax
				
				mov al, targetNumber
				cmp gridArray[bx], al
				je destroy
				jmp next
				
				destroy:
				
					generate_number:
					
						mov randomRange, 5
						mov time_delay, 100
						call generateRandom
						
					mov al, targetNumber
					cmp randomNumber, al
					je generate_number
				
					mov ah, 0
					mov al, randomNumber
					mov gridArray[bx], al	; Saving random number in matrix
				
				next:
					
				inc di
				
			loop inner_loop
				
			pop cx
				
			inc si
			
		loop outer_loop
		
		mov bombed, 1
		add score, 20
	
		ret
	
	bombDestruction endp
	
; ===================================================================================================================================================================

	; **********************************
	; To swap two numbers in given array
	; **********************************
	
	swap proc
	
		push ax
		push bx
		push dx
		
		; ***************************************
		; Restricting players movement in level 3
		; ***************************************
		
		mov bx, toIndex
		cmp gridArray[bx], 'X'
		je not_swapped
		
		mov bx, withIndex
		cmp gridArray[bx], 'X'
		je not_swapped
		
		; ****************************
		; Bomb checking and destroying
		; ****************************
		
		mov bombed, 0
		
		mov bx, toIndex
		cmp gridArray[bx], 'B'
		je not_swapped
		
		mov bx, withIndex
		cmp gridArray[bx], 'B'
		je destroy_bomb
		
		; *******************************************************************
		; Validating Indexes (Numbers are not swapped if indexes are invalid)
		; *******************************************************************
		
		cmp toIndex, 0		; If to swap index is out of grid
		jl not_swapped
		
		cmp withIndex, 0	; If to swap with index is out of grid
		jl not_swapped
		
		mov ax, toIndex		; If to swap with index is on right of to swap index
		add ax, 1
		cmp withIndex, ax
		je start_swapping
		
		mov ax, toIndex		; If to swap with index is on left of to swap index
		sub ax, 1
		cmp withIndex, ax
		je start_swapping
		
		mov ax, toIndex		; If to swap with index is on up of to swap index
		add ax, columns
		cmp withIndex, ax
		je start_swapping
		
		mov ax, toIndex		; If to swap with index is on down of to swap index
		sub ax, columns
		cmp withIndex, ax
		je start_swapping
		
		jmp not_swapped		; Do not swap if above conditions are not full filled
		
		; *************************
		; Swapping numbers in array
		; *************************
		
		start_swapping:
		
			mov bx, toIndex
			mov al, gridArray[bx]
			
			mov bx, withIndex
			mov dl, gridArray[bx]
			
			mov bx, toIndex
			mov gridArray[bx], dl
			
			mov bx, withIndex
			mov gridArray[bx], al
			
			mov swapped, 1			; If numbers are swapped set flag
			jmp return
		
		not_swapped:			; If numbers are not swapped unset flag
		
			mov swapped, 0
			jmp return
			
		destroy_bomb:
		
			generate_number:
		
				mov randomRange, 5		; New number in place of bomb
				call generateRandom
		
			mov bx, toIndex
			mov al, gridArray[bx]
			mov targetNumber, al
			
			mov al, targetNumber
			cmp randomNumber, al
			je generate_number
			
			mov bx, withIndex
			mov al, randomNumber
			mov gridArray[bx], al
		
			call bombDestruction		; Destroy all numbers if swapped with bomb
		
		return:
		
			pop dx
			pop bx
			pop ax
		
			ret
	
	swap endp
	
; ===================================================================================================================================================================

	; **********************************************
	; To draw name, score etc on screen (of level 1)
	; **********************************************
	
	drawLevelInfo proc
	
		; **********************
		; Displaying name on top
		; **********************
	
		mov color, 2
		mov si, offset name_line
		mov x, 9
		mov y, 2
		call displayScreenStr
		
		mov color, 9
		mov si, offset profile
		mov x, 15
		call displayScreenStr
		
		; ***********************
		; Displaying level on top
		; ***********************
	
		mov color, 07
		mov si, offset level1_line
		mov x, 64
		mov y, 13
		call displayScreenStr
		
		; **************************
		; Displaying score on screen
		; **************************
		
		mov numberString[0], '$'
		mov numberString[1], '$'
		mov numberString[2], '$'
		
		mov color, 2
		mov si, offset score_line
		mov x, 29
		mov y, 2
		call displayScreenStr
		
		mov ax, score			; Converting score to a string
		mov si, offset numberString
		call saveNumberStr
		
		mov color, 9
		mov si, offset numberString
		add x, 7
		call displayScreenStr
		
		; **************************
		; Displaying moves on screen
		; **************************
		
		mov numberString[0], '$'
		mov numberString[1], '$'
		mov numberString[2], '$'
		
		mov color, 2
		mov si, offset moves_line
		mov x, 48
		mov y, 2
		call displayScreenStr
		
		mov ax, moves			; Converting score to a string
		mov si, offset numberString
		call saveNumberStr
		
		mov color, 9
		mov si, offset numberString
		add x, 7
		call displayScreenStr
	
		ret
	
	drawLevelInfo endp
	
; ===================================================================================================================================================================

	; ***********************************************************
	; Method to update grid after swapping (If combos are formed)
	; ***********************************************************
	
	updateGrid proc
	
		call updateTarget
		call updateSecTarget
	
		ret
	
	updateGrid endp
	
; ===================================================================================================================================================================

	; ****************************************
	; To update number related to targetNumber
	; ****************************************
	
	updateTarget proc
	
		push ax
		push bx
		push cx
		push dx
		
		; ***********************
		; Crushing right and left
		; ***********************
		
		mov bx, withIndex		; Locating and saving target number
		mov ah, 0
		mov al, gridArray[bx]
		mov targetNumber, al
		
		; ******************************
		; Counting numbers on right side
		; ******************************
		
		mov rightCount, 0
		mov bx, withIndex
		add bx, 1
	
		check_right:
		
			mov ah, 0
			mov al, gridArray[bx]
			cmp targetNumber, al
			jne end_check_right
			
			inc rightCount
			inc bx
		
		jmp check_right
		end_check_right:
		
		; *****************************
		; Counting numbers on left side
		; *****************************
		
		mov leftCount, 0
		mov bx, withIndex
		sub bx, 1
	
		check_left:
		
			mov ah, 0
			mov al, gridArray[bx]
			cmp targetNumber, al
			jne end_check_left
			
			inc leftCount
			dec bx
		
		jmp check_left
		end_check_left:
		
		; ********************************
		; Filling with new numbers started
		; ********************************
		
		mov updated, 0			; Set to zero as nothing is updated
		
		cmp rightCount, 0		; If there are no matching elements on right, move to left
		je start_filling_left
		
		cmp rightCount, 1		; If there is 1 matching element on right, move to left
		je start_filling_left
				
		; *********************************************************************************************
		; Filling numbers on right with new numbers (If there are 2 or more matching elements on right)
		; *********************************************************************************************
		
		mov randomRange, 5		; Filling target number with new number
		call generateRandom
		mov bx, withIndex
		mov ah, 0
		mov al, randomNumber
		mov gridArray[bx], al
		
		add bx, 1
		mov ch, 0
		mov cl, rightCount
		
		fill_right:
			
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			inc bx
		
		loop fill_right
		
		mov updated, 1
		
		; ***********************************
		; Start filling left side after right
		; ***********************************
		
		start_filling_left:
		
			cmp leftCount, 0
			je continue_up_down
			
			cmp leftCount, 1
			je fill_one_both
			
			cmp rightCount, 1
			je also_fill_right
			jmp continue_left
			
			also_fill_right:
			
				mov randomRange, 5		; Filling target number with new number
				call generateRandom
				mov bx, withIndex
				inc bx
				mov ah, 0
				mov al, randomNumber
				mov gridArray[bx], al
			
			continue_left:
			
				; *********************************************************************************************
				; Filling numbers on right with new numbers (If there are 2 or more matching elements on right)
				; *********************************************************************************************
			
				mov randomRange, 5		; Filling target number with new number
				call generateRandom
				mov bx, withIndex
				mov ah, 0
				mov al, randomNumber
				mov gridArray[bx], al
				
				sub bx, 1
				mov ch, 0
				mov cl, leftCount
				
				fill_left:
					
					mov randomRange, 5
					call generateRandom
					mov ah, 0
					mov al, randomNumber
					mov gridArray[bx], al
					
					dec bx
				
				loop fill_left
				
				mov updated, 1
				jmp continue_up_down
				
		fill_one_both:				; Fill 1 on right and 1 on left with new number
		
			cmp rightCount, 0
			je continue_up_down
		
			mov bx, withIndex
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			inc bx
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			sub bx, 2
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			mov updated, 1
			
		; ********************
		; Crushing up and down
		; ********************
			
		continue_up_down:
			
		mov bx, withIndex		; Locating and saving target number
		mov ah, 0
		mov al, gridArray[bx]
		mov targetNumber, al
		
		; ***************************
		; Counting numbers on up side
		; ***************************
		
		mov upCount, 0
		mov bx, withIndex
		sub bx, columns
	
		check_up:
		
			mov ah, 0
			mov al, gridArray[bx]
			cmp targetNumber, al
			jne end_check_up
			
			inc upCount
			sub bx, columns
		
		jmp check_up
		end_check_up:
		
		; *****************************
		; Counting numbers on down side
		; *****************************
		
		mov downCount, 0
		mov bx, withIndex
		add bx, columns
	
		check_down:
		
			mov ah, 0
			mov al, gridArray[bx]
			cmp targetNumber, al
			jne end_check_down
			
			inc downCount
			add bx, columns
		
		jmp check_down
		end_check_down:
		
		; ********************************
		; Filling with new numbers started
		; ********************************
		
		cmp upCount, 0		; If there are no matching elements on right, move to left
		je start_filling_down
		
		cmp upCount, 1		; If there is 1 matching element on right, move to left
		je start_filling_down
				
		; ********************************************************************************************
		; Filling numbers on up side with new numbers (If there are 2 or more matching elements on up)
		; ********************************************************************************************
		
		mov randomRange, 5		; Filling target number with new number
		call generateRandom
		mov bx, withIndex
		mov ah, 0
		mov al, randomNumber
		mov gridArray[bx], al
		
		sub bx, columns
		mov ch, 0
		mov cl, upCount
		
		fill_up:
			
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			sub bx, columns
		
		loop fill_up
		
		mov updated, 1
		
		; ********************************
		; Start filling down side after up
		; ********************************
		
		start_filling_down:
		
			cmp downCount, 0
			je return
			
			cmp downCount, 1
			je fill_one_both2
			
			cmp upCount, 1
			je also_fill_up
			jmp continue_down
			
			also_fill_up:
			
				mov randomRange, 5		; Filling target number with new number
				call generateRandom
				mov bx, withIndex
				sub bx, columns
				mov ah, 0
				mov al, randomNumber
				mov gridArray[bx], al
			
			continue_down:
			
				; *******************************************************************************************
				; Filling numbers on down with new numbers (If there are 2 or more matching elements on down)
				; *******************************************************************************************
			
				mov randomRange, 5		; Filling target number with new number
				call generateRandom
				mov bx, withIndex
				mov ah, 0
				mov al, randomNumber
				mov gridArray[bx], al
				
				add bx, columns
				mov ch, 0
				mov cl, downCount
				
				fill_down:
					
					mov randomRange, 5
					call generateRandom
					mov ah, 0
					mov al, randomNumber
					mov gridArray[bx], al
					
					add bx, columns
				
				loop fill_down
				
				mov updated, 1
				jmp return
			
				
		fill_one_both2:				; Fill 1 on up and 1 on down with new number
		
			cmp upCount, 0
			je return
		
			mov bx, withIndex
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			sub bx, columns
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			add bx, columns
			add bx, columns
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			mov updated, 1	
			
		return: jmp end_fn
		
		; ***********************************
		; Increasing score on basis of combos
		; ***********************************
		
		mov bx, 0
		
		cmp rightCount, 1
		je add_left
		
		cmp rightCount, 1
		jg add_right
		
		jmp add_left
		
		add_right:
		
			mov ah, 0
			mov al, rightCount
			add score, ax
			mov bx, 1
		
		add_left:
		
			cmp leftCount, 1
			je add_left_right
		
			cmp leftCount, 1
			jg add_leftt
			
			jmp add_next
			
			add_leftt:
			
				cmp rightCount, 1
				je add_right_also
				
				jmp add_only_left
				
				add_right_also:
				
					mov ah, 0
					mov al, rightCount
					add score, ax
					mov bx, 1
					
				add_only_left:
		
					mov ah, 0
					mov al, leftCount
					add score, ax
					mov bx, 1
				
				jmp add_next
			
		add_left_right:
		
				mov ah, 0
				mov al, rightCount
				add score, ax
				mov ah, 0
				mov al, leftCount
				add score, ax
				mov bx, 1
				
		add_next:
		
			cmp bx, 1
			je inc_Score
			
			jmp add_up_down_side
			
			inc_Score:
			
				inc score
				
		add_up_down_side:
		
		mov bx, 0
		
		cmp upCount, 1
		je add_down
		
		cmp upCount, 1
		jg add_up
		
		jmp add_down
		
		add_up:
		
			mov ah, 0
			mov al, upCount
			add score, ax
			mov bx, 1
		
		add_down:
		
			cmp downCount, 1
			je add_up_down
		
			cmp downCount, 1
			jg add_downn
			
			jmp end_adding
			
			add_downn:
			
				cmp upCount, 1
				je add_up_also
				
				jmp add_only_down
				
				add_up_also:
				
					mov ah, 0
					mov al, upCount
					add score, ax
					mov bx, 1
					
				add_only_down:
		
					mov ah, 0
					mov al, downCount
					add score, ax
					mov bx, 1
				
				jmp end_adding
			
		add_up_down:
		
				mov ah, 0
				mov al, upCount
				add score, ax
				mov ah, 0
				mov al, downCount
				add score, ax
				mov bx, 1
				
		end_adding:
		
			cmp bx, 1
			je inc_Score2
			
			jmp end_fn
			
			inc_Score2:
			
				inc score
				
		end_fn:
			
			pop dx
			pop cx
			pop bx
			pop ax
		
			ret
	
	updateTarget endp
	
; ===================================================================================================================================================================

	; ********************************************
	; To update number related to secondary target
	; ********************************************
	
	updateSecTarget proc
	
		push ax
		push bx
		push cx
		push dx
		
		mov bx, toIndex			; Locating and saving target number
		mov ah, 0
		mov al, gridArray[bx]
		mov secTarget, al
		
		; ******************************
		; Counting numbers on right side
		; ******************************
		
		mov rightCount, 0
		mov bx, toIndex
		add bx, 1
	
		check_right:
		
			mov ah, 0
			mov al, gridArray[bx]
			cmp secTarget, al
			jne end_check_right
			
			inc rightCount
			inc bx
		
		jmp check_right
		end_check_right:
		
		; *****************************
		; Counting numbers on left side
		; *****************************
		
		mov leftCount, 0
		mov bx, toIndex
		sub bx, 1
	
		check_left:
		
			mov ah, 0
			mov al, gridArray[bx]
			cmp secTarget, al
			jne end_check_left
			
			inc leftCount
			dec bx
		
		jmp check_left
		end_check_left:
		
		; ********************************
		; Filling with new numbers started
		; ********************************
		
		mov updatedSec, 0			; Set to zero as nothing is updated
		
		cmp rightCount, 0		; If there are no matching elements on right, move to left
		je start_filling_left
		
		cmp rightCount, 1		; If there is 1 matching element on right, move to left
		je start_filling_left
				
		; *********************************************************************************************
		; Filling numbers on right with new numbers (If there are 2 or more matching elements on right)
		; *********************************************************************************************
		
		mov randomRange, 5		; Filling target number with new number
		call generateRandom
		mov bx, toIndex
		mov ah, 0
		mov al, randomNumber
		mov gridArray[bx], al
		
		add bx, 1
		mov ch, 0
		mov cl, rightCount
		
		fill_right:
			
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			inc bx
		
		loop fill_right
		
		mov updatedSec, 1
		
		; ***********************************
		; Start filling left side after right
		; ***********************************
		
		start_filling_left:
		
			cmp leftCount, 0
			je continue_up_down
			
			cmp leftCount, 1
			je fill_one_both
			
			cmp rightCount, 1
			je also_fill_right
			jmp continue_left
			
			also_fill_right:
			
				mov randomRange, 5		; Filling target number with new number
				call generateRandom
				mov bx, toIndex
				inc bx
				mov ah, 0
				mov al, randomNumber
				mov gridArray[bx], al
			
			continue_left:
			
				; *********************************************************************************************
				; Filling numbers on right with new numbers (If there are 2 or more matching elements on right)
				; *********************************************************************************************
			
				mov randomRange, 5		; Filling target number with new number
				call generateRandom
				mov bx, toIndex
				mov ah, 0
				mov al, randomNumber
				mov gridArray[bx], al
				
				sub bx, 1
				mov ch, 0
				mov cl, leftCount
				
				fill_left:
					
					mov randomRange, 5
					call generateRandom
					mov ah, 0
					mov al, randomNumber
					mov gridArray[bx], al
					
					dec bx
				
				loop fill_left
				
				mov updatedSec, 1
				jmp continue_up_down
				
		fill_one_both:				; Fill 1 on right and 1 on left with new number
		
			cmp rightCount, 0
			je continue_up_down
		
			mov bx, toIndex
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			inc bx
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			sub bx, 2
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			mov updatedSec, 1
			
		; ********************
		; Crushing up and down
		; ********************
			
		continue_up_down:
			
		mov bx, toIndex		; Locating and saving target number
		mov ah, 0
		mov al, gridArray[bx]
		mov secTarget, al
		
		; ***************************
		; Counting numbers on up side
		; ***************************
		
		mov upCount, 0
		mov bx, toIndex
		sub bx, columns
	
		check_up:
		
			mov ah, 0
			mov al, gridArray[bx]
			cmp secTarget, al
			jne end_check_up
			
			inc upCount
			sub bx, columns
		
		jmp check_up
		end_check_up:
		
		; *****************************
		; Counting numbers on down side
		; *****************************
		
		mov downCount, 0
		mov bx, toIndex
		add bx, columns
	
		check_down:
		
			mov ah, 0
			mov al, gridArray[bx]
			cmp secTarget, al
			jne end_check_down
			
			inc downCount
			add bx, columns
		
		jmp check_down
		end_check_down:
		
		; ********************************
		; Filling with new numbers started
		; ********************************
		
		cmp upCount, 0		; If there are no matching elements on right, move to left
		je start_filling_down
		
		cmp upCount, 1		; If there is 1 matching element on right, move to left
		je start_filling_down
				
		; ********************************************************************************************
		; Filling numbers on up side with new numbers (If there are 2 or more matching elements on up)
		; ********************************************************************************************
		
		mov randomRange, 5		; Filling target number with new number
		call generateRandom
		mov bx, toIndex
		mov ah, 0
		mov al, randomNumber
		mov gridArray[bx], al
		
		sub bx, columns
		mov ch, 0
		mov cl, upCount
		
		fill_up:
			
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			sub bx, columns
		
		loop fill_up
		
		mov updated, 1
		
		; ********************************
		; Start filling down side after up
		; ********************************
		
		start_filling_down:
		
			cmp downCount, 0
			je return
			
			cmp downCount, 1
			je fill_one_both2
			
			cmp upCount, 1
			je also_fill_up
			jmp continue_down
			
			also_fill_up:
			
				mov randomRange, 5		; Filling target number with new number
				call generateRandom
				mov bx, toIndex
				sub bx, columns
				mov ah, 0
				mov al, randomNumber
				mov gridArray[bx], al
			
			continue_down:
			
				; *******************************************************************************************
				; Filling numbers on down with new numbers (If there are 2 or more matching elements on down)
				; *******************************************************************************************
			
				mov randomRange, 5		; Filling target number with new number
				call generateRandom
				mov bx, toIndex
				mov ah, 0
				mov al, randomNumber
				mov gridArray[bx], al
				
				add bx, columns
				mov ch, 0
				mov cl, downCount
				
				fill_down:
					
					mov randomRange, 5
					call generateRandom
					mov ah, 0
					mov al, randomNumber
					mov gridArray[bx], al
					
					add bx, columns
				
				loop fill_down
				
				mov updated, 1
				jmp return
				
		fill_one_both2:				; Fill 1 on up and 1 on down with new number
		
			cmp upCount, 0
			je return
		
			mov bx, toIndex
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			sub bx, columns
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			add bx, columns
			add bx, columns
			mov randomRange, 5
			call generateRandom
			mov ah, 0
			mov al, randomNumber
			mov gridArray[bx], al
			
			mov updated, 1
			
		return:	jmp end_fn
		
		; ***********************************
		; Increasing score on basis of combos
		; ***********************************
		
		mov bx, 0
		
		cmp rightCount, 1
		je add_left
		
		cmp rightCount, 1
		jg add_right
		
		jmp add_left
		
		add_right:
		
			mov ah, 0
			mov al, rightCount
			add score, ax
			mov bx, 1
		
		add_left:
		
			cmp leftCount, 1
			je add_left_right
		
			cmp leftCount, 1
			jg add_leftt
			
			jmp add_next
			
			add_leftt:
			
				cmp rightCount, 1
				je add_right_also
				
				jmp add_only_left
				
				add_right_also:
				
					mov ah, 0
					mov al, rightCount
					add score, ax
					mov bx, 1
					
				add_only_left:
		
					mov ah, 0
					mov al, leftCount
					add score, ax
					mov bx, 1
				
				jmp add_next
			
		add_left_right:
		
				mov ah, 0
				mov al, rightCount
				add score, ax
				mov ah, 0
				mov al, leftCount
				add score, ax
				mov bx, 1
				
		add_next:
		
			cmp bx, 1
			je inc_Score
			
			jmp add_up_down_side
			
			inc_Score:
			
				inc score
				
		add_up_down_side:
		
		mov bx, 0
		
		cmp upCount, 1
		je add_down
		
		cmp upCount, 1
		jg add_up
		
		jmp add_down
		
		add_up:
		
			mov ah, 0
			mov al, upCount
			add score, ax
			mov bx, 1
		
		add_down:
		
			cmp downCount, 1
			je add_up_down
		
			cmp downCount, 1
			jg add_downn
			
			jmp end_adding
			
			add_downn:
			
				cmp upCount, 1
				je add_up_also
				
				jmp add_only_down
				
				add_up_also:
				
					mov ah, 0
					mov al, upCount
					add score, ax
					mov bx, 1
					
				add_only_down:
		
					mov ah, 0
					mov al, downCount
					add score, ax
					mov bx, 1
				
				jmp end_adding
			
		add_up_down:
		
				mov ah, 0
				mov al, upCount
				add score, ax
				mov ah, 0
				mov al, downCount
				add score, ax
				mov bx, 1
				
		end_adding:
		
			cmp bx, 1
			je inc_Score2
			
			jmp end_fn
			
			inc_Score2:
			
				inc score
		
		end_fn:
			
			pop dx
			pop cx
			pop bx
			pop ax
		
			ret
	
	updateSecTarget endp
	
; ===================================================================================================================================================================

	; ******************************************
	; To find box to swap with after mouse input
	; ******************************************
	
	boxToSwapWith proc
	
		push ax
		push bx
		push cx
		push dx
	
		mov cx, rows
		mov si, 0
		mov di, 0
			
		outer_loop:
			
			push cx
				
			mov cx, columns
			mov di, 0
				
			inner_loop:
				
				mov dx, 0		; Calculating 2D array index (current row * columns + current column)
				mov ax, si
				mov bx, columns
				mul bx
				add ax, di
				
				mov withSwapRow, si		; Saving indexes
				mov withSwapColumn, di
				
				mov bx, 2
				mul bx
				mov bx, ax
					
				mov ax, startx[bx]
				cmp mendx, ax
				jg compare_endx
				jmp next
				
				compare_endx:
				
					mov ax, endx[bx]
					cmp mendx, ax
					jl compare_starty
					jmp next
					
					compare_starty:
					
						mov ax, starty[bx]
						cmp mendy, ax
						jg compare_endy
						jmp next
						
						compare_endy:
						
							mov ax, endy[bx]
							cmp mendy, ax
							jl target_box
				
				next:
					
					inc di
				
			loop inner_loop
				
			pop cx
				
			inc si
			
		loop outer_loop
		
		mov withIndex, -1
		jmp return
		
		target_box:
		
			pop cx
			
			; ***************************
			; Saving number index to swap
			; ***************************
			
			mov ax, bx
			mov bx, 2
			div bx
			mov withIndex, ax
			
		return:
		
			pop dx
			pop cx
			pop bx
			pop ax
		
			ret
	
	boxToSwapWith endp
	
; ===================================================================================================================================================================

	; *************************************
	; To find box to swap after mouse input
	; *************************************
	
	boxToSwap proc
	
		push ax
		push bx
		push cx
		push dx
	
		mov cx, rows
		mov si, 0
		mov di, 0
			
		outer_loop:
			
			push cx
				
			mov cx, columns
			mov di, 0
				
			inner_loop:
				
				mov dx, 0		; Calculating 2D array index (current row * columns + current column)
				mov ax, si
				mov bx, columns
				mul bx
				add ax, di
				
				mov toSwapRow, si		; Saving indexes
				mov toSwapColumn, di
				
				mov bx, 2
				mul bx
				mov bx, ax
					
				mov ax, startx[bx]
				cmp mstartx, ax
				jg compare_endx
				jmp next
				
				compare_endx:
				
					mov ax, endx[bx]
					cmp mstartx, ax
					jl compare_starty
					jmp next
					
					compare_starty:
					
						mov ax, starty[bx]
						cmp mstarty, ax
						jg compare_endy
						jmp next
						
						compare_endy:
						
							mov ax, endy[bx]
							cmp mstarty, ax
							jl target_box
				
				next:
					
					inc di
				
			loop inner_loop
				
			pop cx
				
			inc si
			
		loop outer_loop
		
		mov toIndex, -1
		jmp return
		
		target_box:
		
			pop cx
			
			; ***************************
			; Saving number index to swap
			; ***************************
			
			mov ax, bx
			mov bx, 2
			div bx
			mov toIndex, ax
			
		return:
		
			pop dx
			pop cx
			pop bx
			pop ax
		
			ret
	
	boxToSwap endp

; ===================================================================================================================================================================

	; *****************
	; Draw level1 board
	; *****************
	
	drawBoard proc
	
		; *********************************
		; Displaying black grid array first
		; *********************************
		
		mov x, 10			; Drawing grid array as pixels on screen
		mov y, 5
		call displayGridArrayPixelBlack
		
		; **********************
		; Drawing colorful board
		; **********************
	
		mov x, 68			; Drawing board (Grid) on screen
		mov y, 72
		mov color, 01
		mov boxWidth, 39
		mov boxHeight, 32
		call drawGrid
		
		mov x, 10			; Drawing grid array as pixels on screen
		mov y, 5
		call displayGridArrayPixel
	
		ret
	
	drawBoard endp
	
; ===================================================================================================================================================================

	; ***********************************************
	; Procedure to save multidigit number in a string
	; ***********************************************

	saveNumberStr proc

		divide_push:

			mov dx, 0
			mov bx, 10
			div bx
			push dx
			inc count

			cmp ax,0

		ja divide_push
		
		save_to_string:

			pop dx
			add dl, 48
			
			mov [si], dl
			
			inc si
			dec count
			
			cmp count, 0

		ja save_to_string

		ret

	saveNumberStr endp
	
; ===================================================================================================================================================================
	
	; ***********************************
	; Procedure for asking player profile
	; ***********************************
	
	playerProfile proc
	
		call clearScreen
	
		mov x, 25
		mov y, 13
		mov si, offset profile_input
		mov color, 07
		call displayScreenStr
		
		mov color, 07		; Setting color for the border
		mov x, 150		; Setting x-coordinate for border
		mov y, 160		; Setting y-coordinate for border
		call drawMainBorder
		
		mov di, 0		; Taking profile name as input
		mov dl, 40		; Setting coordinates for input display
		mov dh, 13
		mov color, 07
		
		profileInput:
		
			mov ah, 07		; Taking anonymous characters input
			int 21h
			
			cmp al, 13		; If Enter is pressed
			je end_profileInput
			
			cmp count_profile, 12	; Maximum 12 characters are allowed
			je display_limit_msg
			
			mov profile[di], al		; Storing character in string
			
			mov ah, 02		; Sets the cursor position
			int 10h
			
			mov ah, 09		; Draw character on screen
			mov bh, 0
			mov bl, color
			mov al, profile[di]
			mov cx, 1
			int 10h
			
			inc dl			; Incrementing column for printing next character
			inc di			; Incrementing string index
			inc count_profile	; Incrementing count of characters
			
		jmp profileInput
		
		display_limit_msg:		; To display warning message if user enters more than 12 characters
		
			mov color, 07
			mov si, offset profile_limit
			mov x, 30
			mov y, 18
			call displayScreenStr
			
			jmp profileInput
			
		end_profileInput:
		
		ret
	
	playerProfile endp
	
; ===================================================================================================================================================================

	; ****************************************
	; Procedure to draw border of profile menu
	; ****************************************
	
	drawMainBorder proc
		
		push x			; Pushing x-coordinate for forth rectangle
		
		mov recHeight, 100	; Drawing first rectangle
		push recHeight		; Pushing height of first rectangle for forth rectangle
		
		mov recWidth, 15
		call drawRectangle
		
		mov ax, recWidth	; Drawing second rectangle
		add x, ax
		
		mov recHeight, 15
		mov recWidth, 300		
		call drawRectangle
		
		mov ax, recWidth	; Drawing third rectangle
		add x, ax
		
		mov recHeight, 115
		mov recWidth, 15	
		call drawRectangle
		
		pop ax			; Drawing forth rectangle
		add y, ax
		pop x			; Poping x-coordinate of first rectangle (Borders x-coordinate)
		
		mov recHeight, 15
		mov recWidth, 315
		call drawRectangle
		
		ret
		
	drawMainBorder endp
	
; ===================================================================================================================================================================
	
	; *************************************************************
	; To display grid array with random numbers as pixels on screen
	; *************************************************************
	
	displayGridArrayPixel proc
			
			mov cx, rows
			mov si, 0
			mov di, 0
			
			outer_loop:
			
				cmp cx, 0
				je end_outer_loop
			
				push cx
				push x
				
				mov cx, columns
				mov di, 0
				
				inner_loop:
				
					mov dx, 0		; Calculating 2D array index (current row * columns + current column)
					mov ax, si
					mov bx, columns
					mul bx
					add ax, di
					mov bx, ax
					
					push si
					mov ah, 0
					mov al, gridArray[bx]
					
					cmp al, '1'
					je colorOne
					
					cmp al, '2'
					je colorTwo
					
					cmp al, '3'
					je colorThree
					
					cmp al, '4'
					je colorFour
					
					cmp al, '5'
					je colorFive
					
					cmp al, 'B'
					je colorBee
					
					cmp al, 'X'
					je colorX
					
					mov color, 15
					jmp next
					
					colorOne:
					
						mov color, 5
						jmp next
						
					colorTwo:
					
						mov color, 3
						jmp next
						
					colorThree:
					
						mov color, 2
						jmp next
						
					colorFour:
					
						mov color, 7
						jmp next
					
					colorFive:
					
						mov color, 6
						jmp next
						
					colorBee:
					
						mov color, 8
						jmp next
						
					colorX:
					
						mov color, 10
						jmp next
					
					next:
					
						mov string[0], al
						mov si, offset string
						call displayScreenStr
						pop si
						
						add x, 5
						
						inc di
				
				loop inner_loop
				
				pop x
				pop cx
				
				inc si
				dec cx
				
				add y, 2
			
			jmp outer_loop
			
			end_outer_loop:
	
		ret
	
	displayGridArrayPixel endp
	
; ===================================================================================================================================================================
	
	; ***********************************************************************************************
	; To display grid array (Of black color used in updating) with random numbers as pixels on screen
	; ***********************************************************************************************
	
	displayGridArrayPixelBlack proc
			
			mov color, 0
			mov cx, rows
			mov si, 0
			mov di, 0
			
			outer_loop:
			
				push cx
				push x
				
				mov cx, columns
				mov di, 0
				
				inner_loop:
				
					mov dx, 0		; Calculating 2D array index (current row * columns + current column)
					mov ax, si
					mov bx, columns
					mul bx
					add ax, di
					mov bx, ax
					
					push si
					mov ah, 0
					mov al, gridArray[bx]
					mov string[0], al
					mov si, offset string
					call displayScreenStr
					pop si
					
					add x, 5
					
					inc di
				
				loop inner_loop
				
				pop x
				pop cx
				
				inc si
				
				add y, 2
			
			loop outer_loop
	
		ret
	
	displayGridArrayPixelBlack endp

; ===================================================================================================================================================================

	; *******************
	; Method to draw grid
	; *******************
	
	drawGrid proc
	
		push ax
		push bx
		push cx
		push dx
		
		mov cx, rows
		mov si, 0
		mov di, 0
		
		outerLoop:
		
			push cx
			push x
		
			mov cx, columns
			mov di, 0
			
			innerLoop:
			
				mov dx, 0			; Calculating 2D array index (current row * columns + current column)
				mov ax, si
				mov bx, columns
				mul bx
				add ax, di
				mov bx, 2
				mul bx
				mov bx, ax
			
				call drawBox			; Drawing box
				
				mov ax, x			; Saving starting and ending coordinates of current box
				mov startx[bx], ax
				mov ax, y
				mov starty[bx], ax
				mov ax, comx
				mov endx[bx], ax
				mov ax, comy
				mov endy[bx], ax
				
				mov ax, boxWidth		; Calculating new x-coordinate for next box
				add x, ax
				
				inc di
			
			loop innerLoop
		
			pop x	
			pop cx
			
			mov ax, boxHeight			; Calculating new y-coordinate for next box
			add y, ax
			
			inc si
		
		loop outerLoop
		
		
		pop dx
		pop cx
		pop bx
		pop ax
	
		ret
	
	drawGrid endp

; ===================================================================================================================================================================

	; ********************
	; Method to draw a box
	; ********************
	
	drawBox proc
	
		push si
		push di
		push ax
		push bx
		push cx
		push dx
	
		mov ax, x		; Calculating x-coordinate to compare with
		mov comx, ax
		mov ax, boxWidth
		add comx, ax

		mov ax, y		; Calculating y-coordinate to compare with
		mov comy, ax
		mov ax, boxHeight
		add comy, ax
		
		mov si, x		; Starting column
		mov di, y		; Starting row

		loop1:			; To print lines vertically

			cmp di, comy			; Comparing with (heigth + y-coordinate)
			je end_loop1

			mov ah, 0ch		; To make a pixel
			mov al, color		; Color of pixel
			mov cx, si 		; Column of pixel (x-coordinate)
			mov dx, di 		; Row of pixel (y-coordinate)
			int 10h

			inc di

		jmp loop1

		end_loop1:
		
		mov si, x		; Starting column
		mov di, y		; Starting row

		loop2:			; To print lines horizontally

			cmp si, comx		; Comparing with (width + x-coordinate)
			je end_loop2

			mov ah, 0ch		; To make a pixel
			mov al, color		; Color of pixel
			mov cx, si 		; Column of pixel (x-coordinate)
			mov dx, di 		; Row of pixel (y-coordinate)
			int 10h

			inc si

		jmp loop2

		end_loop2:
		
		mov si, x		; Starting column
		add si, boxWidth
		mov di, y		; Starting row

		loop3:			; To print lines vertically

			cmp di, comy			; Comparing with (heigth + y-coordinate)
			je end_loop3

			mov ah, 0ch		; To make a pixel
			mov al, color		; Color of pixel
			mov cx, si 		; Column of pixel (x-coordinate)
			mov dx, di 		; Row of pixel (y-coordinate)
			int 10h

			inc di

		jmp loop3

		end_loop3:
		
		mov si, x		; Starting column
		mov di, y		; Starting row
		add di, boxHeight

		loop4:			; To print lines horizontally

			cmp si, comx		; Comparing with (width + x-coordinate)
			je end_loop4

			mov ah, 0ch		; To make a pixel
			mov al, color		; Color of pixel
			mov cx, si 		; Column of pixel (x-coordinate)
			mov dx, di 		; Row of pixel (y-coordinate)
			int 10h

			inc si

		jmp loop4

		end_loop4:
		
		pop dx
		pop cx
		pop bx
		pop ax
		pop di
		pop si
	
		ret
	
	drawBox endp
	
; ===================================================================================================================================================================
	
	; ******************************************
	; To display grid array with random numbers
	; ******************************************
	
	displayGridArray proc
			
			mov cx, rows
			mov si, 0
			mov di, 0
			
			outer_loop:
			
				push cx
				
				mov cx, columns
				mov di, 0
				
				inner_loop:
				
					mov dx, 0		; Calculating 2D array index (current row * columns + current column)
					mov ax, si
					mov bx, columns
					mul bx
					add ax, di
					mov bx, ax
					
					mov dl, gridArray[bx]	; Displaying as a character
					mov ah, 02
					int 21h
					
					mov ah, 02	; Space in between characters
					mov dl, 32
					int 21h
					
					inc di
				
				loop inner_loop
				
				mov ah, 02	; Next line
				mov dl, 10
				int 21h
				
				mov ah, 02
				mov dl, 13
				int 21h
				
				pop cx
				
				inc si
			
			loop outer_loop
	
		ret
	
	displayGridArray endp
	
; ===================================================================================================================================================================
	
	; ******************************************
	; To populate grid array with random numbers
	; ******************************************
	
	populateGridArray proc
			
		mov cx, rows
		mov si, 0
		mov di, 0
			
		outer_loop:
			
			push cx
				
			mov cx, columns
			mov di, 0
				
			inner_loop:
				
				mov dx, 0		; Calculating 2D array index (current row * columns + current column)
				mov ax, si
				mov bx, columns
				mul bx
				add ax, di
				mov bx, ax
				
				call generateRandom	; Generating random number
				
				mov ax, level_delay
				mov time_delay, ax	; Adding delay for to get random number every time
				call delay	
				
				cmp randomNumber, '6'
				je make_bomb
				
				cmp randomNumber, '7'
				je makeX
				
				jmp not_bomb
				
				makeX:
				
					mov randomNumber, 'X'
					jmp not_bomb
				
				make_bomb:
				
					mov randomNumber, 'B'
					
				not_bomb:
				
				mov ah, 0
				mov al, randomNumber
				mov gridArray[bx], al	; Saving random number in matrix
				
				next:
					
				inc di
				
			loop inner_loop
				
			pop cx
				
			inc si
			
		loop outer_loop
	
		ret
	
	populateGridArray endp
	
; ===================================================================================================================================================================

	; *********************************
	; Procedure to clear current screen
	; *********************************

	clearScreen proc

		mov ah, 0	; To select screen mode
		mov al, 12h
		int 10h

		ret

	clearScreen endp

; ===================================================================================================================================================================

	; ****************************************************************************************************************
	; Procedure to print string characters on screen (Set x y coordinates, color, and provide offset of string in si)
	; ****************************************************************************************************************
	
	displayScreenStr proc
	
		push ax
		push bx
		push cx
		push dx
	
		mov dl, byte ptr x	; Setting column for string
		mov dh, byte ptr y	; Setting row for string
		
		printChar:
		
			mov al, '$'	; Comparing character with terminating character
			
			cmp [si], al
			je return
		
			mov ah, 02	; Sets the cursor position
			int 10h
			
			mov ah, 09	; Draw character on screen
			mov bh, 0
			mov bl, color
			mov al, [si]
			mov cx, 1
			int 10h
			
			inc si		; Incrementing string index
			inc dl		; Incrementing column for printing next character
			
		jmp printChar
		
		return:
		
			pop dx
			pop cx
			pop bx
			pop ax
	
			ret
	
	displayScreenStr endp
	
; ===================================================================================================================================================================

	; ********************************************************************************
	; Procedure to generate random number (Random number is in dl after function call)
	; ********************************************************************************

	generateRandom proc
	
		push ax
		push bx
		push cx
		push dx
	
		add time_delay, 70
		call delay
	
		mov ah, 0		; Intrrupt to get time
		int 1ah
		
		mov  ax, dx
		xor  dx, dx
		mov  cx, randomRange		; Range 1 - 5
		div  cx			; here dx contains the remainder of the division - from 0 to 4
		
		mov randomNumber, dl
		add randomNumber, '0'
		inc randomNumber
		
		pop dx
		pop cx
		pop bx
		pop ax
	
		ret
	
	generateRandom endp
	
; ===================================================================================================================================================================

	; ***********************
	; Procedure to make delay
	; ***********************
	
	delay proc


		push ax
		push bx
		push cx
		push dx

		mov cx,1000
		
		mydelay:
		
			mov bx, time_delay      ;; increase this number if you want to add more delay, and decrease this number if you want to reduce delay.
			
			mydelay1:
			
				dec bx
			
			jnz mydelay1
		
		loop mydelay


		pop dx
		pop cx
		pop bx
		pop ax

		ret

	delay endp
	
; ===================================================================================================================================================================

	; *****************************
	; Procedure to draw a rectangle
	; *****************************

	drawRectangle proc

		mov ax, x		; Calculating x-coordinate to compare with
		mov comx, ax
		mov ax, recWidth
		add comx, ax

		mov ax, y		; Calculating y-coordinate to compare with
		mov comy, ax
		mov ax, recHeight
		add comy, ax

		mov si, x		; Starting column
		mov di, y		; Starting row

		outer_loop:		; To print lines vertically

			cmp di, comy			; Comparing with (heigth + y-coordinate)
			je end_outer_loop

			mov si, x

			inner_loop:			; To print lines horizontally

				cmp si, comx		; Comparing with (width + x-coordinate)
				je end_inner_loop

				mov ah, 0ch		; To make a pixel
				mov al, color		; Color of pixel
				mov cx, si 		; Column of pixel (x-coordinate)
				mov dx, di 		; Row of pixel (y-coordinate)
				int 10h

				inc si

			jmp inner_loop

			end_inner_loop:

			inc di

		jmp outer_loop

		end_outer_loop:

		ret

	drawRectangle endp
	
; ===================================================================================================================================================================

	; **************************************
	; Procedure to display multidigit number
	; **************************************

	displayNumber proc
	
		push ax
		push bx
		push cx
		push dx
	
		mov count, 0

		divide_push:

			mov dx, 0
			mov bx, 10
			div bx
			push dx
			inc count

			cmp ax,0

		ja divide_push

		display:

			pop dx
			add dl, 48
			mov ah, 02
			int 21h
			dec count
			cmp count, 0

		ja display
		
		pop dx
		pop cx
		pop bx
		pop ax

		ret

	displayNumber endp
	
; ===================================================================================================================================================================

	; ***********************************
	; Procedure to Print level completed 
	; ***********************************
	
	Print_LvlComp proc
	
		push x
		push y
	
		mov x, 100
		mov y, 230
		
		mov color, 0010b	;C
		mov recWidth, 15
		mov recHeight, 85
		call drawRectangle
		
		add x,	10		;C
		mov color, 0010b
		mov recWidth, 35
		mov recHeight, 15
		call drawRectangle
		
		add y,70		;C
		mov color, 0010b
		mov recWidth, 35
		mov recHeight, 15
		call drawRectangle
		
		add x,45
		sub y,70
		mov color, 0010b	;O
		mov recWidth, 15
		mov recHeight, 85
		call drawRectangle
		
		add x,	10		;O
		mov color, 0010b
		mov recWidth, 35
		mov recHeight, 15
		call drawRectangle
		
		add y,70		;O
		mov color, 0010b
		mov recWidth, 35
		mov recHeight, 15
		call drawRectangle
		
		add x,25
		sub y,70
		mov color, 0010b	;O
		mov recWidth, 15
		mov recHeight, 85
		call drawRectangle
		
		add x,25		;M
		mov color, 0010b
		mov recWidth, 15
		mov recHeight, 85
		call drawRectangle
		
		
		add x,50		;M
		mov color, 0010b
		mov recWidth, 15
		mov recHeight, 85
		call drawRectangle
		
		
		sub x, 35	
		push y	
		mov cx, 15		
		
		print_M1_line:
		
			push cx
			
			mov ax, y
			mov comy, ax
			add comy, 18
			mov slope, 1
			
			call diagonalLine2
			
			inc y
			
			pop cx
		
		loop print_M1_line
		
		
		add x, 35
		pop y
		push y			
		mov cx, 15		
		
		print_M2_line:
		
			push cx
			
			mov ax, y
			mov comy, ax
			add comy, 18
			mov slope, 1
			
			call diagonalLine1
			
			inc y
			
			pop cx
		
		loop print_M2_line
		
		pop y
		
		add x,25		;P
		mov color, 0010b
		mov recWidth, 15
		mov recHeight, 85
		call drawRectangle
		
		add x,35		;P
		mov color, 0010b
		mov recWidth, 15
		mov recHeight, 35
		call drawRectangle
		
		sub x,35		;P
		mov color, 0010b
		mov recWidth, 35
		mov recHeight, 15
		call drawRectangle
			
		add y, 35		;P
		mov color, 0010b
		mov recWidth, 50
		mov recHeight, 15
		call drawRectangle
		
		add x,60		;L
		sub y, 35
		mov color, 0010b
		mov recWidth, 15
		mov recHeight, 85
		call drawRectangle
		
		add y, 70		;P
		mov color, 0010b
		mov recWidth,40 
		mov recHeight, 15
		call drawRectangle
		
		add x,50		;E
		sub y, 70
		mov color, 0010b
		mov recWidth, 15
		mov recHeight, 85
		call drawRectangle
		
		mov color, 0010b	;E
		mov recWidth,40 
		mov recHeight, 15
		call drawRectangle
		
		add y, 35		;E
		mov color, 0010b
		mov recWidth,40 
		mov recHeight, 15
		call drawRectangle
		
		add y, 35		;E
		mov color, 0010b
		mov recWidth,40 
		mov recHeight, 15
		call drawRectangle
		
		add x,50		;T
		sub y, 70
		mov color, 0010b
		mov recWidth,50
		mov recHeight, 15
		call drawRectangle
		
		add x,18		;T
		mov color, 0010b
		mov recWidth, 15
		mov recHeight, 85
		call drawRectangle
		
		add x,42		;E
		mov color, 0010b
		mov recWidth, 15
		mov recHeight, 85
		call drawRectangle
		
		mov color, 0010b	;E
		mov recWidth,40 
		mov recHeight, 15
		call drawRectangle
		
		add y, 35		;E
		mov color, 0010b
		mov recWidth,40 
		mov recHeight, 15
		call drawRectangle
		
		add y, 35		;E
		mov color, 0010b
		mov recWidth,40 
		mov recHeight, 15
		call drawRectangle
		
		sub x,355		;L
		sub y, 170
		mov color, 0011b
		mov recWidth, 15
		mov recHeight, 85
		call drawRectangle
		
		add y, 70		;L
		mov color, 0011b
		mov recWidth,55
		mov recHeight, 15
		call drawRectangle
		
		add x,70		;E
		sub y, 70
		mov color, 0011b
		mov recWidth, 15
		mov recHeight, 85
		call drawRectangle
		
		mov color, 0011b	;E
		mov recWidth,55
		mov recHeight, 15
		call drawRectangle
		
		add y, 35		;E
		mov color, 0011b
		mov recWidth,55
		mov recHeight, 15
		call drawRectangle
		
		add y, 35		;E
		mov color, 0011b
		mov recWidth,55
		mov recHeight, 15
		call drawRectangle
		
		add x,70		;V
		sub y, 70
		mov color, 0011b
		mov recWidth, 15
		mov recHeight, 60
		call drawRectangle
		
		add x,40		;V
		mov color, 0011b
		mov recWidth, 15
		mov recHeight, 60
		call drawRectangle
		
		
		sub x, 40
		add y,  50
		push y	
		mov cx, 20		
		
		print_Vletter1_line:
		
			push cx
			
			mov ax, y
			mov comy, ax
			add comy, 14
			mov slope, 2
			
			call diagonalLine2
			
			inc y
			
			pop cx
		
		loop print_Vletter1_line
		
		add x, 54		
		pop y
		push y			
		mov cx, 20		
		
		print_V2_line:
		
			push cx
			
			mov ax, y
			mov comy, ax
			add comy, 14
			mov slope, 2
			
			call diagonalLine1
			
			inc y
			
			pop cx
		
		loop print_V2_line
		
		pop y
		
		add x,16		;E
		sub y, 50
		mov color, 0011b
		mov recWidth, 15
		mov recHeight, 85
		call drawRectangle
		
		mov color, 0011b	;E
		mov recWidth,55
		mov recHeight, 15
		call drawRectangle
		
		add y, 35		;E
		mov color, 0011b
		mov recWidth,55
		mov recHeight, 15
		call drawRectangle
		
		add y, 35		;E
		mov color, 0011b
		mov recWidth,55
		mov recHeight, 15
		call drawRectangle
		
		add x,70		;L
		sub y, 70
		mov color, 0011b
		mov recWidth, 15
		mov recHeight, 85
		call drawRectangle
		
		add y, 70		;L
		mov color, 0011b
		mov recWidth,55
		mov recHeight, 15
		call drawRectangle
		
		pop y
		pop x
		
		ret
	Print_LvlComp endp
	
; ===================================================================================================================================================================

	; **********************************************************************************************************************
	; Procedure to print diagonal line on "x" and "y" coordinates to "comy" and of color "color" (High to low & to left) "/"
	; **********************************************************************************************************************

	diagonalLine1 proc

		mov si, x
		mov di, y

		loop1:

			cmp di, comy
			je return

			mov cx, slope

			loop2:

				mov temp_cx, cx

				mov ah, 0ch		; To make a pixel
				mov al, color		; Color of pixel
				mov cx, si 		; Column of pixel (x-coordinate)
				mov dx, di 		; Row of pixel (y-coordinate)
				int 10h

				dec si

				mov cx, temp_cx

			loop loop2

			inc di

		jmp loop1

		return:

			ret

	diagonalLine1 endp

; ===================================================================================================================================================================

	; ***********************************************************************************************************************
	; Procedure to print diagonal line on "x" and "y" coordinates to "comy" and of color "color" (High to low & to right) "\"
	; ***********************************************************************************************************************

	diagonalLine2 proc

		mov si, x
		mov di, y

		loop1:

			cmp di, comy
			je return

			mov cx, slope

			loop2:

				mov temp_cx, cx

				mov ah, 0ch		; To make a pixel
				mov al, color		; Color of pixel
				mov cx, si 		; Column of pixel (x-coordinate)
				mov dx, di 		; Row of pixel (y-coordinate)
				int 10h

				inc si

				mov cx, temp_cx

			loop loop2

			inc di

		jmp loop1

		return:

			ret

	diagonalLine2 endp

end
