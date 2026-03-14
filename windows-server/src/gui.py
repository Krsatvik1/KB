import tkinter as tk
from tkinter import messagebox
import customtkinter as ctk
import os
import random
import hashlib
import webbrowser
import socket
import threading

# Set appearance and theme
ctk.set_appearance_mode("Dark")
ctk.set_default_color_theme("blue")

class FlowDeskGUI:
    def __init__(self, server, tray, app_version):
        self.server = server
        self.tray = tray
        self.app_version = app_version
        self.root: ctk.CTk = None
        
        # GUI Variables (initialized in run)
        self.server_name_var: tk.StringVar = None
        self.ip_var: tk.StringVar = None
        self.status_var: tk.StringVar = None
        self.update_status_var: tk.StringVar = None
        self.pin_var: tk.StringVar = None
        self.client_var: tk.StringVar = None
        
        # UI Components
        self.devices_frame: ctk.CTkFrame = None
        self.pairing_frame: ctk.CTkFrame = None
        self.status_card: ctk.CTkFrame = None
        self.name_row: ctk.CTkFrame = None
        self.status_label: ctk.CTkLabel = None
        self.update_label: ctk.CTkLabel = None
        self.update_btn: ctk.CTkButton = None
        
        # Editing state
        self.is_editing_name = False
        self.original_server_name = ""
        
        # Design Constants
        self.BG_COLOR = "#0B0F1A"
        self.ACCENT_COLOR = "#00D4FF"
        self.CARD_COLOR = "#1E293B"
        self.SUBTEXT_COLOR = "#9CA3AF"
        self.HEADER_COLOR = "#111827"
        self.TEXT_COLOR = "#F3F4F6"

    def run(self):
        """Starts the GUI mainloop (should be called on main thread)"""
        self.root = ctk.CTk()
        self.root.title("FlowDesk Settings")
        self.root.geometry("460x640")
        self.root.configure(fg_color=self.BG_COLOR)
        self.root.resizable(False, False)

        # Initialize Variables
        self.server_name_var = tk.StringVar(value=os.environ.get("COMPUTERNAME", "Windows Server"))
        if self.tray: self.tray.server_name = self.server_name_var.get()
        self.ip_var = tk.StringVar(value="Discovering...")
        self.status_var = tk.StringVar(value="WAITING FOR CONNECTION")
        self.update_status_var = tk.StringVar(value=f"FlowDesk v{self.app_version}")
        self.pin_var = tk.StringVar(value="000000")
        self.client_var = tk.StringVar(value="Broadcasting on local network...")

        # Main Layout
        main_scroll = ctk.CTkScrollableFrame(self.root, fg_color="transparent")
        main_scroll.pack(fill=tk.BOTH, expand=True, padx=20, pady=20)

        # ── Header ────────────────────────────────────────────────────────────
        header_frame = ctk.CTkFrame(main_scroll, fg_color="transparent")
        header_frame.pack(fill=tk.X, pady=(10, 24))
        
        top_info = ctk.CTkFrame(header_frame, fg_color="transparent")
        top_info.pack(side=tk.LEFT)
        ctk.CTkLabel(top_info, text="FlowDesk", font=("Segoe UI", 24, "bold"), text_color=self.ACCENT_COLOR).pack(anchor=tk.W)
        ctk.CTkLabel(top_info, textvariable=self.ip_var, font=("Segoe UI Semibold", 11), text_color=self.SUBTEXT_COLOR).pack(anchor=tk.W)

        # Version Badge
        v_frame = ctk.CTkFrame(header_frame, fg_color=self.CARD_COLOR, corner_radius=8)
        v_frame.pack(side=tk.RIGHT, pady=(10, 0))
        ctk.CTkLabel(v_frame, text=f"v{self.app_version}", font=("Segoe UI Bold", 9), text_color=self.ACCENT_COLOR).pack(padx=8, pady=2)

        # ── Identity Card ─────────────────────────────────────────────────────
        setup_card = ctk.CTkFrame(main_scroll, fg_color=self.CARD_COLOR, corner_radius=12)
        setup_card.pack(fill=tk.X, pady=(0, 20))
        
        card_content = ctk.CTkFrame(setup_card, fg_color="transparent")
        card_content.pack(fill=tk.X, padx=16, pady=16)

        ctk.CTkLabel(card_content, text="DEVICE IDENTITY", font=("Segoe UI Bold", 10), text_color=self.ACCENT_COLOR).pack(anchor=tk.W, pady=(0, 12))
        
        self.name_row = ctk.CTkFrame(card_content, fg_color="transparent")
        self.name_row.pack(fill=tk.X)
        self._refresh_name_view()

        # ── Connection Status ─────────────────────────────────────────────────
        self.status_card = ctk.CTkFrame(main_scroll, fg_color=self.CARD_COLOR, corner_radius=12)
        self.status_card.pack(fill=tk.X, pady=(0, 20))
        
        status_content = ctk.CTkFrame(self.status_card, fg_color="transparent")
        status_content.pack(fill=tk.X, padx=16, pady=16)

        ctk.CTkLabel(status_content, text="STATUS", font=("Segoe UI Bold", 10), text_color=self.ACCENT_COLOR).pack(anchor=tk.W, pady=(0, 8))
        self.status_label = ctk.CTkLabel(status_content, textvariable=self.status_var, font=("Segoe UI Bold", 16), text_color=self.ACCENT_COLOR)
        self.status_label.pack(anchor=tk.W)
        ctk.CTkLabel(status_content, textvariable=self.client_var, font=("Segoe UI", 11), text_color=self.SUBTEXT_COLOR).pack(anchor=tk.W, pady=(4, 0))

        # ── Paired Devices Card ───────────────────────────────────────────────
        paired_card = ctk.CTkFrame(main_scroll, fg_color=self.CARD_COLOR, corner_radius=12)
        paired_card.pack(fill=tk.X, pady=(0, 20))
        
        paired_content = ctk.CTkFrame(paired_card, fg_color="transparent")
        paired_content.pack(fill=tk.X, padx=16, pady=16)

        header_row = ctk.CTkFrame(paired_content, fg_color="transparent")
        header_row.pack(fill=tk.X, pady=(0, 12))
        ctk.CTkLabel(header_row, text="TRUSTED DEVICES", font=("Segoe UI Bold", 10), text_color=self.ACCENT_COLOR).pack(side=tk.LEFT)
        
        forget_all_btn = ctk.CTkButton(header_row, text="Forget All", width=70, height=24, fg_color="transparent", 
                                      text_color="#FF4566", font=("Segoe UI Bold", 10), command=self._clear_paired, hover_color="#2D1E2A")
        forget_all_btn.pack(side=tk.RIGHT)

        self.devices_frame = ctk.CTkFrame(paired_content, fg_color="transparent")
        self.devices_frame.pack(fill=tk.X)
        
        # ── Pairing Frame (Hidden by default) ────────────────────────────────
        self.pairing_frame = ctk.CTkFrame(main_scroll, fg_color="#423E2A", corner_radius=12, border_width=1, border_color="#EAB308")
        # Packed conditionally in _update_loop

        # ── Footer ────────────────────────────────────────────────────────────
        footer_frame = ctk.CTkFrame(main_scroll, fg_color="transparent")
        footer_frame.pack(fill=tk.X, pady=10)
        
        self.update_label = ctk.CTkLabel(footer_frame, textvariable=self.update_status_var, font=("Segoe UI", 11), text_color=self.SUBTEXT_COLOR)
        self.update_label.pack(side=tk.LEFT)
        
        self.update_btn = ctk.CTkButton(footer_frame, text="Check Now", width=90, height=32, command=self._check_updates)
        self.update_btn.pack(side=tk.RIGHT)

        # Handlers
        self.root.protocol("WM_DELETE_WINDOW", self.hide)
        self.root.after(100, self._set_local_ip)
        self._update_loop()
        self.root.mainloop()

    def _refresh_name_view(self):
        for widget in self.name_row.winfo_children():
            widget.destroy()

        if self.is_editing_name:
            entry = ctk.CTkEntry(self.name_row, textvariable=self.server_name_var, font=("Segoe UI", 14), 
                               fg_color="#0F172A", border_color=self.ACCENT_COLOR, height=36)
            entry.pack(side=tk.LEFT, fill=tk.X, expand=True, padx=(0, 10))
            entry.focus_set()

            save_btn = ctk.CTkButton(self.name_row, text="Save", width=60, height=32, fg_color="#10B981", hover_color="#059669",
                                    command=self._save_name)
            save_btn.pack(side=tk.LEFT, padx=5)

            cancel_btn = ctk.CTkButton(self.name_row, text="Cancel", width=60, height=32, fg_color="transparent", 
                                      border_width=1, border_color="#4B5563", hover_color="#374151", command=self._cancel_edit)
            cancel_btn.pack(side=tk.LEFT)
        else:
            ctk.CTkLabel(self.name_row, textvariable=self.server_name_var, font=("Segoe UI Semibold", 18)).pack(side=tk.LEFT, pady=4)
            
            edit_btn = ctk.CTkButton(self.name_row, text="Edit", width=60, height=28, fg_color="transparent", 
                                    border_width=1, border_color=self.ACCENT_COLOR, text_color=self.ACCENT_COLOR, 
                                    hover_color="#1E293B", command=self._enable_edit)
            edit_btn.pack(side=tk.RIGHT)

            magic_btn = ctk.CTkButton(self.name_row, text="✨", width=32, height=28, fg_color="transparent", 
                                     hover_color="#1E293B", text_color=self.ACCENT_COLOR, command=self._generate_name)
            magic_btn.pack(side=tk.RIGHT, padx=5)

    def _enable_edit(self):
        self.original_server_name = self.server_name_var.get()
        self.is_editing_name = True
        self._refresh_name_view()

    def _save_name(self):
        new_name = self.server_name_var.get().strip()
        if not new_name:
            self.server_name_var.set(self.original_server_name)
        else:
            if self.tray: self.tray.server_name = new_name
        self.is_editing_name = False
        self._refresh_name_view()

    def _cancel_edit(self):
        self.server_name_var.set(self.original_server_name)
        self.is_editing_name = False
        self._refresh_name_view()

    def _generate_name(self):
        prefixes = ["Super", "Turbo", "Flow", "Hyper", "Swift", "Pro"]
        nouns = ["Rig", "Desk", "Server", "Box", "Link", "Node"]
        self.server_name_var.set(f"{random.choice(prefixes)}{random.choice(nouns)}")
        if not self.is_editing_name: self._enable_edit()

    def _update_loop(self):
        if not self.root: return
        
        # 1. Pairing Frame Logic
        if getattr(self.server, 'current_pin', None):
            self.pin_var.set(self.server.current_pin)
            if not self.pairing_frame.winfo_viewable():
                self.pairing_frame.pack(fill=tk.X, pady=(0, 20), after=self.status_card)
                if not self.pairing_frame.winfo_children():
                    p_wrap = ctk.CTkFrame(self.pairing_frame, fg_color="transparent")
                    p_wrap.pack(fill=tk.X, padx=20, pady=20)
                    ctk.CTkLabel(p_wrap, text="NEW DEVICE PAIRING", font=("Segoe UI Bold", 10), text_color="#EAB308").pack(anchor=tk.W)
                    ctk.CTkLabel(p_wrap, text="Enter this PIN on your other device:", font=("Segoe UI", 12)).pack(anchor=tk.W, pady=(4, 8))
                    ctk.CTkLabel(p_wrap, textvariable=self.pin_var, font=("Segoe UI Bold", 36), text_color="#EAB308").pack(pady=10)
                self.show()
        else:
            if self.pairing_frame.winfo_viewable():
                self.pairing_frame.pack_forget()

        # 2. Connection Status
        if self.server.client_socket:
            self.status_var.set("CONNECTED")
            self.status_label.configure(text_color="#10B981")
            self.client_var.set(f"Controlling Windows from {self.server.client_name}")
        else:
            self.status_var.set("LOOKING FOR CLIENTS")
            self.status_label.configure(text_color=self.ACCENT_COLOR)
            self.client_var.set("Waiting for trusted device to connect...")

        # 3. Trusted Devices List
        paired_map = self.server.pairing.paired
        widgets = self.devices_frame.winfo_children()
        
        if not paired_map:
            if not widgets or not hasattr(widgets[0], "is_empty_msg"):
                for w in widgets: w.destroy()
                lbl = ctk.CTkLabel(self.devices_frame, text="No trusted devices yet", font=("Segoe UI", 12, "italic"), text_color=self.SUBTEXT_COLOR)
                lbl.pack(pady=10)
                lbl.is_empty_msg = True
        else:
            # Syncing by clear-and-draw if count changed (simplest fix)
            paired_widgets = [w for w in widgets if hasattr(w, "device_fp")]
            if len(paired_widgets) != len(paired_map):
                for w in widgets: w.destroy()
                for fp, d in paired_map.items():
                    row = ctk.CTkFrame(self.devices_frame, fg_color=self.HEADER_COLOR, corner_radius=8)
                    row.pack(fill=tk.X, pady=4)
                    row.device_fp = fp
                    
                    inner = ctk.CTkFrame(row, fg_color="transparent")
                    inner.pack(fill=tk.X, padx=12, pady=10)
                    
                    info = ctk.CTkFrame(inner, fg_color="transparent")
                    info.pack(side=tk.LEFT)
                    ctk.CTkLabel(info, text=d.get('name', 'Mac'), font=("Segoe UI Bold", 13)).pack(anchor=tk.W)
                    ctk.CTkLabel(info, text=d.get('ip', '0.0.0.0'), font=("Segoe UI", 11, "italic"), text_color=self.SUBTEXT_COLOR).pack(anchor=tk.W)
                    
                    forget = ctk.CTkButton(inner, text="Forget", width=60, height=24, fg_color="transparent", border_width=1, border_color="#BD143C", font=("Segoe UI Bold", 10), command=lambda f=fp: self._forget_device(f))
                    forget.pack(side=tk.RIGHT)

        self.root.after(1000, self._update_loop)

    def _forget_device(self, fp):
        if messagebox.askyesno("Confirm", "Forget this device? It will need a new PIN next time."):
            if fp in self.server.pairing.paired:
                del self.server.pairing.paired[fp]
                from pairing import save_paired_devices
                save_paired_devices(self.server.pairing.paired)

    def _check_updates(self):
        self.update_btn.configure(state="disabled", text="...")
        def _run():
            try:
                from updater import check_for_updates
                update = check_for_updates(self.app_version)
                self.root.after(100, lambda: self._on_update_result(update))
            except: 
                self.root.after(100, lambda: self.update_btn.configure(state="normal", text="Check Now"))
        threading.Thread(target=_run, daemon=True).start()

    def _on_update_result(self, update):
        self.update_btn.configure(state="normal", text="Check Now")
        if update:
            self.update_status_var.set(f"v{update['version']} available!")
            self.update_label.configure(text_color=self.ACCENT_COLOR)
        else:
            self.update_status_var.set(f"FlowDesk v{self.app_version}")
            self.update_label.configure(text_color=self.SUBTEXT_COLOR)

    def _set_local_ip(self):
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
            s.close()
            self.ip_var.set(f"LOCAL IP: {ip}")
        except: self.ip_var.set("LOCAL IP: Unknown")

    def show(self):
        if self.root:
            self.root.deiconify()
            self.root.lift()
            self.root.focus_force()

    def hide(self):
        if self.root: self.root.withdraw()

    def _clear_paired(self):
        if messagebox.askyesno("Security", "Forget all paired devices? Clients will need a new PIN to connect."):
            if hasattr(self.server, 'pairing'):
                self.server.pairing.paired.clear()
                from pairing import save_paired_devices
                save_paired_devices(self.server.pairing.paired)
                messagebox.showinfo("Success", "Pairing list cleared.")

    @property
    def server_name(self): return self.server_name_var.get()
