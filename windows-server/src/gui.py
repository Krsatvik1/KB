import tkinter as tk
from tkinter import ttk, messagebox
import threading
import os

class FlowDeskGUI:
    def __init__(self, server, tray, app_version):
        self.server = server
        self.tray = tray
        self.app_version = app_version
        self.root = None
        self._is_running = False
        
        # Placeholders for thread safety
        self.status_var = None
        self.client_var = None

    def show(self):
        if self._is_running:
            if self.root:
                self.root.lift()
            return
        
        threading.Thread(target=self._run, daemon=True).start()

    def _run(self):
        self._is_running = True
        self.root = tk.Tk()
        self.root.title(f"FlowDesk Settings — v{self.app_version}")
        self.root.geometry("400x500")
        self.root.configure(bg="#0B0F1A")
        self.root.resizable(False, False)

        # Style
        style = ttk.Style()
        style.theme_use('clam')
        style.configure("TFrame", background="#0B0F1A")
        style.configure("TLabel", background="#0B0F1A", foreground="#E8EAF6", font=("Segoe UI", 10))
        style.configure("Header.TLabel", font=("Segoe UI", 14, "bold"), foreground="#00D4FF")
        style.configure("TButton", background="#111827", foreground="#E8EAF6", borderwidth=0)
        
        main_frame = ttk.Frame(self.root, padding="20")
        main_frame.pack(fill=tk.BOTH, expand=True)

        # Header
        ttk.Label(main_frame, text="FlowDesk Server", style="Header.TLabel").pack(pady=(0, 20))

        # Status Group
        status_frame = ttk.LabelFrame(main_frame, text=" Status ", padding="10")
        status_frame.pack(fill=tk.X, pady=10)
        
        self.status_var = tk.StringVar(value="Waiting for connection...")
        ttk.Label(status_frame, textvariable=self.status_var).pack(anchor=tk.W)

        self.client_var = tk.StringVar(value="Client: None")
        ttk.Label(status_frame, textvariable=self.client_var).pack(anchor=tk.W)

        # Settings
        settings_frame = ttk.LabelFrame(main_frame, text=" Security ", padding="10")
        settings_frame.pack(fill=tk.X, pady=10)

        def clear_paired():
            if messagebox.askyesno("Confirm", "Forget all paired devices? Clients will need to re-enter PIN."):
                if hasattr(self.server, 'pairing_manager'):
                    self.server.pairing_manager.forget_all()
                    messagebox.showinfo("Success", "All devices forgotten.")

        ttk.Button(settings_frame, text="Forget All Devices", command=clear_paired).pack(fill=tk.X)

        # Footer
        footer_frame = ttk.Frame(main_frame)
        footer_frame.pack(side=tk.BOTTOM, fill=tk.X, pady=(20, 0))
        
        ttk.Label(footer_frame, text=f"Version {self.app_version}", foreground="#6B7280", font=("Segoe UI", 8)).pack(side=tk.LEFT)
        
        def on_close():
            self._is_running = False
            self.root.destroy()
            self.root = None

        self.root.protocol("WM_DELETE_WINDOW", on_close)
        
        # Periodic update
        self._update_loop()
        
        self.root.mainloop()

    def _update_loop(self):
        if not self._is_running or not self.root:
            return
        
        # Pull status from server/tray
        if self.status_var and self.client_var:
            if self.server.client_socket:
                self.status_var.set("● Connected")
                self.client_var.set(f"Client: {self.server.client_address[0]}")
            else:
                self.status_var.set("Waiting for connection...")
                self.client_var.set("Client: None")
            
        if self.root:
            self.root.after(1000, self._update_loop)
