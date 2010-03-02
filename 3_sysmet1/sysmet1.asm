; vi:ft=nasm:ts=4:tw=78:fdm=marker
;
; More complex example from Windows API tutorial
; Display system metrics
%include "windows.inc"

;-----------------------------------------------------------------------------
%define strings EMPTY
%define offsets EMPTY
%assign offset 0
%macro TEXT 1
    %define %%name string %+ offset
    %define %%namelen %%name %+ len
    %xdefine    offsets offsets,%%name
    %xdefine    strings strings,%1
     dd %%name
     db %%namelen
    %assign offset offset+1
%endmacro

%macro  StringTable 1-*
%assign %%offset 0
    %rotate 1
    %rep    %0-1
        %define %%name string %+ %%offset
        %define %%namelen %%name %+ len
     %%name:
        TEXTA   %1
        db  0
        %%namelen   equ $-%%name-1
        %assign %%offset %%offset+1
        %rotate 1
    %endrep     
%endmacro

struc   ENTRY
.Index:     resd 1
.Label:     resd 1
.LabelLen:  resb 1
.Desc:      resd 1
.DescLen:   resb 1
endstruc
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
    at WNDCLASSEX.lpszMenuName,			dd	0
    at WNDCLASSEX.lpszClassName,		dd	szClassName
    at WNDCLASSEX.hIconSm,				dd	0
iend
;-----------------------------------------------------------------------------
CODESEG
szClassName:    TEXTA "SimpleWindowClass\0"
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
	push    WS_OVERLAPPEDWINDOW | WS_VSCROLL  ;DWORD dwStyle
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
	lea		esi,[esp]
align 4
@@
	xor		eax,eax
	push	eax							;wMsgFilterMax
	push	eax							;wMsgFilterMin
	push	eax							;hWnd
	push	esi							;lpMsg
	cw		GetMessageA   
	test	eax,eax
	jz		@F
	push	esi							;lpMsg
	cw		TranslateMessage  
	push	esi							;lpMsg
	cw		DispatchMessageA  
	jmp		short @B
@@
    mov     eax,[esi+MSG.wParam]
	sfree   MSG_size
.exit:
    push    eax                         ;UINT uExitCode
	cw      ExitProcess                 ;void
;-----------------------------------------------------------------------------
;    Window procedure for main window
WndProc:
; arguments
%define     .hWnd   ebp+8
%define     .uMsg   ebp+12
%define     .wParam ebp+16
%define     .lParam ebp+20
; static variables
UDATASEG
.cxChar:    resd 1
.cyChar:    resd 1
.cxCaps:    resd 1
.FirstColumn:  resd 1
.SecondColumn:  resd 1
.cyClient:      resd 1
.vscrollpos:    resd 1
.cyPage:        resd 1
; real procedure
CODESEG
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
    cmp     eax,WM_SIZE
    je      .wm.size
    cmp     eax,WM_VSCROLL
    je      .wm.vscroll
    ; default message processing
    push    dword [.lParam]             ;LPARAM lParam
	push    dword [.wParam]             ;WPARAM wParam
	push    dword [.uMsg]               ;UINT Msg
	push    dword [.hWnd]               ;HWND hWnd
	cw      DefWindowProcA              ;LRESULT
    pop     ebp
    retn    16
.wm.vscroll:
    movzx   eax,word [.wParam]
    cmp     eax,SB_LINEUP
    jnz     @F
        dec     dword [.vscrollpos]
        jmp     .endcase
@@
    cmp     eax,SB_LINEDOWN
    jnz     @F
        inc     dword [.vscrollpos]
        jmp     .endcase
@@
    cmp     eax,SB_PAGEUP
    jnz     @F
        mov     eax,[.cyPage]
        sub     [.vscrollpos],eax
        jmp     .endcase
@@
    cmp     eax,SB_PAGEDOWN
    jnz     @F
        mov     eax,[.cyPage]
        add     [.vscrollpos],eax
        jmp     .endcase
@@
    cmp     eax,SB_THUMBPOSITION
    jnz     .endcase
        mov     eax,[.wParam]
        shr     eax,16
        mov     [.vscrollpos],eax
