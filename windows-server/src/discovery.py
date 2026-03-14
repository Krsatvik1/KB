import socket
import json
import threading
import time

BEACON_PORT = 5124
BEACON_INTERVAL = 2  # seconds

class DiscoveryBeacon:
    """Broadcasts a UDP beacon so Mac clients can auto-discover the server."""
    def __init__(self, server_port=5123, app_version="1.0.0"):
        self.server_port = server_port
        self.app_version = app_version
        self._running = False
        self._thread = None

    def start(self):
        self._running = True
        self._thread = threading.Thread(target=self._broadcast_loop, daemon=True)
        self._thread.start()
        print(f"Discovery beacon started on UDP port {BEACON_PORT}")

    def stop(self):
        self._running = False

    def _broadcast_loop(self):
        sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_BROADCAST, 1)
        sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        payload = json.dumps({
            "name": "FlowDesk",
            "port": self.server_port,
            "version": self.app_version
        }).encode('utf-8')
        while self._running:
            try:
                sock.sendto(payload, ('<broadcast>', BEACON_PORT))
            except Exception as e:
                print(f"Beacon error: {e}")
            time.sleep(BEACON_INTERVAL)
        sock.close()
