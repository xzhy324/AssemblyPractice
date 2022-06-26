TITLE Program Snake

.386
.model flat, stdcall
option casemap:none

includelib msvcrt.lib
includelib user32.lib

ExitProcess proto, :dword
Sleep proto, :dword
GetStdHandle proto, :dword
SetConsoleCursorPosition proto :dword, :dword
SetConsoleTextAttribute proto :dword, :word
GetAsyncKeyState proto, :dword
CreateThread proto, :dword, :dword, :dword, :dword, :dword, :dword

system proto C, :ptr sbyte, :vararg
printf proto C :ptr sbyte, :vararg
scanf proto C :ptr sbyte, :vararg
memset proto C :ptr sbyte, :dword, :dword
time proto C :dword
srand proto C :dword
rand proto C :dword

;	##################################################################################

.data

; ���� 625 ���ֽڵ����������õ�ͼ
globalMapArr byte 625 dup(?)

; ����ṹ�����洢��
snakePos STRUCT
	x dword ?
	y dword ?
snakePos ENDS

globalSnakeArr snakePos 100 dup(<0, 0>)

; �ߵĳ���
globalSnakeLen dword ?

; �洢��ʼ��ͷ��λ��
globalInitialSnakeHeadX dword ?
globalInitialSnakeHeadY dword ?

; �ߵ��ƶ�����
globalMovementDirection dword ?

; �洢ʳ���λ��
globalFoodX dword ?
globalFoodY dword ?

snakeBody byte "O", 0

;	showMainMenu()
;	��Ҫ��ӡ�ķָ��ߡ�������Ϣ������ָ��
dividingLine byte "-------------------------------------------------------------------", 0ah, 0
operationGuide byte "�� 1 ��ʼ��Ϸ", 0ah, "�� 2 ������Ϸ", 0ah, "�� W �����ƶ�",  0ah, "�� S �����ƶ�", 0ah, "�� A �����ƶ�", 0ah, "�� D �����ƶ�", 0ah, 0
szLogo byte	" ____  _      ____  _  __ _____",0ah,\
            "/ ___\\/ \\  /|/  _ \\/ |/ //  __/",0ah,\
            "|    \\| |\\ ||| / \\||   / |  \\  ",0ah,\
            "\\___ || | \\||| |-|||   \\ |  /_ ",0ah,\
            "\\____/\\_/  \\|\\_/ \\|\\_|\\_\\\\____\\",0ah,0

;	setWall()
;	ѭ������ǽ��ʱ���õı���
i dword ?
j dword ?
wall byte "#", 0
nullCh byte " ", 0
food byte "*", 0
changeLine byte 0ah, 0

;	handleIllegalSelection()
;	����Ƿ��������ʾ��Ϣ
errMsg byte "����ı�Ų���ȷ������ 2s ֮����������", 0ah, 0

;	enterGame()
;	scanf ��ȡ�û�����ʱ��Ҫ�Ĳ��� %d
paramater byte "%d", 0
selection dword ?

;	 judgeDetection()
;	�����ݴ���ͷ����� x, y
 x dword ?
 y dword ?


 ;	die()
 ;	�������ʱ����ʾ��Ϣ
 dieTip byte "������, ��Ϸ����", 0ah, 0

;	endGame()
;	�˳���Ϸ����ʾ��Ϣ
endGameTip byte "������������֮�󼴽��˳�......", 0ah, 0


;	clearScreenUtil()
;	system ������Ļ��Ҫ�õ��Ĳ��� cls
clearScreen byte "cls", 0

;	##################################################################################
.code

;	----------------------------------------------------------------------------------------------------------------------------------------
enterGame proc
enter_game:
	call showMainMenu
	
	; ��ȡ�û�ѡ��
	lea eax, dword ptr ds:[selection]
	push eax
	mov ecx, dword ptr offset paramater
	push ecx
	call scanf
	add esp, 8

	; �ж��û���ѡ��
	mov eax, dword ptr ds:[selection]
	cmp eax, 1
	je start_game
	cmp eax, 2
	je end_game

	; ����Ƿ�����
	call handleIllegalSelection
	jmp enter_game

start_game:
	call startGame
end_game:
	call endGame
	ret
enterGame endp

;	----------------------------------------------------------------------------------------------------------------------------------------
startGame proc
	call initMapData
	call setWall
	call setFoodPosition
    call setSnakePosition

