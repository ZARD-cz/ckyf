@echo off
rem ==========================================================================
rem  clean_keil.bat  -  Safe cleaner for Keil MDK build artifacts
rem  v1.0
rem  NOTE: this file is encoded as GBK (ANSI/CP936). Keep it that way.
rem ==========================================================================
rem IMPORTANT: "<nul" keeps chcp from swallowing redirected stdin (set /p later).
chcp 936 >nul 2>&1 <nul
setlocal EnableExtensions EnableDelayedExpansion

set "SCRIPT_DIR=%~dp0"
set "VERSION=1.0"
set "PROJ="
set "YES=0"
set "PREVIEW_ONLY=0"
set "CLEAN_FW=0"
set "HAS_ARGS=0"
set "RC=0"
set "NDIRS=0"
set "N_DEL=0"
set "N_FAIL=0"
set "N_SKIP=0"
set "N_RDIR=0"
set "NFILES=0"
set "NBYTES=0"
set "WORK="
set "LOG="

rem --------------------------------------------------------------------------
rem  解析命令行
rem --------------------------------------------------------------------------
:parse
if "%~1"=="" goto parsed
set "HAS_ARGS=1"
if /i "%~1"=="/?" goto usage
if /i "%~1"=="/h" goto usage
if /i "%~1"=="-h" goto usage
if /i "%~1"=="--help" goto usage
if /i "%~1"=="/y" goto opt_y
if /i "%~1"=="/f" goto opt_f
if /i "%~1"=="/n" goto opt_n
if /i "%~1"=="/p" goto opt_p
goto opt_path

:opt_y
set "YES=1"
shift
goto parse

:opt_f
set "CLEAN_FW=1"
shift
goto parse

:opt_n
set "PREVIEW_ONLY=1"
shift
goto parse

:opt_p
if "%~2"=="" goto err_p
set "PROJ=%~2"
shift
shift
goto parse

:opt_path
if exist "%~1\" (
  set "PROJ=%~1"
  shift
  goto parse
)
if exist "%~1" (
  for %%I in ("%~1") do set "PROJ=%%~dpI"
  shift
  goto parse
)
set "bad=%~1"
echo [错误] 无法识别的参数: !bad!
set "RC=1"
goto finish

:err_p
echo [错误] /p 后面需要指定工程目录，例如:
echo        clean_keil.bat /p "D:\work\my_project"
set "RC=1"
goto finish

rem --------------------------------------------------------------------------
rem  定位工程目录并做基本安全检查
rem --------------------------------------------------------------------------
:parsed
if not defined PROJ set "PROJ=%SCRIPT_DIR%"
for %%I in ("%PROJ%") do set "PROJ=%%~fI"
if not "%PROJ:~-1%"=="\" set "PROJ=%PROJ%\"
set "PDISP=%PROJ%"
set "PROJROOT=%PROJ:~0,-1%"

rem  拒绝在盘符根目录运行，防止误删整盘文件
if "%PROJ:~1,1%"==":" if "%PROJ:~3%"=="" (
  echo [错误] 不允许在盘符根目录下运行: !PDISP!
  echo        请把本脚本放进 Keil 工程目录，或用 /p 指定工程目录。
  set "RC=1"
  goto finish
)
if not exist "%PROJ%\" (
  echo [错误] 工程目录不存在: !PDISP!
  set "RC=1"
  goto finish
)

rem  必须是 Keil 工程根目录，否则不执行任何删除
set "FOUND=0"
for %%P in ("%PROJ%*.uvprojx" "%PROJ%*.uvproj") do if exist "%%~fP" set "FOUND=1"
if "%FOUND%"=="0" (
  echo [错误] 当前目录不是 Keil 工程根目录，未找到 *.uvprojx / *.uvproj 文件:
  echo        !PDISP!
  echo        请把本脚本放到 Keil 工程根目录，或用 /p 指定工程目录，
  echo        也可以直接把工程文件夹拖到本脚本上运行。
  set "RC=1"
  goto finish
)

echo.
echo ============================================================
echo  Keil MDK 编译中间文件清理工具  v%VERSION%
echo ============================================================
echo  工程目录 : !PDISP!

