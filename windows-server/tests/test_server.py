import sys
import unittest
import json
import threading
import time
import socket

# Mock Windows ctypes for testing on Mac
import ctypes
class MockWinTypes:
    WORD = ctypes.c_uint16
    DWORD = ctypes.c_uint32
    LONG = ctypes.c_int32

class MockUser32:
    def SendInput(self, *args):
        return 1

class MockWinDLL:
    user32 = MockUser32()

if sys.platform != "win32":
    sys.modules['ctypes.wintypes'] = MockWinTypes
    ctypes.wintypes = MockWinTypes
    ctypes.windll = MockWinDLL()

import os
sys.path.append(os.path.join(os.path.dirname(__file__), '..', 'src'))

from server import KBFlowServer
from latency_probe import LatencyProbe
from input_injector import InputInjector

class TestKBFlowServer(unittest.TestCase):
    def test_latency_probe(self):
        probe = LatencyProbe()
        sent_data = []
        def mock_send(data):
            sent_data.append(data)
            
        event = {"t": "ping", "ts": 12345}
        probe.handle_ping(event, mock_send)
        
        self.assertEqual(len(sent_data), 1)
        payload = sent_data[0]
        # First 2 bytes are length
        length = int.from_bytes(payload[:2], byteorder='big')
        body = json.loads(payload[2:].decode('utf-8'))
        
        self.assertEqual(length, len(payload) - 2)
        self.assertEqual(body["t"], "pong")
        self.assertEqual(body["ts"], 12345)

    def test_input_injector(self):
        injector = InputInjector()
        # Mock the SendInput method to track calls
        calls = []
        def mock_send_input(*args):
            calls.append(args)
            return 1
        injector.SendInput = mock_send_input
        
        # Test Key
        injector.dispatch({"t": "k", "vk": 65, "flags": 1})
        self.assertEqual(len(calls), 1)
        
        # Test Mouse Move
        injector.dispatch({"t": "m", "dx": 10, "dy": -5})
        self.assertEqual(len(calls), 2)
        
        # Test Mouse Click
        injector.dispatch({"t": "b", "btn": 0, "state": 1})
        self.assertEqual(len(calls), 3)

    def test_full_server_ping_pong(self):
        server = KBFlowServer(host='127.0.0.1', port=5124) # Use different port for test
        
        # Start server in thread
        t = threading.Thread(target=server.start)
        t.daemon = True
        t.start()
        time.sleep(0.5) # Wait for server to bind
        
        try:
            # Connect as client
            client = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            client.connect(('127.0.0.1', 5124))
            
            # Send ping
            ping = json.dumps({"t": "ping", "ts": 111}).encode('utf-8')
            client.sendall(len(ping).to_bytes(2, byteorder='big') + ping)
            
            # Read header
            header = client.recv(2)
            length = int.from_bytes(header, byteorder='big')
            
            # Read body
            body = client.recv(length)
            response = json.loads(body.decode('utf-8'))
            
            self.assertEqual(response["t"], "pong")
            self.assertEqual(response["ts"], 111)
            
            client.close()
            
        finally:
            server.stop()
            t.join(timeout=1.0)

if __name__ == '__main__':
    unittest.main()