.endcase:
    push    ebx
    
    min     dword [.vscrollpos],NUMLINES-1,eax
    max     eax,0,ebx
    mov     dword [.vscrollpos],ebx


    push    SB_VERT                     ;int nBar
	push    dword [.hWnd]               ;HWND hWnd
	cw      GetScrollPos                ;int
    cmp     eax,ebx
    jz      .dont.scroll

    push    1                           ;BOOL bRedraw
	push    ebx                         ;int nPos
	push    SB_VERT                     ;int nBar
	push    dword [.hWnd]               ;HWND hWnd
	cw      SetScrollPos                ;int

    push    TRUE                        ;BOOL bErase
	push    0                           ;const RECT *lpRect
	push    dword [.hWnd]               ;HWND hWnd
	cw      InvalidateRect              ;BOOL
.dont.scroll:
    pop     ebx
    jmp     .return0
.wm.size:
    mov     eax,dword [.lParam]         ; HIWORD(lParam)
    shr     eax,16
    mov     [.cyClient],eax
    mov     ecx,[.cyChar]
    or      ecx,ecx
    jz      .return0
    cdq
    div     ecx
    mov     [.cyPage],eax
    jmp     .return0
.wm.create:
    push    esi
    salloc  TEXTMETRIC_size
    lea     esi,[esp]
    push    dword [.hWnd]               ;HWND hWnd
	cw      GetDC                       ;HDC
    push    eax                         ;HDC hDC
    
    push    esi
    push    eax
    cw      GetTextMetricsA  
    mov     ecx,dword [esi+TEXTMETRIC.tmAveCharWidth]
    mov     [.cxChar],ecx
    test    dword [esi+TEXTMETRIC.tmPitchAndFamily],1
    jnz      @F
        mov     eax,2
    jmp     .1
@@
        mov     eax,3
.1:
    cdq
    mul     ecx
    shr     eax,1
    mov     [.cxCaps],eax

    mov     eax,[esi+TEXTMETRIC.tmHeight]
    add     eax,[esi+TEXTMETRIC.tmExternalLeading]
    mov     [.cyChar],eax

	push    dword [.hWnd]               ;HWND hWnd
	cw      ReleaseDC                   ;int
    sfree   TEXTMETRIC_size
    pop     esi
    ; calculate first's and second's column positions
    mov     eax,[.cxCaps]
    mov     ecx,22
    cdq
    mul     ecx
    mov     [.FirstColumn],eax
    ; second
    push    eax
    mov     eax,[.cxChar]
    mov     ecx,40
    cdq
    mul     ecx
    add     eax,[esp]
    mov     [.SecondColumn],eax
    pop     eax
    ; scroll info
    push    0                           ;BOOL bRedraw
	push    NUMLINES-1                  ;int nMaxPos
	push    0                           ;int nMinPos
	push    SB_VERT                     ;int nBar
	push    dword [.hWnd]               ;HWND hWnd
	cw      SetScrollRange              ;BOOL

    push    1                           ;BOOL bRedraw
	push    0                           ;int nPos
	push    SB_VERT                     ;int nBar
	push    dword [.hWnd]               ;HWND hWnd
	cw      SetScrollPos                ;int

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
    salloc  PAINTSTRUCT_size+256
%define .ps ebp-PAINTSTRUCT_size
%define .buffer ebp-PAINTSTRUCT_size-256
    lea     esi,[.ps]
    push    esi                         ;LPPAINTSTRUCT lpPaint
	push    dword [.hWnd]               ;HWND hWnd
	cw      BeginPaint                  ;HDC
    ; any painting goes here
    push    ebx                         ; y 
    push    edi                         ; i
    mov     edi,Sysmetrics
    mov     ebx,[.vscrollpos]
    neg     ebx
    mov     eax,[.cyChar]
    cdq
    imul    ebx
    xchg    eax,ebx
