import os
import tkinter as tk
from tkinter import messagebox
from supabase import create_client, Client
from dotenv import load_dotenv, find_dotenv
import threading
import requests

load_dotenv(find_dotenv())

# ================= CONFIGURATION =================
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
HF_TOKEN = os.getenv("HF_TOKEN")
API_URL = os.getenv("HF_API_URL", "https://router.huggingface.co/hf-inference/models/sentence-transformers/all-MiniLM-L6-v2")
# =================================================
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import time

class CloudAIMapperV3:
    def __init__(self, root):
        self.root = root
        self.root.title("Cloud AI Mapper (Robust V3)")
        self.root.geometry("650x700")
        self.root.configure(bg="#f0f0f0")

        self.matches_high = []   
        self.matches_medium = [] 
        self.matches_low = []    
        self.is_processing = False

        # Create a Session with Retry logic built-in
        self.session = requests.Session()
        retries = Retry(total=5, backoff_factor=1, status_forcelist=[500, 502, 503, 504])
        self.session.mount('https://', HTTPAdapter(max_retries=retries))

        try:
            self.supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
            print("Connected to Supabase")
        except Exception as e:
            messagebox.showerror("Connection Error", f"Could not connect:\n{e}")

        self._setup_ui()

    def _setup_ui(self):
        tk.Label(self.root, text="Cloud AI Auto-Mapper", font=("Segoe UI", 18, "bold"), bg="#f0f0f0").pack(pady=10)
        tk.Label(self.root, text="Version 3: Slow & Steady (Anti-Crash)", font=("Segoe UI", 10), bg="#f0f0f0", fg="#666").pack()

        self.status_frame = tk.LabelFrame(self.root, text="Status", bg="white")
        self.status_frame.pack(fill=tk.X, padx=20, pady=10)
        self.lbl_status = tk.Label(self.status_frame, text="Ready. Enter Token & Click Analyze.", bg="white", fg="#000", font=("Segoe UI", 11))
        self.lbl_status.pack(pady=10, padx=10)

        stats_frame = tk.LabelFrame(self.root, text="Match Results", bg="white", font=("Segoe UI", 10, "bold"))
        stats_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=5)

        self.lbl_high = self._create_stat_row(stats_frame, "High Confidence (> 60%)", "0", "green", 0)
        self.lbl_med = self._create_stat_row(stats_frame, "Medium Confidence (40-60%)", "0", "#FBC02D", 1)
        self.lbl_low = self._create_stat_row(stats_frame, "Low Confidence (< 40%)", "0", "red", 2)

        btn_frame = tk.Frame(self.root, bg="#f0f0f0")
        btn_frame.pack(fill=tk.X, padx=20, pady=20)

        self.btn_analyze = tk.Button(btn_frame, text="1. START ROBUST ANALYSIS", command=self.start_analysis, 
                                     bg="#673AB7", fg="white", font=("Segoe UI", 11, "bold"), height=2)
        self.btn_analyze.pack(fill=tk.X, pady=5)

        self.btn_update = tk.Button(btn_frame, text="2. MERGE HIGH CONFIDENCE ITEMS", command=self.start_bulk_update, 
                                    bg="gray", fg="white", font=("Segoe UI", 11, "bold"), height=2, state=tk.DISABLED)
        self.btn_update.pack(fill=tk.X, pady=5)

    def _create_stat_row(self, parent, label, value, color, row):
        tk.Label(parent, text=label, bg="white", font=("Segoe UI", 11)).grid(row=row, column=0, sticky="w", padx=20, pady=15)
        lbl = tk.Label(parent, text=value, bg="white", fg=color, font=("Segoe UI", 14, "bold"))
        lbl.grid(row=row, column=1, sticky="e", padx=20, pady=15)
        parent.grid_columnconfigure(1, weight=1)
        return lbl

    # ================= LOGIC =================

    def query_similarity_api(self, source_text, candidate_texts):
        """Robust API Call with Error Handling"""
        headers = {"Authorization": f"Bearer {HF_TOKEN}"}
        payload = {
            "inputs": {
                "source_sentence": source_text,
                "sentences": candidate_texts
            },
            "options": {"wait_for_model": True}
        }
        
        attempt = 0
        max_retries = 3
        
        while attempt < max_retries:
            try:
                # Use the session for connection pooling (Fixes NameResolutionError)
                response = self.session.post(API_URL, headers=headers, json=payload, timeout=30)
                
                # Check for 504 / 503 (Model Loading)
                if response.status_code in [503, 504]:
                    self.update_status(f"Model waking up... (Attempt {attempt+1})")
                    time.sleep(10) # Wait 10 seconds for model to load
                    attempt += 1
                    continue
                
                # Check for other errors
                if response.status_code != 200:
                    print(f"API Error {response.status_code}: {response.text[:100]}...") # Print only start of error
                    return None

                # Success
                return response.json()
                
            except Exception as e:
                print(f"Network Exception: {e}")
                time.sleep(2) # Short pause on network error
                attempt += 1
                
        return None

    def start_analysis(self):
        if self.is_processing: return
        self.is_processing = True
        self.btn_analyze.config(state=tk.DISABLED)
        threading.Thread(target=self.run_analysis_thread).start()

    def run_analysis_thread(self):
        try:
            self.update_status("Fetching data from Supabase...")
            sub_res = self.supabase.table('subtopics').select('id, name_it').execute()
            card_res = self.supabase.table('theory_cards').select('id, title_it').execute()
            
            subtopics = sub_res.data
            cards = card_res.data
            
            sub_names = [s['name_it'] for s in subtopics]
            
            self.matches_high = []
            self.matches_medium = []
            self.matches_low = []
            report_lines = []

            total = len(cards)
            
            for i, card in enumerate(cards):
                card_title = card['title_it']
                
                # Update status less frequently to save UI resources
                if i % 1 == 0: 
                    self.update_status(f"Analyzing {i+1}/{total}: {card_title[:25]}...")

                scores = self.query_similarity_api(card_title, sub_names)
                
                if scores:
                    max_score = max(scores)
                    best_index = scores.index(max_score)
                    best_sub = subtopics[best_index]
                    
                    match_data = {
                        'card_id': card['id'],
                        'card_title': card_title,
                        'sub_id': best_sub['id'],
                        'sub_name': best_sub['name_it'],
                        'score': max_score
                    }

                    if max_score >= 0.6: 
                        self.matches_high.append(match_data)
                        print(f"High match: {match_data}")
                    elif max_score >= 0.4:
                        self.matches_medium.append(match_data)
                        print(f"Medium match: {match_data}")
                    else:
                        self.matches_low.append(match_data)
                        print(f"Low match: {match_data}")
                        
                    report_lines.append(match_data)
                
                # IMPORTANT: Slow down to prevent DNS/Connection errors
                time.sleep(1.0) 

            self.generate_report(report_lines)
            self.root.after(0, self.on_analysis_complete)

        except Exception as e:
            print(e)
            self.root.after(0, lambda: messagebox.showerror("Error", str(e)))
            self.is_processing = False
            self.root.after(0, lambda: self.btn_analyze.config(state=tk.NORMAL))

    def update_status(self, text):
        self.root.after(0, lambda: self.lbl_status.config(text=text))

    def generate_report(self, all_matches):
        all_matches.sort(key=lambda x: x['score'], reverse=True)
        with open("robust_similarity_report.txt", "w", encoding="utf-8") as f:
            f.write("AI SIMILARITY REPORT (ROBUST)\n=============================\n")
            for m in all_matches:
                f.write(f"[{int(m['score']*100)}%] {m['card_title']} -> {m['sub_name']}\n")

    def on_analysis_complete(self):
        self.is_processing = False
        self.lbl_high.config(text=str(len(self.matches_high)))
        self.lbl_med.config(text=str(len(self.matches_medium)))
        self.lbl_low.config(text=str(len(self.matches_low)))
        self.lbl_status.config(text="Done. Check 'robust_similarity_report.txt'")
        self.btn_analyze.config(state=tk.NORMAL)
        
        if self.matches_high:
            self.btn_update.config(state=tk.NORMAL, bg="#4CAF50", text=f"MERGE {len(self.matches_high)} ITEMS")
        else:
            self.btn_update.config(state=tk.DISABLED, text="NO GOOD MATCHES")

    def start_bulk_update(self):
        if not messagebox.askyesno("Confirm", f"Update {len(self.matches_high)} cards?"): return
        self.btn_update.config(state=tk.DISABLED, text="Updating...")
        threading.Thread(target=self.run_update_thread).start()

    def run_update_thread(self):
        success = 0
        for i, item in enumerate(self.matches_high):
            if i % 5 == 0: self.update_status(f"Saving {i}/{len(self.matches_high)}...")
            try:
                self.supabase.table('theory_cards').update({'subtopic_id': item['sub_id']}).eq('id', item['card_id']).execute()
                success += 1
            except: pass
        
        self.root.after(0, lambda: messagebox.showinfo("Success", f"Updated {success} cards!"))
        self.root.after(0, lambda: self.btn_update.config(text="MERGE COMPLETE"))

if __name__ == "__main__":
    root = tk.Tk()
    app = CloudAIMapperV3(root)
    root.mainloop()