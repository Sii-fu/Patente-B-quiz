import os
import json
import time
import threading
import tkinter as tk
from tkinter import scrolledtext, LEFT, RIGHT, X, Y, BOTH, BOTTOM, END
from typing import Any, Dict, List, Optional
from dotenv import load_dotenv  # type: ignore

# Modern UI Library
import ttkbootstrap as ttk  # type: ignore
from ttkbootstrap.constants import *  # type: ignore
from ttkbootstrap.scrolled import ScrolledText  # type: ignore
from ttkbootstrap.dialogs import Messagebox  # type: ignore

# Backend Libraries
from supabase import create_client  # type: ignore
import google.generativeai as genai  # type: ignore

# Load env vars
load_dotenv()

class ModernTranslatorApp(ttk.Window):
    def __init__(self):
        super().__init__(themename="superhero")  # Themes: superhero, darkly, cyborg, cosmo
        self.title("🇮🇹 Driving Theory Translator Pro")
        self.geometry("1100x800")
        
        # --- App State ---
        self.is_running: bool = False
        self.stop_event: threading.Event = threading.Event()
        self.supabase: Any = None
        self.model: Any = None
        
        # --- Layout ---
        self.create_sidebar()
        self.create_main_area()
        self.create_status_bar()

        # --- Auto-Load Env Vars ---
        self.url_entry.insert(0, os.getenv("SUPABASE_URL", ""))
        self.key_entry.insert(0, os.getenv("SUPABASE_KEY", ""))
        self.gemini_entry.insert(0, os.getenv("GEMINI_API_KEY", ""))

    def create_sidebar(self):
        """Left side configuration panel"""
        sidebar = ttk.Frame(self, padding=15, bootstyle="secondary")
        sidebar.pack(side=LEFT, fill=Y)

        # Title
        ttk.Label(sidebar, text="⚙️ CONFIGURATION", font=("Helvetica", 12, "bold"), bootstyle="inverse-secondary").pack(pady=(0, 20), anchor="w")

        # API Keys
        self.create_label_entry(sidebar, "Supabase URL", "url_entry")
        self.create_label_entry(sidebar, "Supabase Key", "key_entry", show="*")
        self.create_label_entry(sidebar, "Gemini API Key", "gemini_entry", show="*")

        ttk.Button(sidebar, text="🔌 Connect APIs", command=self.connect_apis, bootstyle="success-outline").pack(fill=X, pady=10)
        
        ttk.Separator(sidebar).pack(fill=X, pady=20)

        # Settings
        ttk.Label(sidebar, text="🎯 TARGET TABLE", bootstyle="inverse-secondary").pack(anchor="w")
        self.table_var = ttk.StringVar(value="Theory Cards")
        ttk.Combobox(sidebar, textvariable=self.table_var, values=["Theory Cards", "Chapters"], state="readonly").pack(fill=X, pady=5)

        ttk.Label(sidebar, text="📦 BATCH SIZE", bootstyle="inverse-secondary").pack(anchor="w", pady=(10,0))
        self.batch_var = ttk.IntVar(value=5)
        ttk.Spinbox(sidebar, from_=1, to=20, textvariable=self.batch_var).pack(fill=X, pady=5)

        ttk.Label(sidebar, text="⚡ SPEED (Delay)", bootstyle="inverse-secondary").pack(anchor="w", pady=(10,0))
        self.speed_var = ttk.IntVar(value=2)
        ttk.Scale(sidebar, variable=self.speed_var, from_=0, to=10).pack(fill=X, pady=5)

        ttk.Separator(sidebar).pack(fill=X, pady=20)

        # MODE SWITCH
        ttk.Label(sidebar, text="🚀 OPERATION MODE", bootstyle="inverse-secondary").pack(anchor="w")
        self.mode_var = ttk.StringVar(value="TEST")
        
        # Custom Toggle Styling
        chk = ttk.Checkbutton(sidebar, text="ENABLE LIVE WRITE", variable=self.mode_var, 
                              onvalue="LIVE", offvalue="TEST", bootstyle="danger-round-toggle")
        chk.pack(fill=X, pady=10)
        
        ttk.Label(sidebar, text="⚠️ 'TEST' will not save to DB.\nEnable Live Write to apply changes.", 
                  font=("Arial", 8), bootstyle="warning").pack(fill=X)

    def create_label_entry(self, parent, text, attr_name, show=None):
        ttk.Label(parent, text=text, bootstyle="inverse-secondary").pack(anchor="w")
        entry = ttk.Entry(parent, show=show)
        entry.pack(fill=X, pady=(0, 10))
        setattr(self, attr_name, entry)

    def create_main_area(self):
        """Right side logs and controls"""
        main = ttk.Frame(self, padding=20)
        main.pack(side=RIGHT, fill=BOTH, expand=True)

        # Header Controls
        header = ttk.Frame(main)
        header.pack(fill=X, pady=(0, 10))
        
        self.btn_start = ttk.Button(header, text="▶ START PROCESS", command=self.start_thread, bootstyle="primary", state="disabled", width=20)
        self.btn_start.pack(side=LEFT, padx=5)
        
        self.btn_stop = ttk.Button(header, text="⏹ STOP", command=self.stop_process, bootstyle="danger", state="disabled", width=15)
        self.btn_stop.pack(side=LEFT, padx=5)

        # Console Log
        self.log_area = ScrolledText(main, height=20, autohide=True, bootstyle="dark")
        self.log_area.pack(fill=BOTH, expand=True)
        
        # Log Tags
        self.log_area.text.tag_config("INFO", foreground="white")
        self.log_area.text.tag_config("SUCCESS", foreground="#00ff00") # Bright Green
        self.log_area.text.tag_config("TEST", foreground="#ffd700")    # Gold
        self.log_area.text.tag_config("ERROR", foreground="#ff4444")   # Red
        self.log_area.text.tag_config("ITALIAN", foreground="#4fc3f7") # Light Blue

    def create_status_bar(self):
        self.status_var = ttk.StringVar(value="Waiting for connection...")
        status = ttk.Label(self, textvariable=self.status_var, relief="sunken", anchor="w", padding=5, bootstyle="secondary-inverse")
        status.pack(side=BOTTOM, fill=X)

    # --- LOGIC ---

    def log(self, msg, tag="INFO"):
        self.log_area.text.configure(state='normal')
        timestamp = time.strftime("[%H:%M:%S]")
        self.log_area.text.insert(END, f"{timestamp} {msg}\n", tag)
        self.log_area.text.see(END)
        self.log_area.text.configure(state='disabled')

    def connect_apis(self):
        try:
            url = self.url_entry.get().strip()
            key = self.key_entry.get().strip()
            ai_key = self.gemini_entry.get().strip()

            if not url or not key or not ai_key:
                Messagebox.show_error("Please fill in all API Keys", "Missing Info")
                return

            self.supabase = create_client(url, key)
            genai.configure(api_key=ai_key)
            self.model = genai.GenerativeModel('gemini-2.0-flash-001', generation_config={"response_mime_type": "application/json"})
            
            self.log("✅ APIs Connected Successfully!", "SUCCESS")
            self.btn_start.configure(state="normal")
            self.status_var.set("Ready.")
            
        except Exception as e:
            self.log(f"❌ Connection Error: {e}", "ERROR")

    def start_thread(self):
        if not self.is_running:
            self.is_running = True
            self.stop_event.clear()
            self.btn_start.configure(state="disabled")
            self.btn_stop.configure(state="normal")
            threading.Thread(target=self.run_process, daemon=True).start()

    def stop_process(self):
        if self.is_running:
            self.status_var.set("Stopping after current batch...")
            self.stop_event.set()

    def get_safe_translations(self, items: List[Dict[str, Any]], field_name: str = "text_it") -> Dict[int, Dict[str, str]]:
        """Batched AI Call

        `field_name` is the source Italian text field (e.g. `text_it` or `name_it`).
        """
        # Prepare lightweight input
        prompt_input = [{"id": x['id'], "text": x.get(field_name, "")} for x in items]  # type: ignore
        
        prompt = f"""
        Translate these Driving Theory items.
        
        CONTEXT:
        Italian Driving License Theory. 
        Target Audience: Bangladeshi immigrants in Italy.
        
        RULES:
        1. English: Standard UK/EU driving terms.
        2. Bangla: 
           - Natural, Spoken/Colloquial (Not Bookish/Shuddho).
           - Use English words for car parts if common (Steering, Brake, Clutch, Indicator).
           - Must be friendly and easy to read.

        INPUT:
        {json.dumps(prompt_input, ensure_ascii=False)}

        OUTPUT:
        JSON List of objects. MUST include the 'id'.
        Example: [{{ "id": 1, "en": "...", "bn": "..." }}]
        """
        
        try:
            response = self.model.generate_content(prompt)  # type: ignore
            result = json.loads(response.text)

            # Convert list to Dict for ID safety
            # { 101: {'en': '...', 'bn': '...'} }
            return {int(x['id']): x for x in result if 'id' in x}  # type: ignore
        except Exception as e:
            self.log(f"⚠️ AI Generation Error: {e}", "ERROR")
            return {}

    def run_process(self):
        is_cards = "Cards" in self.table_var.get()
        table = "theory_cards_duplicate" if is_cards else "theory_chapters_duplicate"
        en_col = "text_en" if is_cards else "name_en"
        bn_col = "text_bn" if is_cards else "name_bn"
        it_col = "text_it" if is_cards else "name_it"
        is_live = self.mode_var.get() == "LIVE"
        
        self.log(f"🚀 Started in {'LIVE' if is_live else 'TEST'} Mode", "TEST" if not is_live else "SUCCESS")

        while not self.stop_event.is_set():
            try:
                # 1. Fetch Batch
                batch_size = self.batch_var.get()
                # Query rows where English column is NULL (not present)
                res = self.supabase.table(table).select("*").is_(en_col, None).limit(batch_size).execute()  # type: ignore
                items: List[Dict[str, Any]] = res.data  # type: ignore

                self.log(f"📥 Processing batch of {len(items)}...", "INFO")

                # 2. Translate
                # Ask AI to translate using the appropriate Italian source column
                translations = self.get_safe_translations(items, it_col)

                # 3. Update Loop
                success_count = 0
                for item in items:
                    id_val = item.get('id')
                    if id_val is None:
                        self.log("   ⚠️ Skipped item with missing id", "ERROR")
                        continue
                    item_id = int(id_val)
                    t_data = translations.get(item_id)  # type: ignore

                    if t_data and t_data.get('en') and t_data.get('bn'):
                        # Prepare Payload: always write EN (it was NULL by query),
                        # only write BN if it is missing to avoid overwriting existing BN text.
                        payload: Dict[str, str] = {}
                        payload[en_col] = t_data['en']  # type: ignore
                        if not item.get(bn_col):
                            payload[bn_col] = t_data['bn']  # type: ignore

                        # Display Log
                        item_text = str(item.get(it_col, ""))
                        self.log(f"   🇮🇹 {item_text}", "ITALIAN")
                        self.log(f"   🇧🇩 {t_data['bn']}", "INFO")  # type: ignore

                        # WRITE TO DB (Only if LIVE)
                        if is_live:
                            self.supabase.table(table).update(payload).eq('id', item_id).execute()  # type: ignore
                            self.log(f"   ✅ Saved ID {item_id}", "SUCCESS")  # type: ignore
                        else:
                            self.log(f"   🧪 [TEST] Would save ID {item_id} -> {list(payload.keys())}", "TEST")  # type: ignore

                        success_count += 1
                    else:
                        self.log(f"   ⚠️ Skipped ID {item.get('id')} (AI mismatch)", "ERROR")  # type: ignore

                # 4. Status Update
                self.status_var.set(f"Batch Done. Success: {success_count}/{len(items)}")
                
                # 5. Delay
                time.sleep(self.speed_var.get())

            except Exception as e:
                self.log(f"❌ Critical Error: {e}", "ERROR")
                time.sleep(5)

        self.is_running = False
        self.btn_start.configure(state="normal")
        self.btn_stop.configure(state="disabled")
        self.log("🏁 Process Stopped", "INFO")

if __name__ == "__main__":
    app = ModernTranslatorApp()
    app.mainloop()