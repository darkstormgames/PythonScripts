REM filepath: p:\Active\GFN_Python\toggle-python-venv.bat
@echo off
setlocal enabledelayedexpansion

REM Toggle (Enter/Exit) Python Virtual Environment
REM Usage: toggle-python-venv.bat [venv_name]

set "VenvName=%~1"

REM Check if we're currently in a virtual environment
if defined VIRTUAL_ENV (
    echo Currently in virtual environment: %VIRTUAL_ENV%
    set /p "ExitVenv=Do you want to deactivate it? (Y/n): "
    if /i "!ExitVenv!" neq "n" (
        echo Deactivating virtual environment...
        REM Call deactivate in the parent shell context
        endlocal
        call deactivate
        echo Virtual environment deactivated.
        pause
        exit /b 0
    )
)

REM Find all virtual environments in current directory
set "VenvCount=0"
set "TempFile=%TEMP%\venv_list_%RANDOM%.tmp"

for /d %%d in (*) do (
    if exist "%%d\Scripts\activate.bat" (
        set /a VenvCount+=1
        echo %%d >> "!TempFile!"
        set "VenvPath[!VenvCount!]=%%d"
    )
)

REM Handle no venvs found
if %VenvCount%==0 (
    echo No virtual environments found in current directory!
    echo To create one, run: create-python-venv.bat
    pause
    exit /b 1
)

REM If VenvName not provided and venvs exist, let user select
if "%VenvName%"=="" (
    if %VenvCount%==1 (
        set "VenvName=!VenvPath[1]!"
        echo Found virtual environment: !VenvName!
    ) else (
        echo Multiple virtual environments found:
        echo.
        for /l %%i in (1,1,%VenvCount%) do (
            echo   %%i. !VenvPath[%%i]!
        )
        echo.
        :SelectVenv
        set /p "Selection=Select virtual environment (1-%VenvCount%): "
        
        REM Validate selection is a number
        set "ValidSelection=0"
        for /l %%i in (1,1,%VenvCount%) do (
            if "!Selection!"=="%%i" set "ValidSelection=1"
        )
        
        if "!ValidSelection!"=="0" (
            echo Invalid selection. Please try again.
            goto SelectVenv
        )
        
        set "VenvName=!VenvPath[%Selection%]!"
    )
)

REM Clean up temp file
if exist "!TempFile!" del "!TempFile!"

REM Check if specified virtual environment exists
if not exist "%VenvName%" (
    echo Virtual environment '%VenvName%' not found!
    echo.
    echo Available virtual environments:
    for /d %%d in (*) do (
        if exist "%%d\Scripts\activate.bat" (
            echo   - %%d
        )
    )
    pause
    exit /b 1
)

REM Check if activation script exists - Fixed: removed extra space
if not exist "%VenvName%\Scripts\activate.bat" (
    echo Activation script not found at: %VenvName%\Scripts\activate.bat
    echo This doesn't appear to be a valid Python virtual environment.
    pause
    exit /b 1
)

REM Activate virtual environment
echo.
echo Activating virtual environment '%VenvName%'...
REM Use cmd /k to keep the window open with venv activated
cmd /k "%VenvName%\Scripts\activate.bat"
exit /b 0

pause