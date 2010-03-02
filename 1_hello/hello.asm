; vi:ft=nasm:ts=4:tw=78:fdm=marker
;
; Hello world sample
%include "windows.inc"
;-----------------------------------------------------------------------------
DATASEG

;-----------------------------------------------------------------------------
CODESEG
START:
    API     MessageBoxW,0,UNICODE "Hello, I am your first Win32 asm proggy", \
            UNICODE "Message",0
    API     ExitProcess,0