rem --------------------------------------------------------------------------
rem  准备临时文件和日志目录
rem --------------------------------------------------------------------------
set "LOGDIR=%TEMP%"
if not exist "%LOGDIR%\" set "LOGDIR=%USERPROFILE%"
if not exist "%LOGDIR%\" set "LOGDIR=%SCRIPT_DIR%"
set "WORK=%LOGDIR%\keil_clean_%RANDOM%%RANDOM%"
md "%WORK%" >nul 2>&1
if not exist "%WORK%\" (
  echo [错误] 无法创建临时目录，请检查 TEMP 环境变量和磁盘权限。
  set "RC=1"
  goto finish
)
set "DIRS=%WORK%\dirs.txt"
set "LIST=%WORK%\files.txt"
set "SUMMARY=%WORK%\summary.txt"
> "%DIRS%" type nul
> "%LIST%" type nul
> "%SUMMARY%" type nul

call :strlen "%PROJ%" PROJLEN

rem --------------------------------------------------------------------------
rem  从工程文件读取输出目录，并补充常见的输出目录名
rem --------------------------------------------------------------------------
call :parse_project "%PROJ%*.uvprojx"
call :parse_project "%PROJ%*.uvproj"
call :add_outdir "Objects\"
call :add_outdir "Listings\"
call :add_outdir "Output\"
call :add_outdir "OBJ\"

if "%NDIRS%"=="0" (
  echo.
  echo  未发现编译输出目录，工程可能还没有编译过，无需清理。
  goto finish_ok
)

set "EXTS=o obj d crf dep lnp lst map iex sct htm"
if "%CLEAN_FW%"=="1" set "EXTS=!EXTS! axf elf hex bin s19 srec"

rem --------------------------------------------------------------------------
rem  收集文件
rem --------------------------------------------------------------------------
for /f "usebackq delims=" %%D in ("%DIRS%") do call :collect_dir "%%D"
call :compute_totals

if "!NFILES!"=="0" (
  echo.
  echo  未发现需要清理的编译中间文件，工程可能已经是干净的。
  goto finish_ok
)

rem --------------------------------------------------------------------------
rem  预览
rem --------------------------------------------------------------------------
echo.
echo  将清理以下编译输出目录:
for /f "usebackq tokens=1,2 delims=|" %%A in ("%SUMMARY%") do (
  if not "%%B"=="0" (
    set "rel=%%A"
    set "rel=!rel:~%PROJLEN%!"
    if "!rel!"=="" set "rel=."
    echo    - !rel!\  （%%B 个文件）
  )
)

call :fmt_size
echo  合计 : !NFILES! 个文件，约 !SIZE_TXT!

echo.
echo  默认保留（不会删除）: 源文件 .c/.h/.s/.asm、工程文件 .uvprojx/.uvoptx、
echo    .uvproj/.uvopt、库文件 .lib/.a，以及 DebugConfig、RTE 等配置目录。
if "!CLEAN_FW!"=="0" echo  固件产物 .axf/.hex/.bin 默认保留，需要一起删除请加 /f。
if "!CLEAN_FW!"=="1" echo  注意: 已启用 /f，.axf/.elf/.hex/.bin 固件产物也会被删除。
echo.

if "!PREVIEW_ONLY!"=="1" (
  echo [预览模式] 没有删除任何文件。去掉 /n 并确认后即可执行清理。
  goto finish_ok
)
if "!YES!"=="1" goto do_clean

set "ans="
set /p "ans=确认删除以上文件吗？输入 Y 回车执行，直接回车取消: "
if /i not "!ans:~0,1!"=="y" (
  echo.
  echo 已取消，没有删除任何文件。
  goto finish_ok
)

