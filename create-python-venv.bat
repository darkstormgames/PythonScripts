REM filepath: p:\Active\GFN_Python\create-python-venv.bat
@echo off
setlocal enabledelayedexpansion

REM Create Python Virtual Environment with Version Selector
REM Usage: create-python-venv.bat [venv_name]

set "VenvName=%~1"
if "%VenvName%"=="" set "VenvName=venv"

echo Searching for Python installations...
echo.

REM Initialize arrays
set "PythonCount=0"
set "TempFile=%TEMP%\python_versions_%RANDOM%.tmp"

REM Search for Python installations
for %%p in (
    "C:\Python*\python.exe"
    "C:\Program Files\Python*\python.exe"
    "C:\Program Files (x86)\Python*\python.exe"
    "%LOCALAPPDATA%\Programs\Python\Python*\python.exe"
    "%APPDATA%\Python\Python*\Scripts\python.exe"
    "C:\Python\Python*\python.exe"
    "C:\Python*\Python*\python.exe"
) do (
    for /f "delims=" %%i in ('dir /b /s "%%~p" 2^>nul') do (
        if exist "%%i" (
            REM Skip WindowsApps paths entirely
            echo %%i | findstr /C:"WindowsApps" >nul
            if !errorlevel! neq 0 (
                REM Skip virtual environment paths (check for pyvenv.cfg in parent directories)
                set "IsVenv=0"
                set "CheckPath=%%~dpi"
                
                REM Check if pyvenv.cfg exists in the same directory as python.exe
                if exist "!CheckPath!..\pyvenv.cfg" set "IsVenv=1"
                if exist "!CheckPath!..\..\pyvenv.cfg" set "IsVenv=1"
                
                REM Also skip if path contains common venv directory names
                echo %%i | findstr /I /C:"\venv\" /C:"\venv310\" /C:"\venv311\" /C:"\venv312\" /C:"\venv313\" /C:"\.venv\" /C:"\env\" /C:"\virtualenv\" >nul
                if !errorlevel!==0 set "IsVenv=1"
                
                if !IsVenv!==0 (
                    REM Get version info and validate it's actually Python
                    set "VersionString="
                    set "IsValidPython=0"
                    for /f "tokens=*" %%v in ('"%%i" --version 2^>^&1') do (
                        set "VersionString=%%v"
                        REM Check if output contains "Python" followed by version number
                        echo !VersionString! | findstr /R /C:"Python [0-9]\.[0-9][0-9]*\.[0-9]" >nul
                        if !errorlevel!==0 set "IsValidPython=1"
                    )
                    
                    if !IsValidPython!==1 (
                        REM Check if this path is already in our list
                        set "AlreadyAdded=0"
                        if exist "!TempFile!" (
                            findstr /C:"%%i" "!TempFile!" >nul 2>&1
                            if !errorlevel!==0 set "AlreadyAdded=1"
                        )
                        
                        if !AlreadyAdded!==0 (
                            set /a PythonCount+=1
                            echo !PythonCount!;%%i;!VersionString! >> "!TempFile!"
                        )
                    )
                )
            )
        )
    )
)

REM Check for python.exe and python3.exe in PATH
for %%c in (python.exe python3.exe) do (
    for /f "delims=" %%i in ('where %%c 2^>nul') do (
        if exist "%%i" (
            REM Skip WindowsApps Python launcher shortcuts
            echo %%i | findstr /C:"WindowsApps" >nul
            if !errorlevel! neq 0 (
                REM Skip virtual environments
                set "IsVenv=0"
                set "CheckPath=%%~dpi"
                
                if exist "!CheckPath!..\pyvenv.cfg" set "IsVenv=1"
                if exist "!CheckPath!..\..\pyvenv.cfg" set "IsVenv=1"
                
                echo %%i | findstr /I /C:"\venv\" /C:"\venv310\" /C:"\venv311\" /C:"\venv312\" /C:"\venv313\" /C:"\.venv\" /C:"\env\" /C:"\virtualenv\" >nul
                if !errorlevel!==0 set "IsVenv=1"
                
                if !IsVenv!==0 (
                    REM Get version info and validate
                    set "VersionString="
                    set "IsValidPython=0"
                    for /f "tokens=*" %%v in ('"%%i" --version 2^>^&1') do (
                        set "VersionString=%%v"
                        echo !VersionString! | findstr /R /C:"Python [0-9]\.[0-9][0-9]*\.[0-9]" >nul
                        if !errorlevel!==0 set "IsValidPython=1"
                    )
                    
                    if !IsValidPython!==1 (
                        REM Check if already in our list
                        set "AlreadyAdded=0"
                        if exist "!TempFile!" (
                            findstr /C:"%%i" "!TempFile!" >nul 2>&1
                            if !errorlevel!==0 set "AlreadyAdded=1"
                        )
                        
                        if !AlreadyAdded!==0 (
                            set /a PythonCount+=1
                            echo !PythonCount!;%%i;!VersionString! >> "!TempFile!"
                        )
                    )
                )
            )
        )
    )
)

