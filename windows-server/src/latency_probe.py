import json

class LatencyProbe:
    def handle_ping(self, event, send_func):
        """Immediately respond to ping with pong to measure RTT."""
        if event.get("t") == "ping":
            ts = event.get("ts")
            pong = {
                "t": "pong",
                "ts": ts
            }
            # Encode response
            payload = json.dumps(pong).encode("utf-8")
            # 2 byte header
            length_bytes = len(payload).to_bytes(2, byteorder='big')
            try:
                send_func(length_bytes + payload)
            except Exception as e:
                print(f"Error sending pong: {e}")
