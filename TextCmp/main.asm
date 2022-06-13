.386	
.model flat, stdcall
option	casemap:none

include		windows.inc
include		user32.inc
include		kernel32.inc
include		msvcrt.inc
includelib	user32.lib
includelib	kernel32.lib
includelib  msvcrt.lib

sprintf PROTO C :ptr sbyte, :ptr sbyte, :VARARG



.const
szClassName		db		'MyTextCmpClass',0
szCaptionMain	db		'Text Aligner',0
szButtonClass   db      'button',0
szEditClass		db		'edit',0
szButtonText	db		'Compare',0
szMsgBoxCap		db		'Result',0
szFmt			db		'Diff Line:%d',0AH,0
szMsgNoDiff		db		'The contents of input files are duplicated',0

idEdit1			equ		1
idEdit2			equ		2
idButton		equ		3



.data
szBuffer		db		1024	 dup(?)		;���ڴ�ӡ������
szBufLine1		db		1024	 dup(?)		;�洢�ļ�1����ĵ�ǰ��
szBufLine2		db		1024	 dup(?)		;�洢�ļ�2����ĵ�ǰ��
szFile1			db		MAX_PATH dup(?)		;�ļ�1·��
szFile2			db		MAX_PATH dup(?)		;�ļ�2·��
nDiff			dd		?					;��ͬ�еĸ���

hInstance		HWND	?
hWinMain		HWND	?
hEdit1			HWND	?
hEdit2			HWND	?
hButton			HWND	?
hFile1			HWND	?
hFile2			HWND	?


.code


_ReadLine		proc	uses ebx, _hFile:HANDLE, _lpBuffer:ptr byte	;lpBuffer����Ŷ���һ�е�ָ��
				local	@dwBytesRead:dword		;����ÿ�ε���readfile����������ַ���
				local	@ch:byte				;����ÿ�ζ�����ַ�
				mov		ebx,_lpBuffer			
				.while	TRUE
					;ÿ�ζ���һ���ַ�
					invoke ReadFile,_hFile,addr @ch,1,addr @dwBytesRead,NULL
					;�����ջ��߻��з���������һ�еĶ���
					.break .if @dwBytesRead == 0
					.break .if @ch == 10		
					;���ַ�����ebx��ָ���ڴ�����
					mov al,@ch
					mov [ebx],al
					inc	ebx
				.endw

				;Ϊ�����һ�����0��β
				mov al,0
				mov [ebx],al
				;�����г��ȱ�����eax��
				invoke lstrlen,_lpBuffer
				ret
_ReadLine		endp

_Compare		proc
				local @nLineSize1:dword
				local @nLineSize2:dword	
				local @line:dword
				local @pdiff[1000]:byte

				invoke CreateFile, offset szFile1,GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
				mov	hFile1,eax
				invoke CreateFile, offset szFile2,GENERIC_READ, FILE_SHARE_READ, NULL, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, NULL
				mov hFile2,eax
			
				mov @line,0
				mov nDiff,0

readline:		inc @line
				invoke  RtlZeroMemory,offset szBufLine1,sizeof szBufLine1
				invoke	_ReadLine	,hFile1,offset szBufLine1
				mov @nLineSize1,eax
				invoke  RtlZeroMemory,offset szBufLine2,sizeof szBufLine2
				invoke	_ReadLine	,hFile2,offset szBufLine2
				mov @nLineSize2,eax


cmp1:			cmp @nLineSize1,0
				jne cmp2			;��1���Ȳ�Ϊ0�ٿ��ж��Ƿ�Ϊ0
				cmp @nLineSize2,0
				je	Finish			;���ļ�1��2����ĵ�ǰ�г��ȶ�Ϊ0��˵���ļ��Ѷ��꣬ת��ӡ����
				;��ʱnline1Ϊ0��nline2��Ϊ0��ת�кż�¼


WriteBuffer:	invoke sprintf,addr @pdiff,offset szFmt,@line	;����һ����ʾ��Ϣ
				invoke lstrcat,offset szBuffer,addr @pdiff		;������ʾ��Ϣ���ӵ�ȫ�ִ�ӡ������
				inc	nDiff
				jmp	readline


cmp2:			;��ʱnline1 > 0 ��nline2δ֪
				cmp @nLineSize2,0
				je	WriteBuffer		;��ʱnline1 >0 ,nline2 ==0 ��ת�кż�¼
				;��ʱ���г��ȶ���Ϊ0
				invoke lstrcmp,offset szBufLine1,offset szBufLine2
				cmp eax,0
				je	readline		;��ͬ��������
				jmp	WriteBuffer		;����ת�кż�¼����


