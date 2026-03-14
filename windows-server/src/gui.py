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

        # Device pairing / Security Section
        ttk.Label(main_container, text="SECURITY", style="Sub.TLabel").pack(anchor=tk.W, pady=(10, 8))
        
        ttk.Button(main_container, text="Copy Server IP Address", style="FlowDesk.TButton", command=self._copy_ip).pack(fill=tk.X, pady=5)
        ttk.Button(main_container, text="Forget All Trusted Devices", style="FlowDesk.TButton", command=self._clear_paired).pack(fill=tk.X, pady=5)

        # Footer
        footer = ttk.Frame(main_container)
        footer.pack(side=tk.BOTTOM, fill=tk.X)
        
        shortcut_info = "Control is shared while connected.\nPress Esc × 3 on Mac to emergency exit."
        ttk.Label(footer, text=shortcut_info, style="Sub.TLabel", justify=tk.LEFT).pack(side=tk.LEFT)

        # Handle app closing
        self.root.protocol("WM_DELETE_WINDOW", self.hide)
        
        # Start update loop
        self._update_loop()
        self.root.mainloop()

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
        
        if self.server.client_socket:
            self.status_var.set("● CONNECTED")
            self.status_label.config(fg="#10B981") # Green
            self.client_var.set(f"Active Client: {self.server.client_address[0]}")
        else:
            self.status_var.set("WAITING FOR CONNECTION")
            self.status_label.config(fg=self.ACCENT_COLOR) # Blue-Cyan
            self.client_var.set("No devices connected")
            
        self.root.after(1000, self._update_loop)