go_on_game:
	call drawMap
	call drawSnake
	call moveSnake
	call judgeDetection

	push 250
	call Sleep
	jmp go_on_game
	ret
startGame endp

;	----------------------------------------------------------------------------------------------------------------------------------------
showMainMenu proc
	; ��ӡ�ָ��ַ�
	invoke printf, dword ptr offset dividingLine
	; ��ӡ��ʾ��Ϣ
	invoke printf, dword ptr offset operationGuide
	invoke printf, dword ptr offset szLogo
	; ��ӡ�ָ��ַ�
	invoke printf, dword ptr offset dividingLine

	ret
showMainMenu endp


;	----------------------------------------------------------------------------------------------------------------------------------------
initMapData proc
	push 625
	push 0
	lea eax, dword ptr offset[globalMapArr]
	push eax
	call memset
	add esp, 12
	ret
initMapData endp


;	----------------------------------------------------------------------------------------------------------------------------------------
setWall proc
	mov dword ptr ds:[i], 0
	mov ecx, 25
set_wall:
	; ��ǽ
	lea eax, dword ptr ds:[globalMapArr]
	mov ebx, dword ptr ds:[i]
	mov byte ptr ds:[eax + ebx], 0bh
	; ��ǽ
	lea eax, dword ptr ds:[globalMapArr]
	mov ebx, 24
	imul ebx, ebx, 25
	add eax, ebx
	mov ebx, dword ptr ds:[i]
	mov byte ptr ds : [eax + ebx] , 0bh
	; ��ǽ
	lea eax, dword ptr ds:[globalMapArr]
	mov ebx, dword ptr ds:[i]
	imul ebx, ebx, 25
	mov byte ptr ds : [eax + ebx] , 0bh
	; ��ǽ
	lea eax, dword ptr ds:[globalMapArr]
	mov ebx, dword ptr ds:[i]
	imul ebx, ebx, 25
	add ebx, 24
	mov byte ptr ds : [eax + ebx] , 0bh
	; i �Լ�
	mov ebx, dword ptr ds:[i]
	inc ebx
	mov dword ptr  ds:[i] , ebx
	loop set_wall
	ret
setWall endp



;	----------------------------------------------------------------------------------------------------------------------------------------
setFoodPosition proc
set_food_pos:
	call generateRandomFood

	; �ж�ʳ���ǲ��Ǻ�ǽ���ص�
	lea eax, dword ptr ds : [globalMapArr]
	mov ecx, dword ptr ds : [globalFoodX]
	imul ecx, ecx, 25
	add eax, ecx
	mov edx, dword ptr ds : [globalFoodY]
	add eax, edx

	mov cl, byte ptr ds : [eax]
	cmp cl, 0bh

	; �����ǽ�ص�, ��ص���ʼλ��, �������������
	je set_food_pos
	; ���û��ǽ, ������ʳ��
	mov byte ptr ds : [eax] , 0ch

	ret
setFoodPosition endp



;	----------------------------------------------------------------------------------------------------------------------------------------
generateRandomFood proc
	; ��ȡʱ��
	push 0
	call time
	add esp, 4
	; �������������
	push eax
	call srand
	add esp, 4
	; ��ȡ x ����ֵ
	call rand
	cdq
	mov ecx, 25
	idiv ecx
	mov dword ptr ds : [globalFoodX] , edx
	; ��ȡ y ����ֵ
	call rand
	cdq
	mov ecx, 25
	idiv ecx
	mov dword ptr ds : [globalFoodY] , edx

	ret
generateRandomFood endp



