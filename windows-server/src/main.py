"""
FlowDesk Windows Server — main entry point
Wires together: TCP server, tray UI, UDP discovery beacon, pairing, and updater.
"""
import sys
import os
import threading

sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from server import KBFlowServer
from tray import TrayApp
from discovery import DiscoveryBeacon
from updater import check_for_updates
from gui import FlowDeskGUI

APP_VERSION = "1.1.7"

def main():
    # Track quit event across threads
    stop_event = threading.Event()

    def on_quit():
        stop_event.set()

    def on_check_updates():
        result = check_for_updates(APP_VERSION)
        if result:
            try:
                from plyer import notification
                notification.notify(
                    title="FlowDesk Update Available",
                    message=f"Version {result['version']} available.\nVisit GitHub to download.",
                    app_name="FlowDesk",
                    timeout=10
                )
            except Exception:
                print(f"Update available: {result['version']} — {result['url']}")
        else:
            # Notify only on manual check
            try:
                from plyer import notification
                notification.notify(
                    title="FlowDesk",
                    message=f"You are running the latest version (v{APP_VERSION}).",
                    app_name="FlowDesk",
                    timeout=5
                )
            except Exception:
                pass

    # Start tray (runs in background thread; main thread keeps it alive)
    tray = TrayApp(on_quit=on_quit, on_check_updates=on_check_updates)
    tray.start()

    # Start UDP discovery beacon
    beacon = DiscoveryBeacon(server_port=5123, app_version=APP_VERSION)
    beacon.start()

    # Start TCP server in a background thread
    server = KBFlowServer(tray=tray, app_version=APP_VERSION)
    
    # Initialize GUI
    gui = FlowDeskGUI(server=server, tray=tray, app_version=APP_VERSION)
    tray.on_show_settings = gui.show

    server_thread = threading.Thread(target=server.start, daemon=True)
    server_thread.start()

    print(f"FlowDesk Server v{APP_VERSION} running. Check the system tray.")

    # Check for updates on startup (non-blocking)
    threading.Thread(target=on_check_updates, daemon=True).start()

    # Keep main thread alive until quit
    try:
        stop_event.wait()
    except KeyboardInterrupt:
        pass

    beacon.stop()
    server.stop()
    print("FlowDesk Server stopped.")

if __name__ == "__main__":
    main()
