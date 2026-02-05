@echo off
setlocal enabledelayedexpansion

REM ===== CONFIG =====
set SOURCE=%USERPROFILE%\Desktop\SD_cards
set FILETYPES=*.bin
set DRIVE=D:
set CHECK_INTERVAL=2
set POST_COPY_DELAY=3
set FINAL_EJECT_DELAY=3
REM ==================

echo =====================================
echo SD Auto-Copy Service Started
echo Source: %SOURCE%
echo SD Drive: %DRIVE%
echo =====================================
echo.

REM ===== ASK ONCE AT START =====
set FORMAT_CARD=0

:ASK_FORMAT
set /p USER_CHOICE="Format SD cards to FAT32 before copying images? (Y/N): "
if /I "%USER_CHOICE%"=="Y" (
    set FORMAT_CARD=1
    echo SD cards WILL be formatted to FAT32.
) else if /I "%USER_CHOICE%"=="N" (
    echo SD cards will NOT be formatted.
) else (
    echo Please enter Y or N.
    goto ASK_FORMAT
)

echo.
echo Waiting for SD card...

:MAIN_LOOP
REM --- Wait for SD card insertion ---
:WAIT_FOR_CARD
if not exist "%DRIVE%" (
    timeout /t %CHECK_INTERVAL% >nul
    goto WAIT_FOR_CARD
)

echo SD card detected at %DRIVE%

REM --- Optional format ---
if %FORMAT_CARD%==1 (
    echo WARNING: The SD card %DRIVE% will be formatted to FAT32!
    echo Press Ctrl+C to cancel or wait 3 seconds to continue...
    timeout /t 3 >nul
    echo Formatting %DRIVE%...
    format %DRIVE% /FS:FAT32 /Q /Y >nul
    if errorlevel 1 (
        echo ERROR: Format failed.
        pause
        goto MAIN_LOOP
    )
    timeout /t 3 >nul
)

REM --- Copy files ---
echo Copying image files...
xcopy "%SOURCE%\%FILETYPES%" "%DRIVE%\" /Y /I >nul

echo Copy complete.
echo Waiting %POST_COPY_DELAY% seconds for write flush...
timeout /t %POST_COPY_DELAY% >nul

REM --- Eject SD card ---
echo Ejecting SD card...
powershell -command "(New-Object -comObject Shell.Application).NameSpace(17).ParseName('%DRIVE%').InvokeVerb('Eject')"

REM --- Wait for removal ---
echo Waiting for card removal...
:WAIT_FOR_REMOVAL
if exist "%DRIVE%" (
    timeout /t 1 >nul
    goto WAIT_FOR_REMOVAL
)

echo Card removed. Ready for next one.
echo.
goto MAIN_LOOP