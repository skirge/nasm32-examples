; vi:ft=nasm:ts=4:tw=78:fdm=marker
;
; $Id$
;
; Copyright (C) 2005 QUASAR
;
; $Log$
;
%include "ntddk.inc"
STATUS_DEVICE_CONFIGURATION_ERROR		equ 00C0000182h
;-----------------------------------------------------------------------------
section INIT
DriverEntry proc DriverObject,RegistryPath
    mov     eax,STATUS_DEVICE_CONFIGURATION_ERROR
    return
DriverEntry  endp