;	----------------------------------------------------------------------------------------------------------------------------------------
setSnakePosition proc
set_snake_pos:
	call generateRandomSnakeHead

	lea eax, dword ptr ds : [globalMapArr]
	mov ecx, dword ptr ds : [globalInitialSnakeHeadX]
	imul ecx, ecx, 25
	add eax, ecx
	mov edx, dword ptr ds : [globalInitialSnakeHeadY]
	add eax, edx
		
	mov cl, byte ptr ds : [eax]
	cmp cl, 0bh
	;	�����ǽ�ص�, ��ص���ʼλ��, ����������ͷ
	je set_snake_pos

	;	���ɵ���ͷ����Ҫ��, ��д���ߵĽṹ��
	lea eax, dword ptr ds : [globalSnakeArr]
	mov ecx, dword ptr ds : [globalSnakeLen]
	imul ecx, ecx, 8
	add eax, ecx

	;	�� ��ͷ�� x ����д��ṹ��
	mov ecx, dword ptr ds : [globalInitialSnakeHeadX] 
	mov dword ptr ds : [eax], ecx
		
	;	����ͷ�� y ����д��ṹ��
	mov ecx, dword ptr ds : [globalInitialSnakeHeadY] 
	mov dword ptr ds : [eax + 4], ecx

	;	�����ߵĳ���Ϊ 1
	mov dword ptr ds : [globalSnakeLen] , 1

	ret
setSnakePosition endp



;	----------------------------------------------------------------------------------------------------------------------------------------
generateRandomSnakeHead proc
	;	ȡ��ǰʱ��
	push 0
	call time
	add esp, 4
	;	�������������
	;	Ϊ�˱����ʳ���λ���ص��������������һ���̶�ֵ
	add eax, 23
	push eax
	call srand
	add esp, 4
	;	ȡ x �����������
	call rand
	cdq
	mov ecx, 25
	idiv ecx
	mov dword ptr ds : [globalInitialSnakeHeadX] , edx
	;	ȡ y �����������
	call rand
	cdq
	mov ecx, 25
	idiv ecx
	mov dword ptr ds : [globalInitialSnakeHeadY] , edx

	ret
generateRandomSnakeHead endp




;	----------------------------------------------------------------------------------------------------------------------------------------
handleIllegalSelection proc
	; ��ӡ������Ϣ
	invoke printf, dword ptr offset errMsg
	
	; ��ʱ����
	push 2000
	call dword ptr offset Sleep
	call clearScreenUtil
	ret
handleIllegalSelection endp


;	----------------------------------------------------------------------------------------------------------------------------------------
drawMap proc
	call clearScreenUtil

	mov dword ptr ds:[i], 0
	jmp first_cmp
	; ��һ��ѭ����ʼ
first_inc:
	mov eax, dword ptr ds:[i]
	inc eax
	mov dword ptr ds:[i], eax
first_cmp:	
	mov eax, dword ptr ds:[i]
	cmp eax, 25
	jge first_end

	; �ڶ���ѭ����ʼ
	mov dword ptr ds:[j], 0
	jmp second_cmp

second_inc:						
	mov eax, dword ptr ds:[j]
	inc eax
	mov dword ptr ds:[j], eax

second_cmp:					
	mov eax, dword ptr ds:[j]
	cmp eax, 25
	jge second_end

	;	---------------------------------------------------
	lea eax, dword ptr ds:[globalMapArr]
	mov ecx, dword ptr ds:[i]
	imul ecx, ecx, 25
	add eax, ecx
	mov ecx, dword ptr ds:[j]
	add eax, ecx

	mov al, byte ptr ds:[eax]
	cmp al, 0bh
	je draw_wall
	cmp al, 0ch
	je draw_food

	; ��ӡ�ո�
	invoke printf, dword ptr offset nullCh
	jmp second_inc

	; ��ӡǽ��
draw_wall:
	push -11
	call GetStdHandle
	push 0ffh
	push eax
	call SetConsoleTextAttribute
	invoke printf, dword ptr offset wall
	push -11
	call GetStdHandle
	push 7
	push eax
	call SetConsoleTextAttribute
	jmp second_inc

	; ��ӡʳ��
draw_food:
	push -11
	call GetStdHandle
	push 0cch
	push eax
	call SetConsoleTextAttribute
	invoke printf, dword ptr offset food
	push -11
	call GetStdHandle
	push 7
	push eax
	call SetConsoleTextAttribute
	jmp second_inc
	;	---------------------------------------------------

second_end:
	mov eax, dword ptr offset changeLine
	push eax
	call printf
	add esp, 4
	jmp first_inc

first_end:
	nop
	
	ret
drawMap endp




;	----------------------------------------------------------------------------------------------------------------------------------------
drawSnake proc
	push -11
	call GetStdHandle
	push 0eeh
	push eax
	call SetConsoleTextAttribute

    mov dword ptr ds:[i], 0
	jmp print_snake_cmp

