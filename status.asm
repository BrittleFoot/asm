



SC_C            = 2Eh
SC_CTRL         = 1Dh
SC_LSHIFT       = 2Ah
SC_RSHIFT       = 36h
SC_ALT          = 38h
SC_CAPS_LOCK    = 3Ah
SC_NUM_LOCK     = 45h
SC_SCRL_LOCK    = 46h



_417:

ALT_PRESSED             = 00001000b
CTRL_PRESSED            = 00000100b
LEFT_SHIFT_PRESSED      = 00000010b
RIGHT_SHIFT_PRESSED     = 00000001b



CAPS = 00000100b
NUM  = 00000010b
SCRL = 00000001b


total_pressed   db 00h  
pressed_keys    db 0FFh dup (0)