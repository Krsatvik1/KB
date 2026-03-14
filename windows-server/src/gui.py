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
        self.SUBTEXT_COLOR = "#6B7280"
        self.TEXT_COLOR = "#E8EAF6"
        
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

        # Header Section
        ttk.Label(main_container, text="FlowDesk", style="Header.TLabel").pack(pady=(0, 4))
        ttk.Label(main_container, text="Windows Server v" + self.app_version, style="Sub.TLabel").pack(pady=(0, 30))

        # Status Display Container
        status_box = tk.Canvas(main_container, bg=self.HEADER_COLOR, highlightthickness=1, highlightbackground="#1F2937", height=100)
        status_box.pack(fill=tk.X, pady=(0, 20))
        
        self.status_var = tk.StringVar(value="WAITING FOR CONNECTION")
        self.status_label = tk.Label(status_box, textvariable=self.status_var, bg=self.HEADER_COLOR, fg=self.ACCENT_COLOR, font=("Segoe UI Semibold", 10))
        self.status_label.place(relx=0.5, rely=0.4, anchor=tk.CENTER)
        
        self.client_var = tk.StringVar(value="No devices connected")
        ttk.Label(status_box, textvariable=self.client_var, style="Sub.TLabel", background=self.HEADER_COLOR).place(relx=0.5, rely=0.7, anchor=tk.CENTER)

        # Pairing PIN Container (hidden by default)
        self.pairing_frame = tk.Frame(main_container, bg="#423E2A", highlightthickness=1, highlightbackground="#EAB308")
        
        ttk.Label(self.pairing_frame, text="PAIRING REQUEST", font=("Segoe UI", 9, "bold"), foreground="#EAB308", background="#423E2A").pack(pady=(12, 4))
        self.pin_var = tk.StringVar(value="000000")
        tk.Label(self.pairing_frame, textvariable=self.pin_var, bg="#423E2A", fg="#FFFFFF", font=("Segoe UI", 28, "bold")).pack(pady=(0, 8))
        ttk.Label(self.pairing_frame, text="Enter this PIN on your Mac", style="Sub.TLabel", background="#423E2A").pack(pady=(0, 12))

        # Device pairing / Security Section
        self.security_label = ttk.Label(main_container, text="SECURITY", style="Sub.TLabel")
        self.security_label.pack(anchor=tk.W, pady=(10, 8))
        
        self.copy_btn = ttk.Button(main_container, text="Copy Server IP Address", style="FlowDesk.TButton", command=self._copy_ip)
        self.copy_btn.pack(fill=tk.X, pady=5)
        self.forget_btn = ttk.Button(main_container, text="Forget All Trusted Devices", style="FlowDesk.TButton", command=self._clear_paired)
        self.forget_btn.pack(fill=tk.X, pady=5)

        # Footer
        footer = ttk.Frame(main_container)
        footer.pack(side=tk.BOTTOM, fill=tk.X)
        
        shortcut_info = "Control is shared while connected.\nPress Esc × 3 on Mac to emergency exit."
        ttk.Label(footer, text=shortcut_info, style="Sub.TLabel", justify=tk.LEFT).pack(side=tk.LEFT)

        # Updates Section (Aesthetics matched to sidebar)
        update_section = tk.Frame(main_container, bg=self.BG_COLOR)
        update_section.pack(fill=tk.X, pady=(20, 0))
        ttk.Label(update_section, text="UPDATES", style="Sub.TLabel").pack(anchor=tk.W, pady=(0, 8))
        
        update_inner = tk.Frame(update_section, bg=self.HEADER_COLOR, highlightthickness=1, highlightbackground="#1F2937")
        update_inner.pack(fill=tk.X)
        
        self.update_status_var = tk.StringVar(value=f"FlowDesk v{self.server.app_version}")
        self.update_label = tk.Label(update_inner, textvariable=self.update_status_var, bg=self.HEADER_COLOR, fg="#9CA3AF", font=("Segoe UI", 9))
        self.update_label.pack(side=tk.LEFT, padx=15, py=12)
        
        self.update_btn = tk.Button(update_inner, text="Check Now", bg=self.HEADER_COLOR, fg=self.ACCENT_COLOR, 
                                    activebackground=self.HEADER_COLOR, activeforeground="#FFFFFF",
                                    relief="flat", font=("Segoe UI", 9, "bold"), command=self._check_updates)
        self.update_btn.pack(side=tk.RIGHT, padx=15)

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

    def _copy_ip(self):
        import socket
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            self.root.clipboard_clear()
            self.root.clipboard_append(ip)
            messagebox.showinfo("Copied", f"Local IP {ip} copied to clipboard.")
        except Exception:
            messagebox.showerror("Error", "Could not detect local IP.")

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
                self.pairing_frame.pack(fill=tk.X, pady=(0, 20), after=self.status_label.master)
                self.security_label.pack_forget()
                self.copy_btn.pack_forget()
                self.forget_btn.pack_forget()
                self.show() # Auto-lift if pairing starts
        else:
            if self.pairing_frame.winfo_viewable():
                self.pairing_frame.pack_forget()
                self.security_label.pack(anchor=tk.W, pady=(10, 8))
                self.copy_btn.pack(fill=tk.X, pady=5)
                self.forget_btn.pack(fill=tk.X, pady=5)

        if self.server.client_socket:
            self.status_var.set("● CONNECTED")
            self.status_label.config(fg="#10B981") # Green
            self.client_var.set(f"Active Client: {self.server.client_address[0]}")
        else:
            self.status_var.set("WAITING FOR CONNECTION")
            self.status_label.config(fg=self.ACCENT_COLOR) # Blue-Cyan
            self.client_var.set("No devices connected")
            
        self.root.after(1000, self._update_loop)
