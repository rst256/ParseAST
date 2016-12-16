@echo off

%~d3
CD %3

echo -------- Generate code ... ----------

echo ----------- Compiling ... ----------
:compile
SET path="c:\msys32\usr\bin;c:\ZeroBrane\bin;"%path%
:: c:\msys32\usr\bin\gcc -std=c11 -g lex1.c -o lex1.exe
IF %ERRORLEVEL% EQU 0 GOTO compile_lua_l
echo --------- Compile failed ----------
GOTO end_l

:compile_lua_l
:: cl /Ic:\Lua\5.1\include /IC:\Projects\Lua\cmodules   C:\dev\utf8\re2c\release\lua.c /LD -o lexer.dll /link c:\Lua\5.1\lua51.dll

 C:\msys32\usr\bin\gcc.exe -Ic:\Projects\Lua\cmodules\lua53\src -IC:\Projects\Lua\cmodules -std=c11 -g  C:\dev\utf8\re2c\release\lua.c -shared -o lexer.dll lua53.dll
 
 :: C:\msys32\usr\bin\gcc.exe -Ic:\Lua\5.1\include -IC:\Projects\Lua\cmodules -std=c11 -g  C:\dev\utf8\re2c\release\lua.c -shared -o lexer.dll c:\Lua\5.1\lua51.dll
 
 :: tcc -Bc:\bin -Lc:\Lua\5.1 -llua51 -Ic:\Lua\5.1\include -IC:\Projects\Lua\cmodules -g  C:\dev\utf8\re2c\release\lua.c -shared -o lexer.dll
:: ..\lua52.dll
IF %ERRORLEVEL% EQU 0 GOTO lua_test_l
echo --------- Compile LUA failed ----------
GOTO end_l


echo --------- Compile failed ----------
GOTO end_l

:run_l
echo ---------- Run program ----------
:: lex1.exe test\test.c test\out.c > test\out.log
:: lex1.exe test\out.c test\out-rev.c > test\out-rev.log
:: > tests\out3.ans
:: IF %ERRORLEVEL% EQU 1 GOTO check3_l
:: echo RUNTIME ERROR (%ERRORLEVEL%)
:: gdb -ex run ./lex1.exe test\test.c
:: 
:: :check3_l
:: fc /T /W test\out.c test\out-rev.c
:: fc /T /W test\untranslated.req test\untranslated.list
:: fc /T /W test\undefined.req test\undefined.list

:: IF NOT %ERRORLEVEL% EQU 0 GOTO test_fail_l
%rar% a  -x\*\.archive\ -x\*\.git\ -x\.git\ -x\.archive\  -x@.archive\ignore.list  -r  -agYYYYMMDD-HHMM .archive\auto-good-  * >.archive\log.txt
GOTO lua_test_l

:test_fail_l
echo TEST FAILED

exit
:: gdb -ex run ./a.exe
:: :end_l

:: IF NOT %ERRORLEVEL% EQU 0 GOTO test_fail_l
:: %rar% a  -x\*\.archive\ -x\*\.git\ -x\.git\ -x\.archive\  -x@.archive\ignore.list  -r  -agYYYYMMDD-HHMM .archive\auto-good-  * >.archive\log.txt
:: GOTO end_l
:: 
:: :test_fail_l
:: echo Test failed


:lua_test_l
C:\dev\utf8\re2c\release\lua.exe test.lua 
echo RUNTIME ERROR (%ERRORLEVEL%)
IF %ERRORLEVEL% EQU 0 GOTO end_l
gdb -ex run --args C:\dev\utf8\re2c\release\lua.exe test.lua 

:end_l
echo ALL TESTS SUSSESS
:: lua