REM Also check py launcher for available versions
where py >nul 2>&1
if %errorlevel%==0 (
    REM Get list of installed Python versions via py launcher
    for /f "tokens=1,2" %%a in ('py --list 2^>nul ^| findstr /R "^[ ]*-[0-9]"') do (
        set "PyVersion=%%a"
        set "PyVersion=!PyVersion:~1!"
        
        REM Try to find the actual python.exe for this version
        for /f "delims=" %%i in ('py -!PyVersion! -c "import sys; print(sys.executable)" 2^>nul') do (
            if exist "%%i" (
                REM Skip WindowsApps paths
                echo %%i | findstr /C:"WindowsApps" >nul
                if !errorlevel! neq 0 (
                    REM Skip virtual environments
                    set "IsVenv=0"
                    set "CheckPath=%%~dpi"
                    
                    if exist "!CheckPath!..\pyvenv.cfg" set "IsVenv=1"
                    if exist "!CheckPath!..\..\pyvenv.cfg" set "IsVenv=1"
                    
                    if !IsVenv!==0 (
                        REM Get full version string
                        set "VersionString="
                        for /f "tokens=*" %%v in ('"%%i" --version 2^>^&1') do set "VersionString=%%v"
                        
                        REM Check if already in our list
                        set "AlreadyAdded=0"
                        if exist "!TempFile!" (
                            findstr /C:"%%i" "!TempFile!" >nul 2>&1
                            if !errorlevel!==0 set "AlreadyAdded=1"
                        )
                        
                        if !AlreadyAdded!==0 (
                            set /a PythonCount+=1
                            echo !PythonCount!;%%i;!VersionString! >> "!TempFile!"
                        )
                    )
                )
            )
        )
    )
)

REM Manually check common Python 3.12 installation paths if not found
set "CheckPython312=0"
if exist "!TempFile!" (
    findstr /C:"3.12" "!TempFile!" >nul 2>&1
    if !errorlevel! neq 0 set "CheckPython312=1"
) else (
    set "CheckPython312=1"
)

if !CheckPython312!==1 (
    for %%p in (
        "C:\Python312\python.exe"
        "C:\Python\Python312\python.exe"
        "%LOCALAPPDATA%\Programs\Python\Python312\python.exe"
        "C:\Program Files\Python312\python.exe"
        "C:\Program Files (x86)\Python312\python.exe"
    ) do (
        if exist "%%~p" (
            set "VersionString="
            for /f "tokens=*" %%v in ('"%%~p" --version 2^>^&1') do set "VersionString=%%v"
            
            set "AlreadyAdded=0"
            if exist "!TempFile!" (
                findstr /C:"%%~p" "!TempFile!" >nul 2>&1
                if !errorlevel!==0 set "AlreadyAdded=1"
            )
            
            if !AlreadyAdded!==0 (
                set /a PythonCount+=1
                echo !PythonCount!;%%~p;!VersionString! >> "!TempFile!"
            )
        )
    )
)

if %PythonCount%==0 (
    echo No Python installations found!
    echo Please install Python from https://www.python.org/downloads/
    pause
    exit /b 1
)

REM Display available Python versions
echo Available Python versions:
echo.
for /f "tokens=1,2,3* delims=;" %%a in ('type "!TempFile!" 2^>nul') do (
    set "PythonPath[%%a]=%%b"
    set "PythonVersion[%%a]=%%c"
    echo   %%a. %%c
    echo      Path: %%b
    echo.
)

REM Get user selection
:SelectPython
set /p "Selection=Select Python version (1-%PythonCount%): "
if not defined PythonPath[%Selection%] (
    echo Invalid selection. Please try again.
    goto SelectPython
)

set "SelectedPython=!PythonPath[%Selection%]!"
set "SelectedVersion=!PythonVersion[%Selection%]!"

REM Clean up temp file
if exist "!TempFile!" del "!TempFile!"

REM Check if virtual environment already exists
if exist "%VenvName%" (
    echo.
    echo Virtual environment '%VenvName%' already exists!
    set /p "Overwrite=Do you want to overwrite it? (y/N): "
    if /i "!Overwrite!"=="y" (
        echo Removing existing virtual environment...
        rmdir /s /q "%VenvName%"
    ) else (
        echo Operation cancelled.
        pause
        exit /b 0
    )
)

REM Create virtual environment
echo.
echo Creating virtual environment '%VenvName%' with %SelectedVersion%...
"!SelectedPython!" -m venv "%VenvName%"

if %errorlevel%==0 (
    echo Virtual environment '%VenvName%' created successfully!
    echo.
    set /p "Activate=Do you want to activate the virtual environment now? (Y/n): "
    if /i "!Activate!" neq "n" (
        echo.
        echo Activating virtual environment '%VenvName%'...
        REM Check if the script runs in a new cmd instance
        if defined VIRTUAL_ENV (
            call "%VenvName%\Scripts\activate.bat"
        ) else (
            REM Use cmd /k to keep the window open with venv activated
            cmd /k "%VenvName%\Scripts\activate.bat"
        )
    ) else (
        echo.
        echo To activate it later, run: %VenvName%\Scripts\activate.bat
    )
) else (
    echo Failed to create virtual environment!
    pause
    exit /b 1
)

pause