; vi:ft=nasm:ts=4:tw=78:fdm=marker
;
; macro API is trying to emulate invoke directive from MASM
[LIST -]
%include "windows.inc"
libs kernel32.lib,user32.lib
[LIST +]
;-----------------------------------------------------------------------------
IDD_DLG equ 100
;-----------------------------------------------------------------------------
CODESEG
START:
    API     MessageBoxW,0,UNICODE "Message", UNICODE "Title",\
            MB_ICONINFORMATION
    API     DialogBoxParamW,NESTED{GetModuleHandleA,0},IDD_DLG,0,ADDR DlgProc,0
    API     ExitProcess,eax
;-----------------------------------------------------------------------------
DlgProc proc hWnd,uMsg,wParam,lParam    ;{{{
    mov     eax,[.uMsg]
    cmp     eax,WM_CREATE
    jz      .wm.create
    cmp     eax,WM_CLOSE
    jz      .wm.close
    xor     eax,eax
    return
.wm.create:
    jmp     .return
.wm.close:
    API     EndDialog,[.hWnd],0
.return:
    xor     eax,eax
    inc     eax   
    return
DlgProc endp                            ;}}}
;-----------------------------------------------------------------------------
