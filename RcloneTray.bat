@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul
title Rclone Tray Manager
color 0B

REM ========================================================
REM   Path Configuration (Point to the 'core' subfolder)
REM ========================================================
set "CORE_DIR=%~dp0core"

REM Check if rclone.exe exists
if not exist "%CORE_DIR%\rclone.exe" (
    cls
    color 0C
    echo ========================================================
    echo  [ERROR] File Missing!
    echo ========================================================
    echo.
    echo  Could not find: "%CORE_DIR%\rclone.exe"
    echo.
    echo  Please make sure you have placed the 'rclone.exe'
    echo  inside the 'core' folder.
    echo.
    pause
    exit
)

:MENU
cls
echo =================================================
echo           Rclone Tray Manager
echo =================================================
echo.
echo    [1] Setup Rclone Config (rclone.conf)
echo        ^> Link your cloud accounts.
echo.
echo    [2] Configure Mounts (mount.conf)
echo        ^> Map remotes to drive letters.
echo.
echo    [3] Install Desktop Shortcut
echo    [4] Enable Auto-Start (Silent Mode)
echo.
echo    [0] Exit
echo.
echo =================================================
set /p choice=Enter choice: 

if "%choice%"=="1" goto RCLONE_CONFIG
if "%choice%"=="2" goto MOUNT_CONFIG
if "%choice%"=="3" goto INSTALL
if "%choice%"=="4" goto AUTOSTART
if "%choice%"=="0" exit
goto MENU

:RCLONE_CONFIG
cls
echo [INFO] Launching Rclone Command Line Wizard...
echo.
echo    Config file: %CORE_DIR%\rclone.conf
echo.
"%CORE_DIR%\rclone.exe" config --config "%CORE_DIR%\rclone.conf"
echo.
echo [DONE] Configuration closed.
pause
goto MENU

:MOUNT_CONFIG
cls
echo =================================================
echo           Mount Configuration Wizard
echo =================================================
echo.
echo Current 'mount.conf' content:
if exist "%CORE_DIR%\mount.conf" (
    echo ---------------------------------------------
    type "%CORE_DIR%\mount.conf"
    echo ---------------------------------------------
) else (
    echo [Empty - No mounts configured]
)
echo.
echo    [1] Add a New Mount
echo    [2] Clear/Reset All Mounts
echo    [3] Edit Manually (Notepad)
echo.
echo    [0] Back to Menu
echo.
echo =================================================
set /p mchoice=Select option: 

if "%mchoice%"=="0" goto MENU
if "%mchoice%"=="3" goto EDIT_MOUNT
if "%mchoice%"=="2" goto CLEAR_MOUNT
if "%mchoice%"=="1" goto ADD_MOUNT
goto MOUNT_CONFIG

:ADD_MOUNT
echo.
echo --- Add New Mount ---
echo.

REM --- List configured remotes ---
echo Checking configured remotes...
if not exist "%CORE_DIR%\rclone.conf" (
    echo    [WARN] rclone.conf not found. Please run Option [1] first.
) else (
    powershell -Command "$out = & '%CORE_DIR%\rclone.exe' listremotes --config '%CORE_DIR%\rclone.conf'; if($out) { Write-Host '   Found Remotes: ' -NoNewline; $out | ForEach-Object { Write-Host ($_.TrimEnd(':') + ' ') -NoNewline -ForegroundColor Green }; Write-Host '' } else { Write-Host '   (No remotes found)' -ForegroundColor Yellow }"
)
echo.

set "rname="
set /p rname=1. Enter Remote Name: 
if "%rname%"=="" goto ADD_MOUNT

echo.
REM --- List available drive letters ---
echo Checking available drive letters...
powershell -Command "$used=[System.IO.DriveInfo]::GetDrives().Name.Substring(0,1); Write-Host '   Available: ' -NoNewline; (65..90 | ForEach-Object { [char]$_ }) | Where-Object { $used -notcontains $_ } | ForEach-Object { Write-Host \"$_ \" -NoNewline -ForegroundColor Green }; Write-Host ''"
echo.

set "letter="
set /p letter=2. Enter Drive Letter: 
if "%letter%"=="" goto ADD_MOUNT

REM --- Auto-append colon ---
set "letter=%letter: =%"
if not "%letter:~-1%"==":" set "letter=%letter%:"

echo.
set "label="
set /p label=3. Enter Drive Label (Press Enter to use '%rname%'): 
if "!label!"=="" set "label=%rname%"

REM --- Auto-calculate port ---
echo.
echo [Calculating Port...]
set "NEXT_PORT=5572"
if exist "%CORE_DIR%\mount.conf" (
    for /f %%i in ('powershell -Command "$max=5571; Get-Content '%CORE_DIR%\mount.conf' | ForEach-Object { $p=$_.Split('|')[3]; if([int]$p -gt $max){$max=[int]$p} }; Write-Output ($max+1)"') do set NEXT_PORT=%%i
)
echo    ^> Auto-assigned Port: %NEXT_PORT%

REM Write to file
echo %rname%^|%letter%^|%label%^|%NEXT_PORT%>> "%CORE_DIR%\mount.conf"
echo.
echo [SUCCESS] Mount added: %rname% --^> %letter%
timeout /t 2 >nul
goto MOUNT_CONFIG

:CLEAR_MOUNT
echo.
echo [WARNING] This will delete all mount configurations.
set /p confirm=Are you sure? (y/n): 
if /i "%confirm%"=="y" (
    del "%CORE_DIR%\mount.conf" >nul 2>&1
    echo [INFO] mount.conf cleared.
)
goto MOUNT_CONFIG

:EDIT_MOUNT
if not exist "%CORE_DIR%\mount.conf" type nul > "%CORE_DIR%\mount.conf"
start notepad "%CORE_DIR%\mount.conf"
goto MOUNT_CONFIG

:INSTALL
cls
echo [INFO] Creating Desktop shortcut...
REM Update paths to point to CORE
set "VBS_PATH=%CORE_DIR%\start.vbs"
set "ICON_PATH=%CORE_DIR%\rclone.exe"
set "LINK_NAME=Rclone Tray"
REM WorkingDirectory set to CORE_DIR is crucial
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut([System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), '%LINK_NAME%.lnk')); $s.TargetPath = '%VBS_PATH%'; $s.WorkingDirectory = '%CORE_DIR%'; $s.IconLocation = '%ICON_PATH%, 0'; $s.Save()"
echo [SUCCESS] Shortcut created.
pause
goto MENU

:AUTOSTART
cls
echo [INFO] Adding to Startup folder...
set "VBS_PATH=%CORE_DIR%\start.vbs"
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
powershell -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut('%STARTUP_DIR%\Rclone_AutoStart.lnk'); $s.TargetPath = '%VBS_PATH%'; $s.Arguments = 'boot'; $s.WorkingDirectory = '%CORE_DIR%'; $s.IconLocation = '%CORE_DIR%\rclone.exe, 0'; $s.Save()"
echo [SUCCESS] Added to startup.
pause
goto MENU