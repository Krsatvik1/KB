import tkinter as tk
from tkinter import ttk, messagebox
import os

class FlowDeskGUI:
    def __init__(self, server, tray, app_version):
        self.server = server
        self.tray = tray
        self.app_version = app_version
        self.root = None
        
        # Colors & Fonts
        self.BG_COLOR = "#0B0F1A"
        self.HEADER_COLOR = "#111827"
        self.ACCENT_COLOR = "#00D4FF"
        self.SUBTEXT_COLOR = "#9CA3AF"
        self.TEXT_COLOR = "#F3F4F6"
        self.CARD_COLOR = "#1E293B"
        
        # Identity
        self.server_name_var = tk.StringVar(value=os.environ.get("COMPUTERNAME", "Windows Server"))
        
    def run(self):
        """Starts the GUI mainloop (should be called on main thread)"""
        self.root = tk.Tk()
        self.root.title(f"FlowDesk Settings")
        self.root.geometry("420x580")
        self.root.configure(bg=self.BG_COLOR)
        self.root.resizable(False, False)

        # Basic Style Configuration
        style = ttk.Style()
        style.theme_use('clam')
        style.configure("TFrame", background=self.BG_COLOR)
        style.configure("TLabel", background=self.BG_COLOR, foreground=self.TEXT_COLOR, font=("Segoe UI", 10))
        style.configure("Header.TLabel", font=("Segoe UI", 16, "bold"), foreground=self.ACCENT_COLOR)
        style.configure("Sub.TLabel", font=("Segoe UI", 9), foreground=self.SUBTEXT_COLOR)
        
        # Custom button style
        style.map("FlowDesk.TButton",
            background=[('active', self.ACCENT_COLOR), ('!active', self.HEADER_COLOR)],
            foreground=[('active', self.BG_COLOR), ('!active', self.TEXT_COLOR)]
        )
        style.configure("FlowDesk.TButton", borderwidth=0, font=("Segoe UI", 10, "bold"), padding=10)

        # Main Layout
        main_container = ttk.Frame(self.root, padding="30")
        main_container.pack(fill=tk.BOTH, expand=True)

        # ── Header ────────────────────────────────────────────────────────────
        header_frame = tk.Frame(main_container, bg=self.BG_COLOR)
        header_frame.pack(fill=tk.X, pady=(0, 24))
        
        # App Info
        top_info = tk.Frame(header_frame, bg=self.BG_COLOR)
        top_info.pack(side=tk.LEFT)
        tk.Label(top_info, text="FlowDesk", font=("Segoe UI", 20, "bold"), fg=self.ACCENT_COLOR, bg=self.BG_COLOR).pack(anchor=tk.W)
        
        self.ip_var = tk.StringVar(value="IP: Detect...ing")
        tk.Label(top_info, textvariable=self.ip_var, font=("Segoe UI Semibold", 9), fg=self.SUBTEXT_COLOR, bg=self.BG_COLOR).pack(anchor=tk.W)
        self._set_local_ip()

        # Version Badge
        v_frame = tk.Frame(header_frame, bg=self.CARD_COLOR, padx=8, pady=2)
        v_frame.pack(side=tk.RIGHT, pady=(10, 0))
        tk.Label(v_frame, text=f"v{self.app_version}", font=("Segoe UI Bold", 9), fg=self.ACCENT_COLOR, bg=self.CARD_COLOR).pack()

        # ── Setup Card ────────────────────────────────────────────────────────
        setup_card = tk.Frame(main_container, bg=self.CARD_COLOR, padx=16, pady=16)
        setup_card.pack(fill=tk.X, pady=(0, 20))
        
        tk.Label(setup_card, text="IDENTITY", font=("Segoe UI Bold", 10), fg=self.ACCENT_COLOR, bg=self.CARD_COLOR).pack(anchor=tk.W, pady=(0, 8))
        
        name_input_frame = tk.Frame(setup_card, bg=self.CARD_COLOR)
        name_input_frame.pack(fill=tk.X)
        
        self.name_entry = tk.Entry(name_input_frame, textvariable=self.server_name_var, bg="#0F172A", fg=self.TEXT_COLOR, 
                                  insertbackground=self.ACCENT_COLOR, font=("Segoe UI", 11), borderwidth=0)
        self.name_entry.pack(side=tk.LEFT, fill=tk.X, expand=True, ipady=8, padx=(0, 10))
        
        magic_btn = tk.Button(name_input_frame, text="✨", bg=self.HEADER_COLOR, fg=self.ACCENT_COLOR, relief="flat", 
                             command=self._generate_name, font=("Segoe UI", 12))
        magic_btn.pack(side=tk.RIGHT)

        # ── Connection Status ─────────────────────────────────────────────────
        self.status_card = tk.Frame(main_container, bg=self.CARD_COLOR, padx=16, pady=16)
        self.status_card.pack(fill=tk.X, pady=(0, 20))
        
        tk.Label(self.status_card, text="STATUS", font=("Segoe UI Bold", 10), fg=self.ACCENT_COLOR, bg=self.CARD_COLOR).pack(anchor=tk.W, pady=(0, 8))
        
        self.status_var = tk.StringVar(value="WAITING FOR CONNECTION")
        self.status_label = tk.Label(self.status_card, textvariable=self.status_var, bg=self.CARD_COLOR, fg=self.ACCENT_COLOR, font=("Segoe UI Semibold", 12))
        self.status_label.pack(anchor=tk.W)
        
        self.client_var = tk.StringVar(value="Broadcasting on local network...")
        tk.Label(self.status_card, textvariable=self.client_var, font=("Segoe UI", 9), fg=self.SUBTEXT_COLOR, bg=self.CARD_COLOR).pack(anchor=tk.W, pady=(4, 0))

        # ── Paired Card ───────────────────────────────────────────────────────
        paired_card = tk.Frame(main_container, bg=self.CARD_COLOR, padx=16, pady=16)
        paired_card.pack(fill=tk.X, pady=(0, 20))
        
        tk.Label(paired_card, text="TRUSTED DEVICES", font=("Segoe UI Bold", 10), fg=self.ACCENT_COLOR, bg=self.CARD_COLOR).pack(anchor=tk.W, pady=(0, 12))
        
        self.devices_frame = tk.Frame(paired_card, bg=self.CARD_COLOR)
        self.devices_frame.pack(fill=tk.X)
        
        # Action Buttons
        btn_frame = tk.Frame(paired_card, bg=self.CARD_COLOR)
        btn_frame.pack(fill=tk.X, pady=(12, 0))
        
        self.forget_btn = tk.Button(btn_frame, text="Forget All", bg=self.CARD_COLOR, fg="#FF4566", relief="flat",
                                   font=("Segoe UI Bold", 9), command=self._clear_paired)
        self.forget_btn.pack(side=tk.RIGHT)

        # ── Pairing Frame ────────────────────────────────────────────────────
        self.pairing_frame = tk.Frame(main_container, bg="#423E2A", highlightthickness=1, highlightbackground="#EAB308", padx=16, pady=16)
        
        tk.Label(self.pairing_frame, text="PAIRING REQUEST", font=("Segoe UI Bold", 9), foreground="#EAB308", background="#423E2A").pack(anchor=tk.W, pady=(0, 8))
        self.pin_var = tk.StringVar(value="000000")
        tk.Label(self.pairing_frame, textvariable=self.pin_var, bg="#423E2A", fg="#FFFFFF", font=("Segoe UI", 32, "bold")).pack(pady=4)
        tk.Label(self.pairing_frame, text="Enter PIN on your Mac", font=("Segoe UI", 9), fg="#EAB308", background="#423E2A").pack(pady=(0, 4))

        # ── Updates Section ───────────────────────────────────────────────────
        update_card = tk.Frame(main_container, bg=self.CARD_COLOR, padx=16, pady=12)
        update_card.pack(fill=tk.X, side=tk.BOTTOM, pady=(10, 0))
        
        # self.update_status_var = tk.StringVar(value="Checking...") # Moved to __init__
        tk.Label(update_card, text="UPDATES", font=("Segoe UI Bold", 9), fg=self.ACCENT_COLOR, bg=self.CARD_COLOR).pack(anchor=tk.W, side=tk.LEFT)
        self.update_label = tk.Label(update_card, textvariable=self.update_status_var, bg=self.CARD_COLOR, fg=self.SUBTEXT_COLOR, font=("Segoe UI", 9))
        self.update_label.pack(side=tk.LEFT, padx=10)
        
        self.update_btn = tk.Button(update_card, text="Update", bg=self.CARD_COLOR, fg=self.ACCENT_COLOR, 
                                    relief="flat", font=("Segoe UI Bold", 9), command=self._check_updates)
        self.update_btn.pack(side=tk.RIGHT)

        # Handle app closing
        self.root.protocol("WM_DELETE_WINDOW", self.hide)
        
        # Start update loop
        self._update_loop()
        self.root.mainloop()

    def _check_updates(self):
        """Runs the update check in a background thread to prevent GUI hang"""
        self.update_btn.config(state="disabled", text="Checking...")
        self.update_status_var.set("Polling GitHub for latest version...")
        
        import threading
        from updater import check_for_updates
        
        def _run_check():
            update = check_for_updates(self.server.app_version)
            self.root.after(100, lambda: self._on_update_result(update))
            
        threading.Thread(target=_run_check, daemon=True).start()

    def _on_update_result(self, update):
        self.update_btn.config(state="normal", text="Check Now")
        if update:
            self.update_status_var.set(f"NEW UPDATE: v{update['version']}")
            self.update_label.config(fg="#FF4566") # Pink/Red
            if messagebox.askyesno("Update Available", f"FlowDesk v{update['version']} is available. Download now?"):
                import webbrowser
                webbrowser.open(update['url'])
        else:
            self.update_status_var.set("FlowDesk is up to date.")
            self.update_label.config(fg="#10B981") # Green
            self.root.after(3000, lambda: self.update_status_var.set(f"FlowDesk v{self.server.app_version}"))
            self.root.after(3000, lambda: self.update_label.config(fg="#9CA3AF"))

    def show(self):
        """Lifts the app window to the front"""
        if self.root:
            self.root.deiconify()
            self.root.lift()
            self.root.focus_force()

    def hide(self):
        """Hides the window to tray instead of closing"""
        if self.root:
            self.root.withdraw()

    @property
    def server_name(self):
        return self.server_name_var.get()

    @staticmethod
    def _generate_fingerprint(raw):
        digest = str(hashlib.sha256(raw.encode()).hexdigest())
        return digest[0:16]

    def _generate_name(self):
        prefixes = ["Super", "Turbo", "Flow", "Hyper", "Swift", "Pro"]
        nouns = ["Rig", "Desk", "Server", "Box", "Link", "Node"]
        self.server_name_var.set(f"{random.choice(prefixes)}{random.choice(nouns)}")

    def _set_local_ip(self):
        import socket
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            self.ip_var.set(f"IP: {ip}")
        except Exception:
            self.ip_var.set("IP: Unknown")

    def _clear_paired(self):
        if messagebox.askyesno("Security", "Forget all paired devices? Clients will need a new PIN to connect."):
            if hasattr(self.server, 'pairing_manager'):
                self.server.pairing_manager.forget_all()
                messagebox.showinfo("Success", "Pairing list cleared.")

    def _update_loop(self):
        if not self.root:
            return
        
        # Check for active pairing PIN
        if getattr(self.server, 'current_pin', None):
            self.pin_var.set(self.server.current_pin)
            if not self.pairing_frame.winfo_viewable():
                self.pairing_frame.pack(fill=tk.X, pady=(0, 20), before=self.status_card)
                self.show() 
        else:
            if self.pairing_frame.winfo_viewable():
                self.pairing_frame.pack_forget()

        # Update paired devices list
        for widget in self.devices_frame.winfo_children():
            widget.destroy()
            
        paired_map = self.server.pairing.paired
        if not paired_map:
            tk.Label(self.devices_frame, text="No trusted devices yet", font=("Segoe UI", 9, "italic"),
                    fg=self.SUBTEXT_COLOR, bg=self.CARD_COLOR).pack(pady=4)
        else:
            for fp, d in paired_map.items():
                row = tk.Frame(self.devices_frame, bg=self.HEADER_COLOR, padx=8, pady=6)
                row.pack(fill=tk.X, pady=2)
                
                tk.Label(row, text=d.get('name', 'Mac'), font=("Segoe UI Bold", 10), 
                        fg=self.TEXT_COLOR, bg=self.HEADER_COLOR).pack(side=tk.LEFT)
                
                # Manual Sync button (only if active)
                if self.server.client_address and self.server.client_address[0] == d.get('ip'):
                    tk.Button(row, text="Pull Clipboard", bg=self.HEADER_COLOR, fg=self.ACCENT_COLOR,
                             border=0, font=("Segoe UI Bold", 8), command=self._request_client_clip).pack(side=tk.RIGHT)

        if self.server.client_socket:
            self.status_var.set("CONNECTED")
            self.status_label.config(fg="#10B981") # Green
            self.client_var.set(f"Controlling Windows from {self.server.client_name}")
        else:
            self.status_var.set("LOOKING FOR CLIENTS")
            self.status_label.config(fg=self.ACCENT_COLOR)
            self.client_var.set("Listening for connection requests...")
            
        self.root.after(1000, self._update_loop)

    def _request_client_clip(self):
        # We don't have a direct packet for PULLing yet, but we can implement it 
        # For now, this button triggers a sync signal to the server
        if self.server.client_socket:
            self.server._send_json(self.server.client_socket, {"t": "clip_push_req"})
            messagebox.showinfo("Sync", "Requested clipboard from Mac...")