@@    
    movzx   eax,byte [edi+ENTRY.LabelLen]
    push    eax                         ;int 
	push    dword [edi+ENTRY.Label]     ;LPCSTR 
	push    ebx                         ;int 
	push    0                           ;int 
	push    dword [esi+PAINTSTRUCT.hdc] ;HDC 
	cw      TextOutA                    ;BOOL

    movzx   eax,byte [edi+ENTRY.DescLen]
    push    eax                         ;int 
	push    dword [edi+ENTRY.Desc]      ;LPCSTR 
	push    ebx                         ;int 
	push    dword [.FirstColumn]        ;int 
	push    dword [esi+PAINTSTRUCT.hdc] ;HDC 
	cw      TextOutA                    ;BOOL
    
    push    TA_RIGHT | TA_TOP           ;UINT 
	push    dword [esi+PAINTSTRUCT.hdc] ;HDC 
	cw      SetTextAlign                ;UINT

    push    dword [edi+ENTRY.Index]     ;int nIndex
	cw      GetSystemMetrics            ;int

    push    eax
    push    "%5d"
    lea     eax,[.buffer]
    push    eax
    cw      wsprintfA
    add     esp,3*4

    push    eax                         ;int 
    lea     eax,[.buffer]
	push    eax                         ;LPCSTR 
	push    ebx                         ;int 
	push    dword [.SecondColumn]       ;int 
	push    dword [esi+PAINTSTRUCT.hdc] ;HDC 
	cw      TextOutA                    ;BOOL

    push    TA_LEFT | TA_TOP            ;UINT 
	push    dword [esi+PAINTSTRUCT.hdc] ;HDC 
	cw      SetTextAlign                ;UINT
    add     edi,ENTRY_size
    add     ebx,[.cyChar]
    cmp     dword [edi],-1
    jnz     @B

    pop     edi
    pop     ebx
    push    esi                         ;const PAINTSTRUCT *lpPaint
	push    dword [.hWnd]               ;HWND hWnd
	cw      EndPaint                    ;BOOL
    sfree   PAINTSTRUCT_size+256
%undef  .ps
%undef  .buffer
    pop     esi
    jmp     .return0
.wm.destroy:
    push    0                           ;int nExitCode
	cw      PostQuitMessage             ;void
.return0:
    xor     eax,eax
    pop     ebp
    ret     16
; one entry is
;   dd Index
;   dd Label
;   db LabelLen
;   dd Desc
;   db DescLen
Sysmetrics:
dd  SM_CXSCREEN             
    TEXT "SM_CXSCREEN"              
    TEXT "Screen width in pixels"
dd  SM_CYSCREEN
    TEXT "SM_CYSCREEN"              
    TEXT "Screen height in pixels"
dd  SM_CXVSCROLL
    TEXT "SM_CXVSCROLL"             
    TEXT "Vertical scroll width"
dd  SM_CYHSCROLL
    TEXT "SM_CYHSCROLL"             
    TEXT "Horizontal scroll height"
dd  SM_CYCAPTION
    TEXT "SM_CYCAPTION"             
    TEXT "Caption bar height"
dd  SM_CXBORDER
    TEXT "SM_CXBORDER"              
    TEXT "Window border width"
dd  SM_CYBORDER
    TEXT "SM_CYBORDER"              
    TEXT "Window border height"
dd  SM_CXFIXEDFRAME
    TEXT "SM_CXFIXEDFRAME"          
    TEXT "Dialog window frame width"
dd  SM_CYFIXEDFRAME
    TEXT "SM_CYFIXEDFRAME"          
    TEXT "Dialog window frame height"
dd  SM_CYVTHUMB
    TEXT "SM_CYVTHUMB"              
    TEXT "Vertical scroll thumb height"
dd  SM_CXHTHUMB
    TEXT "SM_CXHTHUMB"              
    TEXT "Horizontal scroll thumb width"
dd  SM_CXICON
    TEXT "SM_CXICON"                
    TEXT "Icon width"
dd  SM_CYICON
    TEXT "SM_CYICON"                
    TEXT "Icon height"
dd  SM_CXCURSOR
    TEXT "SM_CXCURSOR"              
    TEXT "Cursor width"
