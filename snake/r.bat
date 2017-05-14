@echo off
set INCLUDE_PART=/i\music\
\dos\bc\bin\tasm /t /l /zi %1.asm
\dos\bc\bin\tlink /Tde /l %1.obj
%1.exe %2 %3 %4 %5 %6 %7