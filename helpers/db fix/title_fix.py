import os
import threading
import tkinter as tk
from tkinter import messagebox
from dotenv import load_dotenv
from supabase import create_client

# UI Library
import ttkbootstrap as tb
from ttkbootstrap.constants import *
from ttkbootstrap.scrolled import ScrolledText, ScrolledFrame
from rapidfuzz import process, fuzz

# Load Env
load_dotenv()

class ImageSyncerApp(tb.Window):
    def __init__(self):
        super().__init__(themename="superhero")
        self.title("🖼️ Image & Title Syncer Pro")
        self.geometry("1100x800")
        
        # State
        self.supabase = None
        self.source_data = [] 
        self.target_data = [] 
        self.is_running = False
        self.stop_event = threading.Event()
        self.low_confidence_matches = [] # Store manual reviews here

        # Init UI
        self.create_sidebar()
        self.create_main_area()
        self.create_status_bar()
        
        # Auto-fill keys
        self.url_entry.insert(0, os.getenv("SUPABASE_URL", ""))
        self.key_entry.insert(0, os.getenv("SUPABASE_KEY", ""))

    # --- UI COMPONENTS ---
    def create_sidebar(self):
        sidebar = tb.Frame(self, bootstyle="secondary", padding=15)
        sidebar.pack(side=LEFT, fill=Y)
        
        tb.Label(sidebar, text="SETUP", font=("Helvetica", 12, "bold"), bootstyle="inverse-secondary").pack(anchor="w", pady=(0,10))
        
        tb.Label(sidebar, text="Supabase URL", bootstyle="inverse-secondary").pack(anchor="w")
        self.url_entry = tb.Entry(sidebar)
        self.url_entry.pack(fill=X, pady=(0,10))

        tb.Label(sidebar, text="Supabase Key", bootstyle="inverse-secondary").pack(anchor="w")
        self.key_entry = tb.Entry(sidebar, show="*")
        self.key_entry.pack(fill=X, pady=(0,10))

        tb.Button(sidebar, text="1. Fetch Data", command=self.fetch_data, bootstyle="success-outline").pack(fill=X, pady=10)
        
        tb.Separator(sidebar).pack(fill=X, pady=20)
        
        tb.Label(sidebar, text="SETTINGS", font=("Helvetica", 12, "bold"), bootstyle="inverse-secondary").pack(anchor="w", pady=(0,10))
        
        tb.Label(sidebar, text="Match Threshold", bootstyle="inverse-secondary").pack(anchor="w")
        self.threshold_var = tk.IntVar(value=90)
        self.lbl_thresh = tb.Label(sidebar, text="90%", bootstyle="warning-inverse")
        self.lbl_thresh.pack(anchor="e")
        tb.Scale(sidebar, variable=self.threshold_var, from_=50, to=100, command=self.update_thresh_label).pack(fill=X)
        
        tb.Separator(sidebar).pack(fill=X, pady=20)

        self.mode_var = tk.StringVar(value="TEST")
        tb.Checkbutton(sidebar, text="LIVE UPDATE DB", variable=self.mode_var, 
                       onvalue="LIVE", offvalue="TEST", bootstyle="danger-round-toggle").pack(fill=X, pady=10)
        
        tb.Label(sidebar, text="Updates Image AND Title.", font=("Arial", 8), bootstyle="secondary-inverse").pack(anchor="w")

    def create_main_area(self):
        main = tb.Frame(self, padding=20)
        main.pack(side=RIGHT, fill=BOTH, expand=True)

        # Header controls
        header = tb.Frame(main)
        header.pack(fill=X, pady=(0,15))
        
        self.btn_start = tb.Button(header, text="▶ START AUTO-MATCH", command=self.start_thread, state="disabled", bootstyle="primary")
        self.btn_start.pack(side=LEFT, padx=5)
        
        tb.Button(header, text="⏹ STOP", command=self.stop_process, bootstyle="danger").pack(side=LEFT, padx=5)

        # Logs
        self.log_area = ScrolledText(main, height=20, autohide=True, bootstyle="dark")
        self.log_area.pack(fill=BOTH, expand=True)
        self.log_area.text.tag_config("MATCH", foreground="#00ff00")
        self.log_area.text.tag_config("REVIEW", foreground="#ffcc00")
        self.log_area.text.tag_config("FAIL", foreground="#ff4444")

    def create_status_bar(self):
        self.status_var = tk.StringVar(value="Waiting to connect...")
        bar = tb.Label(self, textvariable=self.status_var, relief="sunken", anchor="w", padding=5, bootstyle="secondary-inverse")
        bar.pack(side=BOTTOM, fill=X)

    def update_thresh_label(self, val):
        self.lbl_thresh.config(text=f"{int(float(val))}%")

    def log(self, msg, tag="INFO"):
        self.log_area.text.configure(state='normal')
        self.log_area.text.insert(END, f"{msg}\n", tag)
        self.log_area.text.see(END)
        self.log_area.text.configure(state='disabled')

    # --- BACKEND LOGIC ---
    def fetch_data(self):
        try:
            url = self.url_entry.get()
            key = self.key_entry.get()
            self.supabase = create_client(url, key)
            
            self.status_var.set("Fetching SOURCE table...")
            self.update_idletasks()
            
            # Fetch Source (Original Cards)
            res_source = self.supabase.table('theory_cards').select("id, title_it, image_url").neq("image_url", "null").execute()
            self.source_data = res_source.data
            
            # Fetch Target (Duplicate Cards missing images)
            self.status_var.set("Fetching TARGET table...")
            res_target = self.supabase.table('theory_cards_duplicate').select("id, title_it, image_url").is_("image_url", "null").execute()
            self.target_data = res_target.data
            
            count_msg = f"✅ Data Loaded. Source: {len(self.source_data)} | Target: {len(self.target_data)}"
            self.log(count_msg, "MATCH")
            self.status_var.set(count_msg)
            
            if self.source_data and self.target_data:
                self.btn_start.configure(state="normal")
                
        except Exception as e:
            self.log(f"❌ Fetch Error: {e}", "FAIL")

    def start_thread(self):
        self.is_running = True
        self.stop_event.clear()
        self.low_confidence_matches = [] # Clear previous reviews
        self.btn_start.configure(state="disabled")
        threading.Thread(target=self.run_matching, daemon=True).start()

    def stop_process(self):
        self.is_running = False
        self.stop_event.set()
        self.status_var.set("Stopping...")

    def run_matching(self):
        threshold = self.threshold_var.get()
        is_live = self.mode_var.get() == "LIVE"
        
        # Map Title -> ImageURL
        # We assume source titles are mostly unique or we take the first occurrence
        title_to_img = {x['title_it']: x['image_url'] for x in self.source_data if x['title_it']}
        source_titles = list(title_to_img.keys())

        self.log(f"🚀 Started Matching (Threshold: {threshold}%)", "INFO")
        
        matches_found = 0
        
        for idx, target in enumerate(self.target_data):
            if self.stop_event.is_set(): break
            
            t_title = target.get('title_it')
            if not t_title: continue

            # Fuzzy Match
            res = process.extractOne(t_title, source_titles, scorer=fuzz.token_sort_ratio)
            
            if res:
                match_title, score, _ = res
                
                # CASE 1: High Confidence (Auto)
                if score >= threshold:
                    img_url = title_to_img.get(match_title)
                    self.log(f"✅ #{target['id']} ({score:.1f}%): Syncing Image & Title", "MATCH")
                    
                    if is_live:
                        self.supabase.table('theory_cards_duplicate').update({
                            "image_url": img_url,
                            "title_it": match_title  # <--- UPDATING TITLE HERE TOO
                        }).eq('id', target['id']).execute()
                    else:
                        self.log(f"   [TEST] Would set Img & Title: {match_title[:20]}...", "INFO")
                    
                    matches_found += 1
                
                # CASE 2: Low Confidence (Manual Review)
                elif score >= 60: 
                    self.low_confidence_matches.append({
                        "target_id": target['id'],
                        "target_title": t_title,
                        "source_title": match_title,
                        "source_img": title_to_img.get(match_title),
                        "score": score
                    })

            # Update status
            if idx % 10 == 0:
                self.status_var.set(f"Processing... {idx}/{len(self.target_data)}")

        self.is_running = False
        self.status_var.set("Done.")
        self.log(f"🏁 Finished. Auto-matched: {matches_found}", "MATCH")
        
        # Trigger Review Window on Main Thread if needed
        if self.low_confidence_matches:
            self.log(f"⚠️ Found {len(self.low_confidence_matches)} items for review.", "REVIEW")
            self.after(100, self.open_review_window)
        else:
            self.after(0, lambda: self.btn_start.configure(state="normal"))

    # --- REVIEW WINDOW ---
    def open_review_window(self):
        """ Opens a clean UI to handle 60-89% matches """
        rw = tb.Toplevel(self)
        rw.title(f"Review {len(self.low_confidence_matches)} Low Confidence Matches")
        rw.geometry("950x600")

        # Header
        tb.Label(rw, text="These items had similar titles but were below your threshold.", bootstyle="warning").pack(pady=10)
        
        # Scrolled container for rows
        container = ScrolledFrame(rw, autohide=True)
        container.pack(fill=BOTH, expand=True, padx=10, pady=10)
        
        # Column Headers
        headers = tb.Frame(container)
        headers.pack(fill=X, pady=5)
        tb.Label(headers, text="Score", width=8, font=("bold")).pack(side=LEFT)
        tb.Label(headers, text="Target (Duplicate)", width=30, font=("bold")).pack(side=LEFT)
        tb.Label(headers, text="Best Source Match (Will be copied)", width=30, font=("bold")).pack(side=LEFT)
        tb.Label(headers, text="Action", width=20, font=("bold")).pack(side=LEFT)

        # Populate Rows
        for match in self.low_confidence_matches:
            self.create_review_row(container, match)

        tb.Button(rw, text="Close", command=rw.destroy, bootstyle="secondary").pack(pady=10)
        self.btn_start.configure(state="normal")

    def create_review_row(self, parent, match):
        row = tb.Frame(parent, bootstyle="dark")
        row.pack(fill=X, pady=2, padx=5)
        
        # Score
        tb.Label(row, text=f"{match['score']:.1f}%", width=8, bootstyle="warning").pack(side=LEFT)
        
        # Titles (Wrapped)
        tb.Label(row, text=match['target_title'], width=30, wraplength=220).pack(side=LEFT, padx=5)
        tb.Label(row, text=match['source_title'], width=30, wraplength=220).pack(side=LEFT, padx=5)
        
        # Action Button
        def apply_fix():
            try:
                if self.mode_var.get() == "LIVE":
                    self.supabase.table('theory_cards_duplicate').update({
                        "image_url": match['source_img'],
                        "title_it": match['source_title'] # <--- UPDATING TITLE HERE TOO
                    }).eq('id', match['target_id']).execute()
                    
                    self.log(f"✅ Manual Sync ID {match['target_id']}", "MATCH")
                    row.destroy() # Remove from list
                else:
                    messagebox.showinfo("Test Mode", f"Would copy Image AND Title for ID {match['target_id']}")
                    row.destroy()
            except Exception as e:
                messagebox.showerror("Error", str(e))

        tb.Button(row, text="✅ Sync Image & Title", command=apply_fix, bootstyle="success-outline", width=20).pack(side=LEFT)

if __name__ == "__main__":
    app = ImageSyncerApp()
    app.mainloop()