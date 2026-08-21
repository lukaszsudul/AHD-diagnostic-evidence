@echo off
setlocal
if "%~5"=="" exit /b 64
call "C:\AMDDesignTools\2025.2\Vivado\settings64.bat"
if errorlevel 1 exit /b %errorlevel%
call "C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat" -mode batch -nojournal -log "%~5" -source "%~1" -tclargs "%~2" "%~3" "%~4" "%~6"
exit /b %errorlevel%
