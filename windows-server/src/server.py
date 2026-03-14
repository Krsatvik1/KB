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

    def _on_pin_generated(self, pin: str, client_ip: str):
        print(f"New device from {client_ip} — Pairing PIN: {pin}")
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

    def handle_client(self, conn, addr):
        print(f"Connection from {addr[0]}")
        try:
            # ── Pairing check ─────────────────────────────────────────────────
            if not self.pairing.is_paired(addr):
                pin = self.pairing.start_pairing(addr)
                # Tell client it must authenticate
                self._send_json(conn, {**MSG_AUTH_REQUIRED, "hint": "Enter PIN shown on Windows"})
                # Wait for auth packet
                auth_pkt = self._read_packet(conn)
                if not auth_pkt or auth_pkt.get("t") != "auth" or not self.pairing.verify_pin(addr, str(auth_pkt.get("pin", ""))):
                    self._send_json(conn, MSG_AUTH_FAIL)
                    print(f"Auth failed from {addr[0]}")
                    return
                self._send_json(conn, MSG_AUTH_OK)
                if self.tray:
                    self.tray.pairing_complete()
                print(f"Paired: {addr[0]}")
            else:
                self.pairing.touch_device(addr)

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
                else:
                    self.injector.dispatch(event)

        except Exception as e:
            print(f"Client error: {e}")
        finally:
            print(f"Disconnected: {addr[0]}")
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
