import socket
import json
import threading

from input_injector import InputInjector
from latency_probe import LatencyProbe
from pairing import PairingManager

# Pairing handshake message types
MSG_AUTH_REQUIRED = {"t": "auth_required"}
MSG_AUTH_OK = {"t": "auth_ok"}
MSG_AUTH_FAIL = {"t": "auth_fail"}

class KBFlowServer:
    def __init__(self, host='0.0.0.0', port=5123, tray=None, app_version="1.0.0"):
        self.host = host
        self.port = port
        self.injector = InputInjector()
        self.probe = LatencyProbe()
        self.tray = tray
        self.app_version = app_version
        self.running = False
        self.pairing = PairingManager(on_pin_generated=self._on_pin_generated)
        
        # Connection status for GUI/monitoring
        self.client_socket = None
        self.client_address = None
        self.client_name = None
        self.current_pin = None

    def _on_pin_generated(self, pin: str, client_ip: str):
        print(f"New device from {client_ip} — Pairing PIN: {pin}")
        self.current_pin = pin
        if self.tray:
            self.tray.notify_pairing(pin, client_ip)

    def start(self):
        self.running = True
        self.server_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        self.server_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_sock.bind((self.host, self.port))
        self.server_sock.listen(5)
        print(f"FlowDesk listening on {self.host}:{self.port}...")

        while self.running:
            try:
                conn, addr = self.server_sock.accept()
                conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
                t = threading.Thread(target=self.handle_client, args=(conn, addr), daemon=True)
                t.start()
            except Exception as e:
                if self.running:
                    print(f"Accept error: {e}")

    def _handle_clipboard_sync(self, conn):
        import win32clipboard # Included in pywin32
        try:
            win32clipboard.OpenClipboard()
            data = None
            if win32clipboard.IsClipboardFormatAvailable(win32clipboard.CF_UNICODETEXT):
                data = win32clipboard.GetClipboardData(win32clipboard.CF_UNICODETEXT)
                self._send_json(conn, {"t": "clip_sync_resp", "type": "text", "data": data})
            elif win32clipboard.IsClipboardFormatAvailable(win32clipboard.CF_DIB):
                # For images, we just signal it's too complex for now or send a stub
                # In a full impl, we'd convert DIB to PNG bytes
                self._send_json(conn, {"t": "clip_sync_resp", "type": "error", "msg": "Image sync coming soon"})
            else:
                self._send_json(conn, {"t": "clip_sync_resp", "type": "empty"})
            win32clipboard.CloseClipboard()
        except Exception as e:
            print(f"Clipboard error: {e}")
            self._send_json(conn, {"t": "clip_sync_resp", "type": "error", "msg": str(e)})

    def handle_client(self, conn, addr):
        print(f"Connection from {addr[0]}")
        try:
            # ── Initial Handshake ─────────────────────────────────────────────
            # Wait for client to identify itself
            auth_pkt = self._read_packet(conn)
            if not auth_pkt:
                print(f"Client {addr[0]} disconnected before identification.")
                return

            if not self.pairing.is_paired(addr):
                # ── Pairing Flow ──────────────────────────────────────────────
                # If pairing required, tell client and wait for PIN
                self.current_pin = self.pairing.start_pairing(addr)
                self._send_json(conn, {"t": "auth_required"})
                
                # Wait for second packet containing PIN
                auth_pkt = self._read_packet(conn)
                if not auth_pkt or not self.pairing.verify_pin(addr, f"{auth_pkt.get('pin', '')}|{auth_pkt.get('name', 'Mac')}"):
                    self._send_json(conn, {"t": "auth_fail", "reason": "Incorrect PIN or pairing failed."})
                    print(f"Auth failed from {addr[0]} - Incorrect PIN.")
                    return
                
                # Pairing successful
                self._send_json(conn, {
                    "t": "auth_ok",
                    "name": self.tray.server_name if self.tray else "Windows PC"
                })
                self.current_pin = None
                self.client_name = auth_pkt.get('name', 'Mac')
                if self.tray: self.tray.pairing_complete()
                print(f"Paired: {self.client_name} ({addr[0]})")
            else:
                # ── Already Paired Flow ───────────────────────────────────────
                # Check for name conflicts even for paired devices
                name = auth_pkt.get('name', 'Mac')
                fingerprint = self.pairing.device_fingerprint(addr)
                
                # Verify name uniqueness
                for fid, d in self.pairing.paired.items():
                    if d.get('name') == name and fid != fingerprint:
                        self._send_json(conn, {
                            "t": "auth_fail",
                            "reason": f"Name '{name}' is already taken. Please choose a unique name on your device."
                        })
                        return

                self.client_name = name
                self.pairing.touch_device(addr, self.client_name)
                self._send_json(conn, {
                    "t": "auth_ok",
                    "name": self.tray.server_name if self.tray else "Windows PC"
                })
                print(f"Reconnected: {self.client_name} ({addr[0]})")

            if self.tray:
                self.tray.update_connection(addr[0])

            # Update server state for GUI
            self.client_socket = conn
            self.client_address = addr

            # ── Main event loop ───────────────────────────────────────────────
            while self.running:
                event = self._read_packet(conn)
                if not event:
                    break
                t = event.get("t")
                if t == "ping":
                    self.probe.handle_ping(event, lambda d: self._send_raw(conn, d))
                    if self.tray:
                        self.tray.update_connection(addr[0], event.get("ts", 0))
                elif t == "clip_sync_req":
                    self._handle_clipboard_sync(conn)
                else:
                    self.injector.dispatch(event)

        except Exception as e:
            print(f"Client error: {e}")
        finally:
            print(f"Disconnected: {addr[0]}")
            self.current_pin = None 
            if self.client_socket == conn:
                self.client_socket = None
                self.client_address = None
            if self.tray:
                self.tray.update_disconnected()
            conn.close()

    def _read_packet(self, conn):
        header = self._recv_exactly(conn, 2)
        if not header:
            return None
        length = int.from_bytes(header, 'big')
        payload = self._recv_exactly(conn, length)
        if not payload:
            return None
        return json.loads(payload.decode('utf-8'))

    def _send_json(self, conn, obj: dict):
        raw = json.dumps(obj).encode('utf-8')
        self._send_raw(conn, raw)

    def _send_raw(self, conn, raw: bytes):
        header = len(raw).to_bytes(2, 'big')
        conn.sendall(header + raw)

    def _recv_exactly(self, conn, n):
        data = bytearray()
        while len(data) < n:
            chunk = conn.recv(n - len(data))
            if not chunk:
                return None
            data.extend(chunk)
        return data

    def stop(self):
        self.running = False
        if hasattr(self, 'server_sock'):
            try:
                self.server_sock.close()
            except Exception:
                pass
