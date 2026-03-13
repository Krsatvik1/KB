@echo off
echo Installing dependencies...
pip install pyinstaller pywin32
if %errorlevel% neq 0 exit /b %errorlevel%

echo Building KBFlowServer...
pyinstaller --onefile --noconsole --name KBFlowServer src/main.py
if %errorlevel% neq 0 exit /b %errorlevel%

echo Build complete! Output is in dist\KBFlowServer.exe
pause
