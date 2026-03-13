import ctypes
from ctypes import wintypes
import time

# --- CTYPES STRUCTURES FOR WIN32 SENDINPUT ---
# See https://docs.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-sendinput

PUL = ctypes.POINTER(ctypes.c_ulong)

class KeyBdInput(ctypes.Structure):
    _fields_ = [("wVk", wintypes.WORD),
                ("wScan", wintypes.WORD),
                ("dwFlags", wintypes.DWORD),
                ("time", wintypes.DWORD),
                ("dwExtraInfo", PUL)]

class HardwareInput(ctypes.Structure):
    _fields_ = [("uMsg", wintypes.DWORD),
                ("wParamL", wintypes.WORD),
                ("wParamH", wintypes.WORD)]

class MouseInput(ctypes.Structure):
    _fields_ = [("dx", wintypes.LONG),
                ("dy", wintypes.LONG),
                ("mouseData", wintypes.DWORD),
                ("dwFlags", wintypes.DWORD),
                ("time", wintypes.DWORD),
                ("dwExtraInfo", PUL)]

class Input_I(ctypes.Union):
    _fields_ = [("ki", KeyBdInput),
                ("mi", MouseInput),
                ("hi", HardwareInput)]

class Input(ctypes.Structure):
    _fields_ = [("type", wintypes.DWORD),
                ("ii", Input_I)]

# Constants
INPUT_MOUSE = 0
INPUT_KEYBOARD = 1
INPUT_HARDWARE = 2

KEYEVENTF_EXTENDEDKEY = 0x0001
KEYEVENTF_KEYUP = 0x0002
KEYEVENTF_SCANCODE = 0x0008
KEYEVENTF_UNICODE = 0x0004

MOUSEEVENTF_MOVE = 0x0001
MOUSEEVENTF_LEFTDOWN = 0x0002
MOUSEEVENTF_LEFTUP = 0x0004
MOUSEEVENTF_RIGHTDOWN = 0x0008
MOUSEEVENTF_RIGHTUP = 0x0010
MOUSEEVENTF_MIDDLEDOWN = 0x0020
MOUSEEVENTF_MIDDLEUP = 0x0040
MOUSEEVENTF_WHEEL = 0x0800
MOUSEEVENTF_HWHEEL = 0x01000

class InputInjector:
    def __init__(self):
        self.SendInput = ctypes.windll.user32.SendInput

    def dispatch(self, event):
        """Dispatches a single event from the parsed JSON packet."""
        t = event.get("t")
        
        if t == "k":
            # Keyboard event
            vk = event.get("vk", 0)
            flags = event.get("flags", 1) # 1 = keydown, 0 = keyup
            
            dwFlags = 0
            if flags == 0:
                dwFlags |= KEYEVENTF_KEYUP
                
            self._send_keyboard(vk, dwFlags)
            
        elif t == "m":
            # Mouse move event
            dx = event.get("dx", 0)
            dy = event.get("dy", 0)
            self._send_mouse_move(dx, dy)
            
        elif t == "b":
            # Mouse button event
            btn = event.get("btn", 0) # 0=left, 1=right, 2=middle
            state = event.get("state", 1) # 1=down, 0=up
            self._send_mouse_button(btn, state)
            
        elif t == "s":
            # Mouse scroll event
            dx = event.get("dx", 0)
            dy = event.get("dy", 0)
            self._send_mouse_scroll(dx, dy)

    def _send_keyboard(self, vk, dwFlags):
        extra = ctypes.c_ulong(0)
        ii_ = Input_I()
        ii_.ki = KeyBdInput(vk, 0, dwFlags, 0, ctypes.pointer(extra))
        x = Input(wintypes.DWORD(INPUT_KEYBOARD), ii_)
        self.SendInput(1, ctypes.pointer(x), ctypes.sizeof(x))

    def _send_mouse_move(self, dx, dy):
        extra = ctypes.c_ulong(0)
        ii_ = Input_I()
        ii_.mi = MouseInput(dx, dy, 0, MOUSEEVENTF_MOVE, 0, ctypes.pointer(extra))
        x = Input(wintypes.DWORD(INPUT_MOUSE), ii_)
        self.SendInput(1, ctypes.pointer(x), ctypes.sizeof(x))

    def _send_mouse_button(self, btn, state):
        dwFlags = 0
        if btn == 0: # Left
            dwFlags = MOUSEEVENTF_LEFTDOWN if state == 1 else MOUSEEVENTF_LEFTUP
        elif btn == 1: # Right
            dwFlags = MOUSEEVENTF_RIGHTDOWN if state == 1 else MOUSEEVENTF_RIGHTUP
        elif btn == 2: # Middle
            dwFlags = MOUSEEVENTF_MIDDLEDOWN if state == 1 else MOUSEEVENTF_MIDDLEUP
            
        extra = ctypes.c_ulong(0)
        ii_ = Input_I()
        ii_.mi = MouseInput(0, 0, 0, dwFlags, 0, ctypes.pointer(extra))
        x = Input(wintypes.DWORD(INPUT_MOUSE), ii_)
        self.SendInput(1, ctypes.pointer(x), ctypes.sizeof(x))
        
    def _send_mouse_scroll(self, dx, dy):
        # WHEEL_DELTA = 120
        # For our protocol, dy can be mapped directly * 120 or the client can send pre-multiplied values. 
        # Typically the client just sends lines/ticks, so we map here if needed.
        # Let's assume the client sends arbitrary deltas, e.g., macOS sends unscaled pixel-ish deltas
        # Adjust scale as needed based on macOS client feel.
        scale = 10
        
        extra = ctypes.c_ulong(0)
        ii_ = Input_I()
        if dy != 0:
            ii_.mi = MouseInput(0, 0, dy * scale, MOUSEEVENTF_WHEEL, 0, ctypes.pointer(extra))
            x = Input(wintypes.DWORD(INPUT_MOUSE), ii_)
            self.SendInput(1, ctypes.pointer(x), ctypes.sizeof(x))
            
        if dx != 0:
            ii_.mi = MouseInput(0, 0, dx * scale, MOUSEEVENTF_HWHEEL, 0, ctypes.pointer(extra))
            x = Input(wintypes.DWORD(INPUT_MOUSE), ii_)
            self.SendInput(1, ctypes.pointer(x), ctypes.sizeof(x))