print_snake_inc:
	mov eax, dword ptr ds:[i]
	inc eax
	mov dword ptr ds:[i], eax
print_snake_cmp:
	mov eax, dword ptr ds:[i]
	mov ecx, dword ptr ds:[globalSnakeLen]
	; ������õĳ��ȵ��ڴ����̰���ߵĳ���, ��ͼ����
	cmp eax, ecx	
	jge print_snake_end

	; ִ�д���
	lea eax, dword ptr ds:[globalSnakeArr]
	mov ecx, dword ptr ds:[i]
	imul ecx, ecx, 8
	add eax, ecx

	; �õ��ߵ�����, ƴ�Ӻ���� gotoxy
	mov ecx, dword ptr ds:[eax]							; ȡ�� x
	shl ecx, 16													; ���� 16 λ
	mov edx, dword ptr ds:[eax + 4]					; ȡ�� y
	or ecx, edx													; ƴ�����
	push ecx														; ���ù��λ��
	call gotoxyUtil
	add esp, 4

	; ��ӡ�ߵ�����
	push -11
	call GetStdHandle
	push 99h
	push eax
	call SetConsoleTextAttribute
	invoke printf, dword ptr offset snakeBody
	jmp print_snake_inc

print_snake_end:
	nop
	push -11
	call GetStdHandle
	push 7
	push eax
	call SetConsoleTextAttribute
	ret

	
drawSnake endp




;	----------------------------------------------------------------------------------------------------------------------------------------
moveSnake proc
	;	��ѭ��������ֵ
	mov eax, dword ptr ds : [globalSnakeLen]
	sub eax, 2
	mov dword ptr ds : [i] , eax
	jmp snake_cmp

snake_dec:
	mov eax, dword ptr ds : [i]
	dec eax
	mov dword ptr ds : [i] , eax

snake_cmp:
	mov eax, dword ptr ds : [i]
	cmp eax, 0
	jl snake_end

	lea eax, dword ptr ds : [globalSnakeArr]
	mov ecx, dword ptr ds : [i]
	imul ecx, ecx, 8
	add eax, ecx
	mov ecx, dword ptr ds : [eax]
	mov edx, dword ptr ds : [eax + 4]

	;	�ŵ� i + 1 ���±���
	add eax, 8
	mov dword ptr ds : [eax] , ecx
	mov dword ptr ds : [eax + 4] , edx
	jmp snake_dec

snake_end:

	;	ȷ����ͷλ��
	mov eax, dword ptr ds : [globalMovementDirection]
	cmp eax, 1
	je move_up
	cmp eax, 2
	je move_down
	cmp eax, 3
	je move_left
	cmp eax, 4
	je move_right

	;	�����ƶ�
move_up:
	lea eax, dword ptr ds : [globalSnakeArr]
	mov ecx, dword ptr ds : [eax]
	mov edx, dword ptr ds : [eax + 4]
	dec ecx
	mov dword ptr ds : [eax] , ecx
	mov dword ptr ds : [eax + 4] , edx
	jmp 	fun_end
	;	�����ƶ�
move_down:
	lea eax, dword ptr ds : [globalSnakeArr]
	mov ecx, dword ptr ds : [eax]
	mov edx, dword ptr ds : [eax + 4]
	inc ecx
	mov dword ptr ds : [eax] , ecx
	mov dword ptr ds : [eax + 4] , edx
	jmp 	fun_end
	;	�����ƶ�
move_left:
	lea eax, dword ptr ds : [globalSnakeArr]
	mov ecx, dword ptr ds : [eax]
	mov edx, dword ptr ds : [eax + 4]
	dec edx
	mov dword ptr ds : [eax] , ecx
	mov dword ptr ds : [eax + 4] , edx
	jmp 	fun_end
	;	�����ƶ�
move_right:
	lea eax, dword ptr ds : [globalSnakeArr]
	mov ecx, dword ptr ds : [eax]
	mov edx, dword ptr ds : [eax + 4]
	inc edx
	mov dword ptr ds : [eax] , ecx
	mov dword ptr ds : [eax + 4] , edx
	jmp 	fun_end

fun_end:
	nop

	ret
moveSnake endp





