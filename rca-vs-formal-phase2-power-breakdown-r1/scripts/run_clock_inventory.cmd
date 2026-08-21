@echo off
setlocal
call "C:\AMDDesignTools\2025.2\Vivado\settings64.bat"
call "C:\AMDDesignTools\2025.2\Vivado\bin\vivado.bat" -mode batch -notrace -nojournal -nolog -source "%~1" -tclargs "%~2" "%~3" "%~4" "%~5"
exit /b %ERRORLEVEL%
