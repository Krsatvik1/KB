import threading
import json
import os

try:
    import pystray
    from pystray import MenuItem as item
    from PIL import Image
    TRAY_AVAILABLE = True
except ImportError:
    TRAY_AVAILABLE = False

ICON_PATH = os.path.join(os.path.dirname(__file__), 'icon.ico')

class TrayApp:
    def __init__(self, on_quit=None, on_check_updates=None, on_show_settings=None):
        self.on_quit = on_quit
        self.on_check_updates = on_check_updates
        self.on_show_settings = on_show_settings
        self._icon = None
        self._status = "Waiting for connection..."
        self._client_info = "No client"
        self._latency = "--"
        self._pending_pin = None

    def _build_menu(self):
        items = [
            item(f"FlowDesk Server", None, enabled=False),
            pystray.Menu.SEPARATOR,
            item(lambda _: f"● {self._status}", None, enabled=False),
            item(lambda _: f"Client: {self._client_info}", None, enabled=False),
            item(lambda _: f"Latency: {self._latency}", None, enabled=False),
            pystray.Menu.SEPARATOR,
            item("Show Settings", lambda _: self.on_show_settings() if self.on_show_settings else None),
        ]
        if self._pending_pin:
            items += [
                pystray.Menu.SEPARATOR,
                item(f"🔐 Pairing PIN: {self._pending_pin}", None, enabled=False),
            ]
        items += [
            pystray.Menu.SEPARATOR,
            item("Check for Updates", lambda _: self.on_check_updates() if self.on_check_updates else None),
            item("Quit FlowDesk", lambda _: self._quit()),
        ]
        return pystray.Menu(*items)

    def _quit(self):
        if self._icon:
            self._icon.stop()
        if self.on_quit:
            self.on_quit()

    def start(self):
        if not TRAY_AVAILABLE:
            print("pystray not available — running headless")
            return
        try:
            img = Image.open(ICON_PATH).convert("RGBA")
        except Exception:
            img = Image.new('RGBA', (64, 64), color=(0, 0, 0, 0))
            # Draw a simple circle if icon fails
            from PIL import ImageDraw
            draw = ImageDraw.Draw(img)
            draw.ellipse([10, 10, 54, 54], fill=(0, 212, 255))

        self._icon = pystray.Icon(
            "FlowDesk",
            img,
            "FlowDesk Server",
            menu=self._build_menu()
        )
        threading.Thread(target=self._icon.run, daemon=True).start()

    def notify_pairing(self, pin: str, client_ip: str):
        self._pending_pin = pin
        self._status = f"Pairing with {client_ip}..."
        self._refresh_menu()
        # Windows toast notification
        try:
            from plyer import notification
            notification.notify(
                title="FlowDesk — New Device",
                message=f"PIN: {pin}\nEnter this on your Mac to pair.",
                app_name="FlowDesk",
                timeout=30
            )
        except Exception:
            pass

    def pairing_complete(self):
        self._pending_pin = None
        self._refresh_menu()

    def update_connection(self, client_ip: str, latency_ms: int = None):
        self._status = f"Connected"
        self._client_info = client_ip
        self._latency = f"{latency_ms}ms" if latency_ms else "--"
        self._refresh_menu()

    def update_disconnected(self):
        self._status = "Waiting for connection..."
        self._client_info = "No client"
        self._latency = "--"
        self._refresh_menu()

    def _refresh_menu(self):
        if self._icon:
            self._icon.menu = self._build_menu()
            self._icon.update_menu()
