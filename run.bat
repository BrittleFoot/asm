@echo off
\dos\bc\bin\tasm /t /l /z %1.asm
\dos\bc\bin\tlink /t /l %1.obj
rem %2 %1.com
%1.com %2 %3