Finish:			invoke CloseHandle,hFile1
				invoke CloseHandle,hFile2
				ret
_Compare		endp

_ProcWinMain	proc	uses ebx edi esi,handle:HWND,uMsg:UINT,wParam:WPARAM,lParam:LPARAM


				; ������Ϣ�����ͷַ�����ͬ�ķ�֧
				mov		eax,uMsg
				.if	uMsg == WM_CLOSE
				;�رմ���
					invoke DestroyWindow,hWinMain
					invoke PostQuitMessage, NULL

				.elseif uMsg == WM_CREATE
				
				;���ڳ�ʼ��֮�����ɿؼ�
				    ;����������
                    invoke CreateWindowEx,WS_EX_CLIENTEDGE, offset szEditClass, NULL, \
                      WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or ES_AUTOHSCROLL, \
                      90, 30, 300, 30, handle, idEdit1, hInstance, NULL
                    mov hEdit1, eax
                    invoke SetFocus, hEdit1

					invoke CreateWindowEx,WS_EX_CLIENTEDGE, offset szEditClass, NULL, \
                      WS_CHILD or WS_VISIBLE or WS_BORDER or ES_LEFT or ES_AUTOHSCROLL, \
                      90, 90, 300, 30, handle, idEdit2, hInstance, NULL
                    mov hEdit2, eax
                    ;���ð�ť
                    invoke CreateWindowEx, NULL, OFFSET szButtonClass, ADDR szButtonText, \
                      WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON, \
                      200, 210, 80, 30, handle, idButton, hInstance, NULL
                    mov hButton, eax  ;��ʱeax�д���Ǵ�����ť�ľ��
                    
				.elseif uMsg == WM_COMMAND
				;�����¼��ķַ�����
					.if wParam == idButton
						;��ȡ�ļ���
						invoke	GetDlgItemText,handle,idEdit1,offset szFile1,sizeof szFile1
						invoke	GetDlgItemText,handle,idEdit2,offset szFile2,sizeof	szFile2
                        ;invoke	SetDlgItemText,handle,idEdit2,offset szFile1
						invoke _Compare	;�ȶ������ı�������Ҫ��ӡ�����ݱ�����szBuffer��
						.if nDiff == 0
							invoke MessageBox, NULL, offset szMsgNoDiff,offset szMsgBoxCap,MB_OK
						.else
							invoke MessageBox, NULL, offset szBuffer,offset szMsgBoxCap,MB_OK
						.endif
						
					.endif	
				.else
				;�����¼�
					invoke DefWindowProc, handle,uMsg,wParam,lParam
					ret
				.endif
				xor eax,eax	
				ret
_ProcWinMain	endp

_WinMain		proc
				local	@stWndClass:WNDCLASSEX
				local	@stMsg:MSG

				invoke	GetModuleHandle,NULL
				mov		hInstance,eax
				invoke	RtlZeroMemory,addr @stWndClass, sizeof @stWndClass

				;ע�ᴰ����
				invoke	LoadCursor,0,IDC_ARROW
				mov		@stWndClass.hCursor,eax
				push	hInstance
				pop		@stWndClass.hInstance
				mov		@stWndClass.cbSize, sizeof WNDCLASSEX
				mov		@stWndClass.style,CS_HREDRAW or CS_VREDRAW
				mov		@stWndClass.lpfnWndProc,offset _ProcWinMain
				mov		@stWndClass.hbrBackground,COLOR_BTNFACE+1
				mov		@stWndClass.lpszClassName,offset szClassName
				invoke	RegisterClassEx, addr @stWndClass

				;��������ʾ����
				invoke	CreateWindowEx,WS_EX_CLIENTEDGE,\
						offset szClassName, offset szCaptionMain,\
						WS_OVERLAPPEDWINDOW,\
						CW_USEDEFAULT,CW_USEDEFAULT,\
						480,320,\
						NULL,NULL,hInstance,NULL
				mov		hWinMain,eax
				invoke	ShowWindow,hWinMain,SW_SHOWNORMAL
				invoke	UpdateWindow,hWinMain

				;��Ϣѭ��
				.while TRUE
					invoke	GetMessage,addr @stMsg,NULL,0,0
					.break	.if eax == 0
					invoke	TranslateMessage, addr @stMsg
					invoke	DispatchMessage, addr @stMsg
				.endw
				ret

_WinMain		endp

start:
				
				call	_WinMain	
				invoke	ExitProcess,NULL

end start

