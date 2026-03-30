import os
import threading
import time
import tkinter as tk
from tkinter import LEFT, RIGHT, X, Y, BOTH, BOTTOM, END
from typing import Any, Dict, List
try:
    from dotenv import load_dotenv  # type: ignore
except Exception:
    def load_dotenv() -> None:  # fallback no-op if python-dotenv isn't installed
        return None
from supabase import create_client  # type: ignore
import ttkbootstrap as ttk  # type: ignore
from ttkbootstrap.constants import *  # type: ignore
from ttkbootstrap.widgets.scrolled import ScrolledText  # type: ignore
from rapidfuzz import process, fuzz  # type: ignore

# Load Env
load_dotenv()

class ImageSyncerApp(ttk.Window):
    def __init__(self):
        super().__init__(themename="superhero")
        self.title("🖼️ Image Syncer: Source -> Duplicate")
        self.geometry("1000x750")
        
        self.supabase = None
        self.source_data: List[Any] = []  # The original cards (id, title, image)
        self.target_data: List[Any] = []  # The duplicate cards (id, title)
        self.is_running = False
        self.stop_event = threading.Event()

        # UI Layout
        self.create_config_ui()
        self.create_main_ui()
        
        # Auto-fill keys
        self.url_entry.insert(0, os.getenv("SUPABASE_URL", ""))
        self.key_entry.insert(0, os.getenv("SUPABASE_KEY", ""))

    def create_config_ui(self):
        frame = ttk.Frame(self, padding=10, bootstyle="secondary")
        frame.pack(fill=X)
        
        # API Keys
        row1 = ttk.Frame(frame)
        row1.pack(fill=X, pady=5)
        ttk.Label(row1, text="Supabase URL:", width=15).pack(side=LEFT)
        self.url_entry = ttk.Entry(row1)
        self.url_entry.pack(side=LEFT, fill=X, expand=True, padx=5)
        
        row2 = ttk.Frame(frame)
        row2.pack(fill=X, pady=5)
        ttk.Label(row2, text="Supabase Key:", width=15).pack(side=LEFT)
        self.key_entry = ttk.Entry(row2, show="*")
        self.key_entry.pack(side=LEFT, fill=X, expand=True, padx=5)
        
        ttk.Button(row2, text="Connect & Fetch Data", command=self.fetch_data, bootstyle="success").pack(side=LEFT, padx=10)

    def create_main_ui(self):
        main = ttk.Frame(self, padding=20)
        main.pack(fill=BOTH, expand=True)

        # Controls
        controls = ttk.LabelFrame(main, text="Matching Logic")
        controls.pack(fill=X, pady=10, padx=5)

        # Threshold Slider
        ttk.Label(controls, text="Similarity Threshold (0-100):").pack(side=LEFT)
        self.threshold_var = tk.IntVar(value=90)
        self.lbl_threshold = ttk.Label(controls, text="90%")
        self.lbl_threshold.pack(side=LEFT, padx=5)
        
        scale = ttk.Scale(controls, from_=50, to=100, variable=self.threshold_var, command=self.update_thresh_label)
        scale.pack(side=LEFT, fill=X, expand=True, padx=10)

        # Mode Switch
        self.mode_var = tk.StringVar(value="TEST")
        ttk.Checkbutton(controls, text="ENABLE LIVE DB UPDATES", variable=self.mode_var, 
                        onvalue="LIVE", offvalue="TEST", bootstyle="danger-round-toggle").pack(side=RIGHT)

        # Action Buttons
        btn_frame = ttk.Frame(main)
        btn_frame.pack(fill=X, pady=10)
        self.btn_start = ttk.Button(btn_frame, text="▶ START MATCHING", command=self.start_thread, state="disabled", bootstyle="primary")
        self.btn_start.pack(side=LEFT, fill=X, expand=True, padx=5)
        ttk.Button(btn_frame, text="⏹ STOP", command=self.stop_process, bootstyle="danger").pack(side=LEFT, fill=X, expand=True, padx=5)

        # Logs
        self.log_area = ScrolledText(main, height=15, autohide=True)
        self.log_area.pack(fill=BOTH, expand=True)
        self.log_area.text.tag_config("MATCH", foreground="#00ff00")
        self.log_area.text.tag_config("WEAK", foreground="#ffaa00")
        self.log_area.text.tag_config("FAIL", foreground="#ff4444")

        # Status
        self.status_var = tk.StringVar(value="Connect to Supabase first.")
        ttk.Label(self, textvariable=self.status_var, relief="sunken", anchor="w", bootstyle="inverse-secondary").pack(fill=X)

    def update_thresh_label(self, val):
        self.lbl_threshold.config(text=f"{int(float(val))}%")

    def log(self, msg, tag="INFO"):
        self.log_area.text.configure(state='normal')
        self.log_area.text.insert(END, f"{msg}\n", tag)
        self.log_area.text.see(END)
        self.log_area.text.configure(state='disabled')

    # --- LOGIC ---
    def fetch_data(self):
        try:
            url = self.url_entry.get()
            key = self.key_entry.get()
            self.supabase = create_client(url, key)
            
            self.status_var.set("Fetching SOURCE table (theory_cards)...")
            self.update_idletasks()
            
            # 1. Fetch Source (The table WITH images)
            # Assuming the source table is named 'theory_cards' (adjust if needed)
            res_source = self.supabase.table('theory_cards').select("id, title_it, image_url").neq("image_url", "null").execute()
            self.source_data = res_source.data
            
            # 2. Fetch Target (The table WITHOUT images)
            self.status_var.set("Fetching TARGET table (theory_cards_duplicate)...")
            res_target = self.supabase.table('theory_cards_duplicate').select("id, title_it, image_url").is_("image_url", "null").execute()
            self.target_data = res_target.data
            
            msg = f"✅ Loaded: {len(self.source_data)} Source Images | {len(self.target_data)} Targets needing images."
            self.log(msg, "MATCH")
            self.status_var.set(msg)
            
            if len(self.source_data) > 0 and len(self.target_data) > 0:
                self.btn_start.configure(state="normal")
                
        except Exception as e:
            self.log(f"❌ Error: {e}", "FAIL")

    def start_thread(self):
        self.is_running = True
        self.stop_event.clear()
        self.btn_start.configure(state="disabled")
        threading.Thread(target=self.run_matching, daemon=True).start()

    def stop_process(self):
        self.is_running = False
        self.stop_event.set()
        self.status_var.set("Stopping...")

    def run_matching(self):
        threshold = self.threshold_var.get()
        is_live = self.mode_var.get() == "LIVE"
        
        # Prepare Source dictionary for fast lookup {title: image_url}
        # We also create a list of just titles for RapidFuzz
        source_titles = [x['title_it'] for x in self.source_data if x['title_it']]
        # Map Title -> ImageURL (Handle duplicates by keeping one)
        title_to_img = {x['title_it']: x['image_url'] for x in self.source_data if x['title_it']}
        
        self.log(f"🚀 Starting Match Process (Threshold: {threshold}%)", "INFO")
        
        matches_found = 0
        
        for idx, target in enumerate(self.target_data):
            if self.stop_event.is_set(): break
            
            target_id = target['id']
            target_title = target['title_it']
            
            if not target_title:
                continue

            # --- THE MAGIC: RapidFuzz ---
            # extractOne returns: (Match String, Score, Index)
            match = process.extractOne(target_title, source_titles, scorer=fuzz.token_sort_ratio)
            
            if match:
                best_match_title, score, _ = match
                
                if score >= threshold:
                    img_url = title_to_img.get(best_match_title)
                    
                    # LOGGING
                    self.log(f"#{target_id} | Score: {score:.1f}", "MATCH" if score == 100 else "WEAK")
                    self.log(f"   Target: {target_title[:40]}...")
                    self.log(f"   Source: {best_match_title[:40]}...")
                    
                    if is_live:
                        try:
                            # type: ignore -- supabase client is dynamic
                            self.supabase.table('theory_cards_duplicate').update({"image_url": img_url}).eq('id', target_id).execute()  # type: ignore
                            self.log(f"   ✅ DB Updated!", "MATCH")
                        except Exception as e:
                            self.log(f"   ❌ DB Write Error: {e}", "FAIL")
                    else:
                        img_snippet = (img_url[-20:] if isinstance(img_url, str) and len(img_url) > 20 else (img_url if img_url else "N/A"))
                        self.log(f"   🧪 [TEST] Would set image: {img_snippet}...", "WEAK")
                    
                    matches_found += 1
                    self.log("-" * 40)
                    
                else:
                    # Optional: Log failures if you want to see what's being missed
                    # self.log(f"Skipped #{target_id} (Best score: {score:.1f})", "FAIL")
                    pass

            # Update status every 10 items
            if idx % 10 == 0:
                self.status_var.set(f"Processed {idx+1}/{len(self.target_data)} | Matches: {matches_found}")
        
        self.is_running = False
        self.btn_start.configure(state="normal")
        self.log(f"🏁 DONE! Total matches applied: {matches_found}", "MATCH")
        self.status_var.set("Process Completed.")

if __name__ == "__main__":
    app = ImageSyncerApp()
    app.mainloop()