;	----------------------------------------------------------------------------------------------------------------------------------------
 judgeMovementDirection proc
 back_while:
	;	��ȡ w ��
	push 87
	call GetAsyncKeyState
	and ax, 0ff00h				
	cmp ax, 0
	jne w_press

	;	��ȡ s ��
	push 83
	call GetAsyncKeyState
	and ax, 0ff00h
	cmp ax, 0
	jne s_press

	;	��ȡ a ��
	push 65
	call GetAsyncKeyState
	and ax, 0ff00h
	cmp ax, 0
	jne a_press

	;	 d ��
	push 68
	call GetAsyncKeyState
	and ax, 0ff00h
	cmp ax, 0
	jne d_press
	jmp back_while

	;	��� w ��������
w_press:
	mov eax, dword ptr ds : [globalMovementDirection]
	cmp eax, 2
	je w_back
	mov dword ptr ds : [globalMovementDirection] , 1
w_back:
	jmp back_while

	;	��� s ��������
s_press:
	mov eax, dword ptr ds : [globalMovementDirection]
	cmp eax, 1
	je s_back
	mov dword ptr ds : [globalMovementDirection] , 2
s_back:
	jmp back_while

	;	��� a ��������
a_press:
	mov eax, dword ptr ds : [globalMovementDirection]
	cmp eax, 4
	je a_back
	mov dword ptr ds : [globalMovementDirection] , 3
a_back:
	jmp back_while

	;	��� d ��������
d_press:
	mov eax, dword ptr ds : [globalMovementDirection]
	cmp eax, 3
	je d_back
	mov dword ptr ds : [globalMovementDirection] , 4
d_back:
	jmp back_while

	ret
 judgeMovementDirection endp



 ;	----------------------------------------------------------------------------------------------------------------------------------------
 judgeDetection proc
	;	ȡ����ͷ�� xy ����
	lea eax, dword ptr ds : [globalSnakeArr]
	mov ecx, dword ptr ds : [eax]
	mov edx, dword ptr ds : [eax + 4]
	mov dword ptr ds : [x] , ecx
	mov dword ptr ds : [y] , edx

	;	ȡ����ͷ������
	lea eax, dword ptr ds : [globalMapArr]
	imul ecx, ecx, 25
	add eax, ecx
	add eax, edx
	mov cl, byte ptr ds : [eax]

	;	�ж��Ƿ�ײǽ
	cmp cl, 0bh
	je snake_dead


	;	�ж��Ƿ�Ե�ʳ��
	cmp cl, 0ch
	je snake_add_len

	;	ɶ��û��
	jmp fun_end

snake_dead:
	call die

snake_add_len:
	call addSnakeLen
	call initMapData
	call setWall
	call setFoodPosition

fun_end:
	nop

	ret
 judgeDetection endp



 ;	----------------------------------------------------------------------------------------------------------------------------------------
 addSnakeLen proc
	mov eax, dword ptr ds : [globalSnakeLen]
	inc eax
	mov dword ptr ds : [globalSnakeLen] , eax

	ret
 addSnakeLen endp

 ;	----------------------------------------------------------------------------------------------------------------------------------------
 die proc
	call clearScreenUtil

	invoke printf, dword ptr offset dieTip

	call endGame

	ret
 die endp


 ;	----------------------------------------------------------------------------------------------------------------------------------------
endGame proc
	; ��ӡ��ʾ��Ϣ
	invoke printf, dword ptr offset endGameTip

	; ��ʱ 2s
	push 2000
	call Sleep

	; �˳�
	push 0
	call ExitProcess
	ret
endGame endp


;	----------------------------------------------------------------------------------------------------------------------------------------
clearScreenUtil proc
	mov eax, dword ptr offset clearScreen
	push eax
	call system
	add esp, 4
	ret
clearScreenUtil endp



;	----------------------------------------------------------------------------------------------------------------------------------------
gotoxyUtil proc C pos:dword
	mov eax, dword ptr ds : [pos]
	push eax

	push -11
	call GetStdHandle
	push eax

	call SetConsoleCursorPosition
	ret
gotoxyUtil endp




;	----------------------------------------------------------------------------------------------------------------------------------------

;	##################################################################################
main proc

	;	���ٵ�һ���߳�
	push 0
	push 0
	push 0
	lea eax, dword ptr ds : [judgeMovementDirection]
	push eax
	push 0
	push 0
	call CreateThread

	;	�ڶ����߳� (���߳�)
	call enterGame
main endp
end main