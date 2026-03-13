import socket
import json
import threading

from input_injector import InputInjector
from latency_probe import LatencyProbe

class KBFlowServer:
    def __init__(self, host='0.0.0.0', port=5123):
        self.host = host
        self.port = port
        self.injector = InputInjector()
        self.probe = LatencyProbe()
        self.running = False

    def start(self):
        self.running = True
        self.server_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        # Allow port reuse
        self.server_sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.server_sock.bind((self.host, self.port))
        self.server_sock.listen(1)
        print(f"Listening on {self.host}:{self.port}...")

        while self.running:
            try:
                conn, addr = self.server_sock.accept()
                print(f"Connected by {addr}")
                # Set TCP_NODELAY for lowest latency
                conn.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
                
                client_thread = threading.Thread(target=self.handle_client, args=(conn,))
                client_thread.daemon = True
                client_thread.start()
            except Exception as e:
                print(f"Accept error: {e}")
                if not self.running:
                    break

    def handle_client(self, conn):
        try:
            while self.running:
                # Read 2-byte length header (big-endian)
                header = self._recv_exactly(conn, 2)
                if not header:
                    break
                    
                payload_len = int.from_bytes(header, byteorder='big')
                
                # Read payload
                payload = self._recv_exactly(conn, payload_len)
                if not payload:
                    break
                    
                body = payload.decode('utf-8')
                event = json.loads(body)
                
                # Dispatch
                t = event.get("t")
                if t == "ping":
                    self.probe.handle_ping(event, conn.sendall)
                else:
                    self.injector.dispatch(event)

        except Exception as e:
            print(f"Client error: {e}")
        finally:
            print("Client disconnected.")
            conn.close()

    def _recv_exactly(self, conn, n):
        data = bytearray()
        while len(data) < n:
            packet = conn.recv(n - len(data))
            if not packet:
                return None
            data.extend(packet)
        return data

    def stop(self):
        self.running = False
        if hasattr(self, 'server_sock'):
            self.server_sock.close()
