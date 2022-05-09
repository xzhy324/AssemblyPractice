.486
.model flat, stdcall
.stack 4096
option casemap:none

includelib  msvcrt.lib
include		msvcrt.inc

printf	proto C, :ptr sbyte,:vararg
scanf	proto C, :dword,	:vararg

ExitProcess PROTO, dwExitCode:dword


.data
	szOutFmt	byte	'%d',0
	szInFmt		byte	'%s',0
	szMsg		byte	'Testing!',0ah,0	;0ah�����з�
		
	x			dd	128 dup(?)
	y			dd	128 dup(?)
	tmpinput	db	128 dup(?)	;�ֽ����鹩���룬��Ҫ��չ
	ans			dd	256 dup(0)
	xlen		dd	?
	ylen		dd	?
	pr			dd	?
	numBase		dd	10


.code

char2int		proc	stdcall	s:ptr byte,\
								numptr:ptr dword,\
								slen:dword
				push edi
				push esi
				push ecx
				push eax
				mov esi,s
				mov edi,numptr
				mov ecx,slen
convertLoop:
				movzx eax, byte ptr[esi]
				sub eax,'0'
				mov [edi], eax
				add edi,4
				add esi,1
				loop convertLoop

				pop eax
				pop ecx
				pop esi
				pop edi

				ret
char2int		endp

invertNum		proc stdcall a:ptr dword, alen:dword
				push ecx
				push ebx
				push eax
				push esi
				
				mov esi,a		;�����׵�ַ

				mov eax,0
				mov ebx,alen
				sub ebx,1		;��ʼ����Ҫά���ĶԳ��±�

				mov ecx,alen
				shr ecx,1
				add ecx,1		;����ѭ������
				
invertLoop:
				push dword ptr[esi+eax*4]	
				push dword ptr[esi+ebx*4]
				pop  dword ptr[esi+eax*4]
				pop  dword ptr[esi+ebx*4]			;���ö�ջ����
				add eax,1
				sub ebx,1
				loop invertLoop


				pop esi
				pop eax
				pop ebx
				pop ecx
				ret
invertNum		endp
				

mulAndAdd		proc stdcall num1:ptr dword,\
							 num2:ptr dword,\
							 result:ptr dword
				local i,j:dword

				push eax
				push ebx
				push ecx
				push edx
				mov i,0
outerLoop:
				mov j,0
innerLoop:
				mov ebx,i
				add ebx,j						
				shl ebx,2					;��4��Ϊ����ȷ�ļ��
				add ebx,result				;��ʱebx�д����ans[i+j]��ƫ����

				mov ecx,i
				shl ecx,2
				add ecx,num1				;ȡ��x[i]��ƫ�ƣ������ڴ������Ѱַ��ðѸ���ƫ���������ڼĴ�������ʹ�ñ���Ѱַ
				mov eax,[ecx]
				
				mov ecx,j
				shl ecx,2
				add ecx,num2				;ȡ��y[j]��ƫ��
				
				mul dword ptr[ecx]			;����x[i]*y[j]
				
				add [ebx],eax				;eax�д�ų���Ľ��
				add j,1						;j++
				mov ecx,j
				cmp ecx,ylen
				jb	innerLoop				;�ص��ڲ�ѭ��

				add i,1
				mov ecx,i
				cmp ecx,xlen				;i++
				jb	outerLoop				;�ص����ѭ��

				pop edx
				pop ecx
				pop ebx
				pop eax
				ret
mulAndAdd		endp
				


start:
	invoke	printf,	offset szMsg

	invoke	scanf, offset szInFmt, offset tmpinput
	invoke	crt_strlen, offset tmpinput					;ͳ�������ַ�������,�������eax��
	mov xlen , eax
	invoke  char2int, offset tmpinput, offset x, xlen	;�����ֽ��ַ���ȥ'0'��������Ϊ4�ֽ�����
	invoke invertNum, offset x, xlen					;�����ְ�����ԳƷ�ת

	invoke	scanf, offset szInFmt, offset tmpinput
	invoke	crt_strlen, offset tmpinput					;ͳ�������ַ�������,�������eax��
	mov ylen , eax
	invoke  char2int, offset tmpinput, offset y, ylen	;�����ֽ��ַ���ȥ'0'��������Ϊ4�ֽ�����
	invoke invertNum, offset y, ylen					;�����ְ�����ԳƷ�ת
	
	invoke mulAndAdd, offset x,offset y,offset ans		;������λ�ļ�����

	
	mov pr,0											;�����λ��ʼ������λ
whileStart:
	mov ecx,pr
	shl ecx,2
	add ecx,offset ans
	mov eax,[ecx]
	mov edx,0					;һ��Ҫ�ǵ�����չ��edx��������edx�ٳ�
	div numBase					;remainder=>edx  ,  quotient=>eax

	mov [ecx],edx
	cmp eax,0
	je nocarry
	add [ecx+4],eax
nocarry:
	add pr,1
	cmp pr,256
	jb whileStart
	
	
	
	;�ҵ��׷���λ
	mov pr,255
	mov edx,pr
	shl edx,2
	mov esi,offset ans
loop1:
	sub edx,4
	mov eax,[edx+esi]
	cmp eax,0
	je loop1

	add edx,4
	mov ebx,edx
loop2:
	sub ebx,4
	mov eax,[esi+ebx]
	invoke printf, offset szOutFmt,eax			;�⺯�������Լ���edx�ģ����˻������һָ�����Ķ�ջƽ��������ȥ�ˣ���Ϊʲô��������ֱ���ñ�ַѰַ����
	cmp ebx,0
	ja loop2

	invoke ExitProcess,0
end start