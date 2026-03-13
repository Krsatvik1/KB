import sys
import os

# Adjust sys.path for relative imports to work when run directly
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from server import KBFlowServer

def main():
    try:
        print("Starting KBFlow Server...")
        server = KBFlowServer()
        server.start()
    except KeyboardInterrupt:
        print("Stopping server.")
    except Exception as e:
        print(f"Server error: {e}")
        input("Press Enter to exit...")

if __name__ == "__main__":
    main()
