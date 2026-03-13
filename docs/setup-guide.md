# KBFlow Setup Guide

## Windows Setup (Receiver)

1. **Download KBFlowServer.exe** from the GitHub Releases page.
2. **Copy** it to a convenient folder on your Windows PC.
3. **Allow port 5123** manually in Windows Firewall:
   - Open 'Windows Defender Firewall with Advanced Security'
   - Click 'Inbound Rules' -> 'New Rule...'
   - Select 'Port', choose TCP, and enter `5123`
   - Allow the connection and apply to all profiles. Name it "KBFlow".
4. **Double-click the .exe**. It runs in the background.
5. Find your IP address by opening Command Prompt and typing `ipconfig` (`IPv4 Address`).

## Mac Setup (Sender)

1. **Download KBFlow.app** from the GitHub Releases page.
2. Unzip and drag to Applications.
3. Open it. The first time, it will prompt for Accessibility permissions so it can intercept keystrokes without the Mac reacting.
   - Go to System Settings -> Privacy & Security -> Accessibility
   - Add/enable KBFlow.
4. Open the app again, type the Windows PC IP Address, and click Connect!
