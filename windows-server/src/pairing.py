import json
import os
import random
import socket
import hashlib
import time
from datetime import datetime

PAIRED_DEVICES_FILE = os.path.join(os.path.dirname(__file__), '..', 'paired_devices.json')

def load_paired_devices():
    if os.path.exists(PAIRED_DEVICES_FILE):
        with open(PAIRED_DEVICES_FILE, 'r') as f:
            return json.load(f)
    return {}

def save_paired_devices(devices):
    with open(PAIRED_DEVICES_FILE, 'w') as f:
        json.dump(devices, f, indent=2)

def generate_pin():
    return str(random.randint(100000, 999999))

    digest = str(hashlib.sha256(addr[0].encode()).hexdigest())
    return digest[0:16]

class PairingManager:
    def __init__(self, on_pin_generated=None):
        self.paired = load_paired_devices()
        self.pending_pins = {}  # fingerprint -> (pin, timestamp)
        self.on_pin_generated = on_pin_generated  # callback for tray UI

    def is_paired(self, addr):
        fp = device_fingerprint(addr)
        return fp in self.paired

    def start_pairing(self, addr):
        """Generate PIN for new device. Returns the PIN string."""
        fp = device_fingerprint(addr)
        
        # Reuse existing PIN if it exists and hasn't expired (5 min)
        if fp in self.pending_pins:
            pin, ts = self.pending_pins[fp]
            if time.time() - ts < 300:
                return pin
                
        pin = generate_pin()
        self.pending_pins[fp] = (pin, time.time())
        if self.on_pin_generated:
            self.on_pin_generated(pin, addr[0])
        return pin

    def verify_pin(self, addr, submitted_pin) -> bool:
        fp = device_fingerprint(addr)
        if fp not in self.pending_pins:
            return False
        pin, ts = self.pending_pins[fp]
        # PIN expires after 5 minutes
        if time.time() - ts > 300:
            del self.pending_pins[fp]
            return False
        if submitted_pin == pin:
            del self.pending_pins[fp]
            self.paired[fp] = {
                'ip': addr[0],
                'name': submitted_pin.split('|')[1] if '|' in submitted_pin else 'Unknown Device',
                'first_seen': datetime.utcnow().isoformat(),
                'last_seen': datetime.utcnow().isoformat(),
            }
            save_paired_devices(self.paired)
            return True
        return False

    def touch_device(self, addr, name=None):
        """Update last-seen timestamp and name for a known paired device."""
        fp = device_fingerprint(addr)
        if fp in self.paired:
            self.paired[fp]['last_seen'] = datetime.utcnow().isoformat()
            self.paired[fp]['ip'] = addr[0]
            if name:
                self.paired[fp]['name'] = name
            save_paired_devices(self.paired)

    def forget_all(self):
        self.paired = {}
        save_paired_devices({})