rem --------------------------------------------------------------------------
rem  执行清理
rem --------------------------------------------------------------------------
:do_clean
set "TS=%DATE%_%TIME%"
set "TS=!TS:/=-!"
set "TS=!TS::=-!"
set "TS=!TS:.=-!"
set "TS=!TS:,=-!"
set "TS=!TS: =-!"
set "LOG=%LOGDIR%\keil_clean_!TS!.log"
> "%LOG%" echo([clean_keil v%VERSION%]
>>"%LOG%" echo(Project : !PDISP!
>>"%LOG%" echo(Time    : !TS!
>>"%LOG%" echo(Options : YES=!YES!  CLEAN_FW=!CLEAN_FW!
>>"%LOG%" echo(------------------------------------------------------------

echo.
echo  正在清理...
for /f "usebackq delims=" %%F in ("%LIST%") do (
  set "p=%%F"
  set "attr="
  for %%S in ("%%F") do set "attr=%%~aS"
  if not defined attr (
    set /a N_FAIL+=1
    >>"%LOG%" echo([FAIL] !p!
  ) else (
    if not "!attr:l=!"=="!attr!" (
      set /a N_SKIP+=1
      >>"%LOG%" echo([SKIP] !p!
    ) else (
      del /f /q /a "%%F" >nul 2>&1
      if exist "%%F" (
        set /a N_FAIL+=1
        >>"%LOG%" echo([FAIL] !p!
      ) else (
        set /a N_DEL+=1
        >>"%LOG%" echo([DEL ] !p!
      )
    )
  )
)

rem  只删除清理后已经变空的输出目录（rd 对非空目录会失败，因此是安全的）
for /f "usebackq delims=" %%D in ("%DIRS%") do call :try_remove_dir "%%D"

>>"%LOG%" echo(------------------------------------------------------------
>>"%LOG%" echo(Deleted=!N_DEL!  Failed=!N_FAIL!  Skipped=!N_SKIP!  RemovedDirs=!N_RDIR!

echo.
echo ============================================================
echo  清理完成
echo    删除文件 : !N_DEL! 个
if not "!N_SKIP!"=="0" echo    跳过链接 : !N_SKIP! 个
if not "!N_FAIL!"=="0" echo    删除失败 : !N_FAIL! 个
echo    删除空目录: !N_RDIR! 个
echo    操作日志 : !LOG!
echo ============================================================
if not "!N_FAIL!"=="0" (
  echo  提示: 有文件删除失败，通常是被 Keil 或编辑器占用，关闭后重试即可。
  set "RC=1"
)
goto finish

rem --------------------------------------------------------------------------
rem  帮助
rem --------------------------------------------------------------------------
:usage
echo.
echo  clean_keil.bat  v%VERSION%
echo  安全清理 Keil MDK 工程编译中间文件的批处理脚本。
echo.
echo  用法:
echo    clean_keil.bat                 预览并确认后清理（双击运行）
echo    clean_keil.bat /y              直接清理，不再确认
echo    clean_keil.bat /n              只预览，不删除任何文件
echo    clean_keil.bat /f              额外删除固件产物 .axf/.elf/.hex/.bin 等
echo    clean_keil.bat /p ＜工程目录＞   指定工程目录（默认是本脚本所在目录）
echo    clean_keil.bat /?              显示本帮助
echo    也可以把工程文件夹直接拖到本脚本图标上运行。
echo.
echo  默认清理的扩展名（只会在编译输出目录内查找）:
echo    .o .obj .d .crf .dep .lnp .lst .map .iex .sct .htm
echo  /f 追加清理:
echo    .axf .elf .hex .bin .s19 .srec
echo.
echo  安全机制:
echo    1. 只在 Keil 工程的编译输出目录内操作，输出目录取自 .uvprojx 里的
echo       OutputDirectory / ListingPath，并补充 Objects/Listings/Output/OBJ。
echo    2. 只删除上面的扩展名，绝不删除 .c/.h/.s/.uvprojx/.uvoptx 等源文件
echo       和工程文件。
echo    3. 删除前列出数量和大小，交互确认后才执行。
echo    4. 跳过符号链接/目录联接，输出目录在工程外时直接跳过。
echo    5. 只删除已经变空的输出目录，且从不删除工程根目录。
echo    6. 每个被删除的文件都写入 TEMP 目录下的日志，便于事后核对。
echo    7. 只清理输出目录的第一层（Keil 默认输出是扁平结构），不会递归
echo       钻进输出目录的子文件夹，避免误碰链接或其它工程。
echo.
echo  提示: 文件名保持 GBK 编码保存，否则中文提示可能显示为乱码。
set "RC=0"
goto finish

rem ==========================================================================
rem  子程序
rem ==========================================================================

:strlen
setlocal EnableDelayedExpansion
set "s=%~1"
set "n=0"
:strlen_loop
if defined s (
  set "s=!s:~1!"
  set /a n+=1
  goto strlen_loop
)
endlocal & set "%~2=%n%"
exit /b

:parse_project
set "spec=%~1"
for /f "usebackq delims=" %%L in (`findstr /i /c:"<OutputDirectory>" "!spec!" 2^>nul`) do call :add_tagged "%%L" "<OutputDirectory>"
for /f "usebackq delims=" %%L in (`findstr /i /c:"<ListingPath>" "!spec!" 2^>nul`) do call :add_tagged "%%L" "<ListingPath>"
exit /b

:add_tagged
set "ln=%~1"
set "tag=%~2"
set "ln=!ln:*%tag%=!"
for /f "delims=<" %%V in ("!ln!") do call :add_outdir "%%V"
exit /b

:add_outdir
set "raw=%~1"
if not defined raw exit /b
for /f "tokens=* delims= " %%X in ("!raw!") do set "raw=%%X"
if not defined raw exit /b
if /i "!raw:~1,1!"==":" goto ao_abs
if "!raw:~0,2!"=="\\" goto ao_abs
for %%I in ("%PROJ%!raw!") do set "abs=%%~fI"
goto ao_norm

:ao_abs
for %%I in ("!raw!") do set "abs=%%~fI"

:ao_norm
if not defined abs exit /b
if not "!abs:~-1!"=="\" set "abs=!abs!\"
if /i not "!abs:~0,%PROJLEN%!"=="%PROJ%" (
  echo   [跳过] 输出目录在工程目录之外: !abs!
  exit /b
)
if not exist "!abs!" exit /b
set "abs=!abs:~0,-1!"
for /f "usebackq delims=" %%D in ("%DIRS%") do if /i "%%D"=="!abs!" exit /b
>>"%DIRS%" echo(!abs!
set /a NDIRS+=1
exit /b

:collect_dir
set "d=%~1"
set "attr="
for %%I in ("!d!") do set "attr=%%~aI"
if defined attr if not "!attr:l=!"=="!attr!" (
  echo   [跳过] 符号链接或目录联接: !d!
  exit /b
)
set "cnt=0"
for %%E in (%EXTS%) do (
  for /f "usebackq delims=" %%F in (`dir /b /a-d "!d!\*.%%E" 2^>nul`) do (
    set "p=!d!\%%F"
    >>"%LIST%" echo(!p!
    set /a cnt+=1
  )
)
>>"%SUMMARY%" echo(!d!^|!cnt!
exit /b

:compute_totals
set /a NFILES=0
set /a NBYTES=0
for /f "usebackq delims=" %%F in ("%LIST%") do (
  set /a NFILES+=1
  for %%S in ("%%F") do set /a NBYTES+=%%~zS
)
exit /b

:fmt_size
set /a KB=NBYTES/1024
set "SIZE_TXT=!KB! KB"
if !KB! LSS 1024 exit /b
set /a MB=KB/1024
set /a DEC=KB-MB*1024
set /a DEC=DEC*10
set /a DEC=DEC/1024
set "SIZE_TXT=!MB!.!DEC! MB"
exit /b

:try_remove_dir
set "d=%~1"
if /i "!d!"=="%PROJROOT%" exit /b
if not exist "!d!\" exit /b
set "attr="
for %%I in ("!d!") do set "attr=%%~aI"
if defined attr if not "!attr:l=!"=="!attr!" exit /b
set "has=0"
for /f "usebackq delims=" %%X in (`dir /b /a "!d!" 2^>nul`) do set "has=1"
if "!has!"=="1" exit /b
rd "!d!" >nul 2>&1
if not exist "!d!\" (
  >>"%LOG%" echo([RMDIR] !d!
  set /a N_RDIR+=1
)
exit /b

rem ==========================================================================
rem  收尾
rem ==========================================================================

:finish_ok
set "RC=0"

:finish
if defined WORK if exist "!WORK!" rd /s /q "!WORK!" >nul 2>&1
if "%HAS_ARGS%"=="0" (
  echo.
  pause
)
endlocal & exit /b %RC%