dd  SM_CYCURSOR
    TEXT "SM_CYCURSOR"              
    TEXT "Cursor height"
dd  SM_CYMENU
    TEXT "SM_CYMENU"                
    TEXT "Menu bar height"
dd  SM_CXFULLSCREEN
    TEXT "SM_CXFULLSCREEN"          
    TEXT "Full screen client area width"
dd  SM_CYFULLSCREEN
    TEXT "SM_CYFULLSCREEN"
    TEXT "Full screen client area height"
dd	SM_CYKANJIWINDOW
	TEXT "SM_CYKANJIWINDOW"         
	TEXT "Kanji window height",
dd	SM_MOUSEPRESENT
	TEXT "SM_MOUSEPRESENT"          
	TEXT "Mouse present flag"
dd	SM_CYVSCROLL
	TEXT "SM_CYVSCROLL"             
	TEXT "Vertical scroll arrow height"
dd	SM_CXHSCROLL
	TEXT "SM_CXHSCROLL"             
	TEXT "Horizontal scroll arrow width"
dd	SM_DEBUG
	TEXT "SM_DEBUG"                 
	TEXT "Debug version flag"
dd	SM_SWAPBUTTON
	TEXT "SM_SWAPBUTTON"            
	TEXT "Mouse buttons swapped flag"
dd	SM_CXMIN
	TEXT "SM_CXMIN"                 
	TEXT "Minimum window width"
dd	SM_CYMIN
	TEXT "SM_CYMIN"                 
	TEXT "Minimum window height"
dd	SM_CXSIZE
	TEXT "SM_CXSIZE"                
	TEXT "Min/Max/Close button width"
dd	SM_CYSIZE
	TEXT "SM_CYSIZE"                
	TEXT "Min/Max/Close button height"
dd	SM_CXSIZEFRAME
	TEXT "SM_CXSIZEFRAME"           
	TEXT "Window sizing frame width"
dd	SM_CYSIZEFRAME
	TEXT "SM_CYSIZEFRAME"           
	TEXT "Window sizing frame height"
dd	SM_CXMINTRACK
	TEXT "SM_CXMINTRACK"            
	TEXT "Minimum window tracking width"
dd	SM_CYMINTRACK
	TEXT "SM_CYMINTRACK"            
	TEXT "Minimum window tracking height"
dd	SM_CXDOUBLECLK
	TEXT "SM_CXDOUBLECLK"           
	TEXT "Double click x tolerance"
dd	SM_CYDOUBLECLK
	TEXT "SM_CYDOUBLECLK"           
	TEXT "Double click y tolerance"
dd	SM_CXICONSPACING
	TEXT "SM_CXICONSPACING"         
	TEXT "Horizontal icon spacing"
dd	SM_CYICONSPACING
	TEXT "SM_CYICONSPACING"         
	TEXT "Vertical icon spacing"
dd	SM_MENUDROPALIGNMENT
	TEXT "SM_MENUDROPALIGNMENT"     
	TEXT "Left or right menu drop"
dd	SM_PENWINDOWS
	TEXT "SM_PENWINDOWS"            
	TEXT "Pen extensions installed"
dd	SM_DBCSENABLED
	TEXT "SM_DBCSENABLED"           
	TEXT "Double-Byte Char Set enabled"
dd	SM_CMOUSEBUTTONS
	TEXT "SM_CMOUSEBUTTONS"         
	TEXT "Number of mouse buttons"
dd	SM_SECURE
	TEXT "SM_SECURE"                
	TEXT "Security present flag"
dd	SM_CXEDGE
	TEXT "SM_CXEDGE"                
	TEXT "3-D border width"
dd	SM_CYEDGE
	TEXT "SM_CYEDGE"                
	TEXT "3-D border height"
dd	SM_CXMINSPACING
	TEXT "SM_CXMINSPACING"          
	TEXT "Minimized window spacing width"
dd	SM_CYMINSPACING
	TEXT "SM_CYMINSPACING"          
	TEXT "Minimized window spacing height"
dd	SM_CXSMICON
	TEXT "SM_CXSMICON"              
	TEXT "Small icon width"
