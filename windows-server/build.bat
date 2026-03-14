@echo off
echo Installing FlowDesk dependencies...
pip install pyinstaller pywin32 pystray Pillow plyer
if %errorlevel% neq 0 exit /b %errorlevel%

echo Building FlowDesk Server...
pyinstaller --onefile --noconsole --name FlowDeskServer --icon="../assets/icons/icon.ico" src/main.py
if %errorlevel% neq 0 exit /b %errorlevel%

echo Build complete! Output is in dist\FlowDeskServer.exe
