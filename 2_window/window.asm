; vi:ft=nasm:ts=4:tw=78:fdm=marker
;
; Display a simple window
; sample converted from Windows api tutorial
%include "windows.inc"
;-----------------------------------------------------------------------------
DATASEG
wc:
istruc WNDCLASSEX
    at WNDCLASSEX.cbSize,				dd	WNDCLASSEX_size
    at WNDCLASSEX.style,				dd	CS_VREDRAW + CS_HREDRAW
    at WNDCLASSEX.lpfnWndProc,			dd	WndProc
    at WNDCLASSEX.cbClsExtra,			dd	0
    at WNDCLASSEX.cbWndExtra,			dd	0
    at WNDCLASSEX.hInstance,			DD	0x400000
    at WNDCLASSEX.hIcon,				DD	0
    at WNDCLASSEX.hCursor,				DD	0
    at WNDCLASSEX.hbrBackground,		dd	COLOR_WINDOW
    at WNDCLASSEX.lpszMenuName, 		dd	0
    at WNDCLASSEX.lpszClassName,		dd	szClassName
    at WNDCLASSEX.hIconSm,				dd	0
iend
szClassName:    TEXTA "SimpleWindowClass\0"
;-----------------------------------------------------------------------------
CODESEG
START:
    push    IDI_APPLICATION             ;LPCSTR lpIconName
	push    0                           ;HINSTANCE hInstance
	cw      LoadIconA                   ;HICON
    mov     [wc+WNDCLASSEX.hIcon],eax
    push    IDC_ARROW                   ;LPCSTR lpCursorName
	push    0                           ;HINSTANCE hInstance
	cw      LoadCursorA                 ;HCURSOR
    mov     [wc+WNDCLASSEX.hCursor],eax
    mov     D[wc+WNDCLASSEX.hbrBackground],COLOR_WINDOW+1
    push    wc                          ;const WNDCLASSEXA *
	cw      RegisterClassExA            ;ATOM
    or      eax,eax
    jnz     @F
        push    MB_ICONERROR                ;UINT uType
	    push    0                           ;LPCSTR lpCaption
	    push    "Cannot register class!"    ;LPCSTR lpText
	    push    0                           ;HWND hWnd
	    cw      MessageBoxA                 ;int
        jmp     .exit
@@
    xor     eax,eax
    push    eax                         ;LPVOID lpParam
	push    dword [wc+WNDCLASSEX.hInstance] ;HINSTANCE hInstance
	push    eax                         ;HMENU hMenu
	push    eax                         ;HWND hWndParent
	push    CW_USEDEFAULT               ;int nHeight
	push    CW_USEDEFAULT               ;int nWidth
	push    eax                         ;int Y
	push    eax                         ;int X
	push    WS_OVERLAPPEDWINDOW         ;DWORD dwStyle
	push    "Simple window"             ;LPCSTR lpWindowName
	push    szClassName                 ;LPCSTR lpClassName
	push    eax                         ;DWORD dwExStyle
	cw      CreateWindowExA             ;HWND
    or      eax,eax
    jnz     @F
        push    MB_ICONERROR                ;UINT uType
	    push    0                           ;LPCSTR lpCaption
	    push    "Cannot create window!"     ;LPCSTR lpText
	    push    0                           ;HWND hWnd
	    cw      MessageBoxA                 ;int
        jmp     .exit
@@
    push    eax                         ;HWND hWnd
    
    push    SW_SHOW                     ;int nCmdShow
	push    eax                         ;HWND hWnd
	cw      ShowWindow                  ;BOOL
    cw      UpdateWindow                ;BOOL

    salloc  MSG_size
	lea 	esi,[esp]
align 4
@@
	xor 	eax,eax
	push	eax 	            		;wMsgFilterMax
	push	eax 				    	;wMsgFilterMin
	push	eax 						;hWnd
	push	esi 						;lpMsg
	cw	    GetMessageA   
	test	eax,eax
	jz		@F
	push	esi 						;lpMsg
	cw	    TranslateMessage  
	push	esi 					    ;lpMsg
	cw	    DispatchMessageA  
	jmp 	short @B
@@
    mov     eax,[esi+MSG.wParam]
	sfree   MSG_size
.exit:
    push    eax                         ;UINT uExitCode
	cw      ExitProcess                 ;void
;-----------------------------------------------------------------------------
;    Window procedure for main window
WndProc:
%define     .hWnd   ebp+8
%define     .uMsg   ebp+12
%define     .wParam ebp+16
%define     .lParam ebp+20
    push    ebp
    mov     ebp,esp
    mov     eax,[.uMsg]
    cmp     eax,WM_CREATE
    je      .wm.create
    cmp     eax,WM_PAINT
    je      .wm.paint
    cmp     eax,WM_DESTROY
    je      .wm.destroy
    cmp     eax,WM_CLOSE
    je      .wm.close
    ; default message processing
    push    dword [.lParam]             ;LPARAM lParam
	push    dword [.wParam]             ;WPARAM wParam
	push    dword [.uMsg]               ;UINT Msg
	push    dword [.hWnd]               ;HWND hWnd
	cw      DefWindowProcA              ;LRESULT
    leave
    retn    16
.wm.create:
    jmp     .return0
.wm.close:
    push    MB_ICONQUESTION|MB_YESNO    ;UINT uType
	push    "Question"                  ;LPCSTR lpCaption
	push    "Are you sure?"             ;LPCSTR lpText
	push    dword [.hWnd]               ;HWND hWnd
	cw      MessageBoxA                 ;int
    cmp     eax,IDYES
    jne     @F
        push    dword [.hWnd]               ;HWND hWnd
	    cw      DestroyWindow               ;BOOL
@@
    jmp     .return0
.wm.paint:
    push    esi
    salloc  PAINTSTRUCT_size
    lea     esi,[esp]
    push    esi                         ;LPPAINTSTRUCT lpPaint
	push    dword [.hWnd]               ;HWND hWnd
	cw      BeginPaint                  ;HDC
    ; any painting goes here


    push    esi                         ;const PAINTSTRUCT *lpPaint
	push    dword [.hWnd]               ;HWND hWnd
	cw      EndPaint                    ;BOOL
    sfree   PAINTSTRUCT_size
    pop     esi
    jmp     .return0
.wm.destroy:
    push    0                           ;int nExitCode
	cw      PostQuitMessage             ;void
.return0:
    xor     eax,eax
    leave
    ret     16
