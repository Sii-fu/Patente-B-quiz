import os
import tkinter as tk
from tkinter import messagebox
from supabase import create_client, Client
from dotenv import load_dotenv, find_dotenv
import threading
from difflib import SequenceMatcher

load_dotenv(find_dotenv())

# ================= CONFIGURATION =================
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

class AutoMapperDashboard:
    def __init__(self, root):
        self.root = root
        self.root.title("Theory <-> Subtopic Bulk Mapper")
        self.root.geometry("600x600")
        self.root.configure(bg="#f0f0f0")

        self.matches_90_plus = []
        self.matches_80_90 = []
        self.matches_70_80 = []
        self.matches_low = []

        self.is_processing = False

        # Initialize Supabase
        try:
            self.supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
            print("Connected to Supabase")
        except Exception as e:
            messagebox.showerror("Connection Error", f"Could not connect:\n{e}")

        self._setup_ui()

    def _setup_ui(self):
        # Header
        tk.Label(self.root, text="Database Alignment Dashboard", font=("Segoe UI", 18, "bold"), bg="#f0f0f0").pack(pady=15)

        # Status Section
        self.status_frame = tk.LabelFrame(self.root, text="Analysis Status", bg="white", font=("Segoe UI", 10))
        self.status_frame.pack(fill=tk.X, padx=20, pady=5)
        
        self.lbl_status = tk.Label(self.status_frame, text="Ready to Analyze", bg="white", fg="#555", font=("Segoe UI", 11))
        self.lbl_status.pack(pady=10, padx=10)

        # Statistics Section
        stats_frame = tk.LabelFrame(self.root, text="Match Statistics", bg="white", font=("Segoe UI", 10, "bold"))
        stats_frame.pack(fill=tk.BOTH, expand=True, padx=20, pady=10)

        # Grid for stats
        self.lbl_count_90 = self._create_stat_row(stats_frame, "Matches > 90% (Safe to Merge)", "0", "green", 0)
        self.lbl_count_80 = self._create_stat_row(stats_frame, "Matches 80% - 90%", "0", "#FBC02D", 1) # Yellow
        self.lbl_count_70 = self._create_stat_row(stats_frame, "Matches 70% - 80%", "0", "orange", 2)
        self.lbl_count_low = self._create_stat_row(stats_frame, "Matches < 70% (Likely Unrelated)", "0", "red", 3)

        # Buttons Section
        btn_frame = tk.Frame(self.root, bg="#f0f0f0")
        btn_frame.pack(fill=tk.X, padx=20, pady=20)

        self.btn_analyze = tk.Button(btn_frame, text="1. RUN ANALYSIS & GENERATE LOG", command=self.start_analysis, 
                                     bg="#2196F3", fg="white", font=("Segoe UI", 11, "bold"), height=2)
        self.btn_analyze.pack(fill=tk.X, pady=5)

        self.btn_update = tk.Button(btn_frame, text="2. MERGE > 90% TO DATABASE", command=self.start_bulk_update, 
                                    bg="gray", fg="white", font=("Segoe UI", 11, "bold"), height=2, state=tk.DISABLED)
        self.btn_update.pack(fill=tk.X, pady=5)

    def _create_stat_row(self, parent, label_text, value_text, color, row):
        tk.Label(parent, text=label_text, bg="white", font=("Segoe UI", 11)).grid(row=row, column=0, sticky="w", padx=20, pady=10)
        lbl_val = tk.Label(parent, text=value_text, bg="white", fg=color, font=("Segoe UI", 14, "bold"))
        lbl_val.grid(row=row, column=1, sticky="e", padx=20, pady=10)
        parent.grid_columnconfigure(1, weight=1) # Push value to right
        return lbl_val

    # ================= LOGIC =================

    def start_analysis(self):
        if self.is_processing: return
        self.is_processing = True
        self.btn_analyze.config(state=tk.DISABLED)
        self.btn_update.config(state=tk.DISABLED, bg="gray")
        self.lbl_status.config(text="Fetching Data from DB...")
        
        threading.Thread(target=self.run_analysis_thread).start()

    def run_analysis_thread(self):
        try:
            # 1. Fetch Data
            sub_res = self.supabase.table('subtopics').select('id, name_it').execute()
            card_res = self.supabase.table('theory_cards').select('id, title_it').execute()
            
            subtopics = sub_res.data
            cards = card_res.data

            self.root.after(0, lambda: self.lbl_status.config(text=f"Comparing {len(cards)} cards vs {len(subtopics)} subtopics..."))

            # 2. Reset Lists
            self.matches_90_plus = []
            self.matches_80_90 = []
            self.matches_70_80 = []
            self.matches_low = []
            all_results = []

            # 3. Analyze
            for card in cards:
                card_title = str(card.get('title_it', '')).lower().strip()
                best_score = 0.0
                best_sub = None

                for sub in subtopics:
                    sub_name = str(sub.get('name_it', '')).lower().strip()
                    score = SequenceMatcher(None, card_title, sub_name).ratio()
                    
                    if score > best_score:
                        best_score = score
                        best_sub = sub
                
                # Store Result
                match_data = {
                    'card_id': card['id'],
                    'card_title': card.get('title_it', 'N/A'),
                    'sub_id': best_sub['id'] if best_sub else None,
                    'sub_name': best_sub['name_it'] if best_sub else 'No Match',
                    'score': best_score
                }
                
                all_results.append(match_data)

                # Categorize
                if best_score >= 0.9:
                    self.matches_90_plus.append(match_data)
                elif best_score >= 0.8:
                    self.matches_80_90.append(match_data)
                elif best_score >= 0.7:
                    self.matches_70_80.append(match_data)
                else:
                    self.matches_low.append(match_data)

            # 4. Generate Text File
            self.generate_report_file(all_results)

            # 5. Update UI
            self.root.after(0, self.on_analysis_complete)

        except Exception as e:
            print(f"Error: {e}")
            self.root.after(0, lambda: messagebox.showerror("Error", str(e)))
            self.is_processing = False

    def generate_report_file(self, all_results):
        # Sort by score descending
        all_results.sort(key=lambda x: x['score'], reverse=True)

        filename = "comparison_report.txt"
        with open(filename, "w", encoding="utf-8") as f:
            f.write("THEORY CARD TO SUBTOPIC MATCH REPORT\n")
            f.write("====================================\n\n")
            
            f.write(f"High Confidence (>= 90%): {len(self.matches_90_plus)}\n")
            f.write(f"Medium Confidence (80-89%): {len(self.matches_80_90)}\n")
            f.write(f"Low Confidence (< 80%): {len(self.matches_70_80) + len(self.matches_low)}\n\n")
            f.write("DETAILED LIST:\n")
            f.write("Score | Theory Card Title  ==>  Predicted Subtopic\n")
            f.write("-" * 80 + "\n")

            for item in all_results:
                score_pct = int(item['score'] * 100)
                line = f"[{score_pct}%] {item['card_title']}  ==>  {item['sub_name']}\n"
                f.write(line)
        
        print(f"Report generated: {filename}")

    def on_analysis_complete(self):
        self.is_processing = False
        
        # Update Counts
        self.lbl_count_90.config(text=str(len(self.matches_90_plus)))
        self.lbl_count_80.config(text=str(len(self.matches_80_90)))
        self.lbl_count_70.config(text=str(len(self.matches_70_80)))
        self.lbl_count_low.config(text=str(len(self.matches_low)))

        self.lbl_status.config(text="Analysis Complete. Report saved to 'comparison_report.txt'")
        self.btn_analyze.config(state=tk.NORMAL)
        
        # Enable Update button if we have matches
        if len(self.matches_90_plus) > 0:
            self.btn_update.config(state=tk.NORMAL, bg="#4CAF50", text=f"MERGE {len(self.matches_90_plus)} ITEMS TO DATABASE")
        else:
            self.btn_update.config(state=tk.DISABLED, text="NO HIGH CONFIDENCE MATCHES")

    # ================= BULK UPDATE =================

    def start_bulk_update(self):
        if not self.matches_90_plus: return
        
        confirm = messagebox.askyesno("Confirm Merge", 
                                      f"Are you sure you want to update {len(self.matches_90_plus)} Theory Cards?\n\n"
                                      "This will assign the 'subtopic_id' in the database.")
        if not confirm: return

        self.is_processing = True
        self.btn_update.config(state=tk.DISABLED, text="Updating Database...")
        self.btn_analyze.config(state=tk.DISABLED)
        
        threading.Thread(target=self.run_update_thread).start()

    def run_update_thread(self):
        success_count = 0
        fail_count = 0
        total = len(self.matches_90_plus)

        try:
            for index, item in enumerate(self.matches_90_plus):
                # Update Status occasionally
                if index % 5 == 0:
                     self.root.after(0, lambda i=index: self.lbl_status.config(text=f"Updating {i+1}/{total}..."))

                try:
                    # EXECUTE DB UPDATE
                    self.supabase.table('theory_cards').update({
                        'subtopic_id': item['sub_id']
                    }).eq('id', item['card_id']).execute()
                    
                    success_count += 1
                except Exception as e:
                    print(f"Failed to update card {item['card_id']}: {e}")
                    fail_count += 1

            self.root.after(0, lambda: self.on_update_complete(success_count, fail_count))

        except Exception as global_e:
            self.root.after(0, lambda: messagebox.showerror("Critical Error", str(global_e)))
            self.is_processing = False

    def on_update_complete(self, success, fail):
        self.is_processing = False
        self.lbl_status.config(text=f"Update Finished. Success: {success}, Failed: {fail}")
        messagebox.showinfo("Complete", f"Database updated successfully.\nUpdated: {success}\nFailed: {fail}")
        
        # Reset buttons
        self.btn_analyze.config(state=tk.NORMAL)
        self.btn_update.config(state=tk.DISABLED, bg="gray", text="MERGE COMPLETE")
        self.matches_90_plus = [] # Clear list so they don't click again immediately

if __name__ == "__main__":
    root = tk.Tk()
    app = AutoMapperDashboard(root)
    root.mainloop()