dd	SM_CYSMICON
	TEXT "SM_CYSMICON"              
	TEXT "Small icon height"
dd	SM_CYSMCAPTION
	TEXT "SM_CYSMCAPTION"           
	TEXT "Small caption height"
dd	SM_CXSMSIZE
	TEXT "SM_CXSMSIZE"              
	TEXT "Small caption button width"
dd	SM_CYSMSIZE
	TEXT "SM_CYSMSIZE"              
	TEXT "Small caption button height"
dd	SM_CXMENUSIZE
	TEXT "SM_CXMENUSIZE"            
	TEXT "Menu bar button width"
dd	SM_CYMENUSIZE
	TEXT "SM_CYMENUSIZE"            
	TEXT "Menu bar button height"
dd	SM_ARRANGE
	TEXT "SM_ARRANGE"               
	TEXT "How minimized windows arranged"
dd	SM_CXMINIMIZED
	TEXT "SM_CXMINIMIZED"           
	TEXT "Minimized window width"
dd	SM_CYMINIMIZED
	TEXT "SM_CYMINIMIZED"           
	TEXT "Minimized window height"
dd	SM_CXMAXTRACK
	TEXT "SM_CXMAXTRACK"            
	TEXT "Maximum draggable width"
dd	SM_CYMAXTRACK
	TEXT "SM_CYMAXTRACK"            
	TEXT "Maximum draggable height"
dd	SM_CXMAXIMIZED
	TEXT "SM_CXMAXIMIZED"           
	TEXT "Width of maximized window"
dd	SM_CYMAXIMIZED
	TEXT "SM_CYMAXIMIZED"           
	TEXT "Height of maximized window"
dd	SM_NETWORK
	TEXT "SM_NETWORK"               
	TEXT "Network present flag"
dd	SM_CLEANBOOT
	TEXT "SM_CLEANBOOT"             
	TEXT "How system was booted"
dd	SM_CXDRAG
	TEXT "SM_CXDRAG"                
	TEXT "Avoid drag x tolerance"
dd	SM_CYDRAG
	TEXT "SM_CYDRAG"                
	TEXT "Avoid drag y tolerance"
dd	SM_SHOWSOUNDS
	TEXT "SM_SHOWSOUNDS"            
	TEXT "Present sounds visually"
dd	SM_CXMENUCHECK
	TEXT "SM_CXMENUCHECK"           
	TEXT "Menu check-mark width"
dd	SM_CYMENUCHECK
	TEXT "SM_CYMENUCHECK"           
	TEXT "Menu check-mark height"
dd	SM_SLOWMACHINE
	TEXT "SM_SLOWMACHINE"           
	TEXT "Slow processor flag"
dd	SM_MIDEASTENABLED
	TEXT "SM_MIDEASTENABLED"        
	TEXT "Hebrew and Arabic enabled flag"
dd	SM_MOUSEWHEELPRESENT
	TEXT "SM_MOUSEWHEELPRESENT"     
	TEXT "Mouse wheel present flag"
dd	SM_XVIRTUALSCREEN
	TEXT "SM_XVIRTUALSCREEN"        
	TEXT "Virtual screen x origin"
dd	SM_YVIRTUALSCREEN
	TEXT "SM_YVIRTUALSCREEN"        
	TEXT "Virtual screen y origin"
dd	SM_CXVIRTUALSCREEN
	TEXT "SM_CXVIRTUALSCREEN"       
	TEXT "Virtual screen width"
dd	SM_CYVIRTUALSCREEN
	TEXT "SM_CYVIRTUALSCREEN"       
	TEXT "Virtual screen height"
dd	SM_CMONITORS
	TEXT "SM_CMONITORS"             
	TEXT "Number of monitors"
dd	SM_SAMEDISPLAYFORMAT
	TEXT "SM_SAMEDISPLAYFORMAT"     
    TEXT "Same color format flag"
NUMLINES    equ ($-Sysmetrics)/ENTRY_size
times ENTRY_size dd -1
StringTable strings
%undef strings
%undef offsets
%undef offset
