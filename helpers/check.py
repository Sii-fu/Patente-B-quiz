import os
import tkinter as tk
from tkinter import messagebox, scrolledtext
from PIL import Image, ImageTk, ImageGrab
from supabase import create_client, Client
from dotenv import load_dotenv
import io
import re
import threading

load_dotenv()

# ================= CONFIGURATION =================
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
BUCKET_NAME = "quiz_images"
# =================================================

class ImageMismatchCheckerApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Figure Mismatch Checker & Fixer")
        self.root.geometry("700x800")
        self.root.configure(bg="#f0f0f0")

        self.mismatches = []
        self.current_mismatch = None
        self.current_index = 0
        self.is_uploading = False

        # Initialize Supabase
        try:
            self.supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
            print("Connected to Supabase")
        except Exception as e:
            messagebox.showerror("Connection Error", f"Could not connect:\n{e}")

        self._setup_ui()
        # Start scanning in background
        self.root.after(100, self._scan_for_mismatches)

    def _setup_ui(self):
        # Header
        tk.Label(self.root, text="🔍 Figure Mismatch Detector", 
                font=("Segoe UI", 16, "bold"), bg="#f0f0f0").pack(pady=10)

        # Status Frame
        status_frame = tk.Frame(self.root, bg="white", bd=2, relief=tk.GROOVE)
        status_frame.pack(pady=5, fill=tk.X, padx=20)
        
        tk.Label(status_frame, text="Scanning Status:", bg="white", 
                font=("Segoe UI", 10, "bold"), fg="#555").pack(anchor=tk.W, padx=10, pady=(5,0))
        self.lbl_scan_status = tk.Label(status_frame, text="Initializing...", bg="white", 
                                       font=("Segoe UI", 11), fg="#FF5722")
        self.lbl_scan_status.pack(anchor=tk.W, padx=10, pady=5)

        # Mismatch Info Card
        info_frame = tk.Frame(self.root, bg="white", bd=2, relief=tk.RAISED)
        info_frame.pack(pady=10, fill=tk.X, padx=20)
        
        tk.Label(info_frame, text="Expected Figure:", bg="white", 
                font=("Segoe UI", 10, "bold"), fg="#555").pack(anchor=tk.W, padx=10, pady=(5,0))
        self.lbl_expected_fig = tk.Label(info_frame, text="---", bg="white", 
                                        font=("Segoe UI", 14, "bold"), fg="#D32F2F")
        self.lbl_expected_fig.pack(anchor=tk.W, padx=10, pady=5)

        tk.Label(info_frame, text="Current Image URL:", bg="white", 
                font=("Segoe UI", 10, "bold"), fg="#555").pack(anchor=tk.W, padx=10)
        self.lbl_current_url = tk.Label(info_frame, text="---", bg="white", 
                                       font=("Segoe UI", 9), fg="#666", wraplength=600)
        self.lbl_current_url.pack(anchor=tk.W, padx=10, pady=(0,5))

        tk.Label(info_frame, text="Affected Questions:", bg="white", 
                font=("Segoe UI", 10, "bold"), fg="#555").pack(anchor=tk.W, padx=10)
        self.lbl_affected_count = tk.Label(info_frame, text="---", bg="white", 
                                          font=("Segoe UI", 10, "bold"), fg="#FF9800")
        self.lbl_affected_count.pack(anchor=tk.W, padx=10, pady=(0,5))

        # Sample Question Display
        tk.Label(self.root, text="📝 Sample Question (Verify this is correct):", 
                bg="#f0f0f0", font=("Segoe UI", 10, "bold")).pack(pady=(10,5))
        
        self.txt_sample_question = scrolledtext.ScrolledText(
            self.root, height=4, wrap=tk.WORD, font=("Segoe UI", 10),
            bg="#FFF9C4", bd=2, relief=tk.GROOVE
        )
        self.txt_sample_question.pack(fill=tk.X, padx=20, pady=5)
        self.txt_sample_question.config(state=tk.DISABLED)

        # Instructions
        tk.Label(self.root, text="1. Snapshot correct figure from PDF (Win+Shift+S)  |  2. Paste below", 
                bg="#f0f0f0", fg="#666", font=("Segoe UI", 9)).pack(pady=5)

        # Paste Button
        self.btn_paste = tk.Button(self.root, text="📋 PASTE IMAGE (Ctrl+V)", 
                                   command=self.paste_image, 
                                   bg="#2196F3", fg="white", font=("Segoe UI", 11, "bold"), 
                                   height=2, relief=tk.FLAT, state=tk.DISABLED)
        self.btn_paste.pack(pady=5, fill=tk.X, padx=20)

        # Preview
        self.lbl_preview = tk.Label(self.root, text="[ No Image ]", bg="#e0e0e0", height=12)
        self.lbl_preview.pack(fill=tk.BOTH, expand=True, padx=20, pady=5)

        # Action Buttons Frame
        button_frame = tk.Frame(self.root, bg="#f0f0f0")
        button_frame.pack(pady=10, fill=tk.X, padx=20)

        # Upload Button
        self.btn_upload = tk.Button(button_frame, text="✅ FIX & UPDATE DATABASE", 
                                    command=self.start_upload_thread, 
                                    bg="#4CAF50", fg="white", font=("Segoe UI", 12, "bold"), 
                                    state=tk.DISABLED, height=2, relief=tk.FLAT)
        self.btn_upload.pack(side=tk.LEFT, expand=True, fill=tk.X, padx=(0, 5))

        # Skip Button
        self.btn_skip = tk.Button(button_frame, text="⏭️ SKIP THIS", 
                                 command=self.skip_current, 
                                 bg="#FF9800", fg="white", font=("Segoe UI", 12, "bold"), 
                                 state=tk.DISABLED, height=2, relief=tk.FLAT)
        self.btn_skip.pack(side=tk.RIGHT, expand=True, fill=tk.X, padx=(5, 0))

        # Status Bar
        self.status_var = tk.StringVar(value="Initializing...")
        tk.Label(self.root, textvariable=self.status_var, bd=1, relief=tk.SUNKEN, 
                anchor=tk.W, bg="#333", fg="white", font=("Segoe UI", 9)).pack(side=tk.BOTTOM, fill=tk.X)

        # Bindings
        self.root.bind('<Return>', lambda e: self.start_upload_thread())
        self.root.bind('<Control-v>', lambda e: self.paste_image())

    def _scan_for_mismatches(self):
        """Scan database for questions with figure references but mismatched image_url"""
        self.lbl_scan_status.config(text="🔄 Scanning database for mismatches...")
        self.status_var.set("Fetching all questions from database...")
        self.root.update_idletasks()
        
        try:
            # Get ALL questions using pagination (Supabase has 1000 row default limit)
            all_questions = []
            page_size = 1000
            offset = 0
            
            while True:
                response = self.supabase.table('questions') \
                    .select('id, text_it, image_url') \
                    .range(offset, offset + page_size - 1) \
                    .execute()
                
                if not response.data:
                    break
                    
                all_questions.extend(response.data)
                print(f"Fetched batch: {len(response.data)} questions (Total so far: {len(all_questions)})")
                
                # Update status during fetch
                self.status_var.set(f"Fetching questions... ({len(all_questions)} loaded)")
                self.root.update_idletasks()
                
                if len(response.data) < page_size:
                    break  # Last page
                    
                offset += page_size
            
            print(f"✅ Fetched ALL {len(all_questions)} questions from DB")
            
            # Find mismatches
            mismatches_dict = {}  # Key: expected_fig, Value: list of question records
            
            for question in all_questions:
                text = question.get('text_it', '')
                image_url = question.get('image_url', '') or ''
                
                # Extract figure number from text using regex
                # Patterns: "figura 123", "fig. 123", "fig 123", "figure 123"
                fig_match = re.search(r'\b(?:figura|fig\.?|figure)\s*(\d+)\b', text, re.IGNORECASE)
                
                if fig_match:
                    expected_fig_num = fig_match.group(1)
                    expected_fig_name = f"fig_{expected_fig_num}.png"
                    
                    # Check if image_url contains this figure number
                    if expected_fig_num not in image_url:
                        # MISMATCH FOUND!
                        if expected_fig_name not in mismatches_dict:
                            mismatches_dict[expected_fig_name] = []
                        mismatches_dict[expected_fig_name].append(question)
            
            # Convert to list format
            self.mismatches = [
                {
                    'expected_fig': fig_name,
                    'questions': questions,
                    'sample_question': questions[0]  # Use first as sample
                }
                for fig_name, questions in mismatches_dict.items()
            ]
            
            print(f"Found {len(self.mismatches)} figure mismatches")
            
            if len(self.mismatches) > 0:
                self.lbl_scan_status.config(
                    text=f"⚠️ Found {len(self.mismatches)} mismatches!", 
                    fg="#D32F2F"
                )
                self._load_mismatch(0)
            else:
                self._show_all_clear()
                
        except Exception as e:
            messagebox.showerror("Scan Error", f"Failed to scan database:\n{e}")
            self.lbl_scan_status.config(text="❌ Scan failed", fg="red")

    def _load_mismatch(self, index):
        """Load a specific mismatch for fixing"""
        if index < len(self.mismatches):
            self.current_index = index
            self.current_mismatch = self.mismatches[index]
            
            expected_fig = self.current_mismatch['expected_fig']
            questions = self.current_mismatch['questions']
            sample = self.current_mismatch['sample_question']
            
            self.lbl_expected_fig.config(text=expected_fig)
            self.lbl_current_url.config(
                text=sample['image_url'][:100] + "..." if len(sample['image_url']) > 100 
                     else sample['image_url'] if sample['image_url'] else "(NULL)"
            )
            self.lbl_affected_count.config(text=f"{len(questions)} question(s) affected")
            
            # Show sample question
            self.txt_sample_question.config(state=tk.NORMAL)
            self.txt_sample_question.delete('1.0', tk.END)
            self.txt_sample_question.insert('1.0', sample['text_it'])
            self.txt_sample_question.config(state=tk.DISABLED)
            
            self.status_var.set(f"Mismatch {index + 1}/{len(self.mismatches)}: Waiting for correct image...")
            
            # Enable buttons
            self.btn_paste.config(state=tk.NORMAL)
            self.btn_skip.config(state=tk.NORMAL)
            
            # Reset UI elements
            self.lbl_preview.config(image='', text="[ Paste Image Here ]")
            self.current_image = None
            self.btn_upload.config(state=tk.DISABLED, bg="gray")
        else:
            self._show_all_clear()

    def paste_image(self):
        """Handle image paste from clipboard"""
        try:
            image = ImageGrab.grabclipboard()
            if isinstance(image, Image.Image):
                self.current_image = image
                
                # Preview
                preview = image.copy()
                preview.thumbnail((550, 400))
                self.photo = ImageTk.PhotoImage(preview)
                self.lbl_preview.config(image=self.photo, text="")
                
                self.btn_upload.config(state=tk.NORMAL, bg="#4CAF50")
                self.status_var.set("✅ Image ready. Press ENTER or click 'FIX & UPDATE'")
            else:
                messagebox.showwarning("No Image", "Clipboard does not contain an image.")
                self.status_var.set("❌ No image in clipboard")
        except Exception as e:
            messagebox.showerror("Paste Error", str(e))

    def start_upload_thread(self):
        """Start upload process in background thread"""
        if not self.current_image or self.is_uploading or not self.current_mismatch:
            return
        
        self.is_uploading = True
        self.btn_upload.config(text="⏳ Uploading...", state=tk.DISABLED)
        self.btn_skip.config(state=tk.DISABLED)
        self.btn_paste.config(state=tk.DISABLED)
        threading.Thread(target=self.upload_and_fix).start()

    def upload_and_fix(self):
        """Upload image and update all affected questions"""
        try:
            # 1. Prepare Image
            img_byte_arr = io.BytesIO()
            self.current_image.save(img_byte_arr, format='PNG')
            img_byte_arr = img_byte_arr.getvalue()

            # 2. Upload to Storage
            file_name = self.current_mismatch['expected_fig']
            self.supabase.storage.from_(BUCKET_NAME).upload(
                path=file_name,
                file=img_byte_arr,
                file_options={"content-type": "image/png", "x-upsert": "true"}
            )

            # 3. Get Public URL
            public_url = self.supabase.storage.from_(BUCKET_NAME).get_public_url(file_name)

            # 4. BULK UPDATE all affected questions
            affected_ids = [q['id'] for q in self.current_mismatch['questions']]
            
            for question_id in affected_ids:
                self.supabase.table('questions') \
                    .update({'image_url': public_url}) \
                    .eq('id', question_id) \
                    .execute()
            
            print(f"Updated {len(affected_ids)} questions with {public_url}")

            # 5. Success - Move to next
            self.root.after(0, self.on_upload_success)

        except Exception as e:
            self.root.after(0, lambda: messagebox.showerror("Upload Error", str(e)))
            self.root.after(0, self._reset_buttons)
            self.is_uploading = False

    def on_upload_success(self):
        """Handle successful upload"""
        self.is_uploading = False
        messagebox.showinfo("Success", 
                          f"✅ Fixed {len(self.current_mismatch['questions'])} question(s)!")
        
        # Remove from list and move to next
        self.mismatches.pop(self.current_index)
        
        if len(self.mismatches) > 0:
            # Adjust index if needed
            if self.current_index >= len(self.mismatches):
                self.current_index = len(self.mismatches) - 1
            self._load_mismatch(self.current_index)
        else:
            self._show_all_clear()

    def skip_current(self):
        """Skip current mismatch and move to next"""
        if messagebox.askyesno("Skip", "Skip this mismatch for now?"):
            self.current_index += 1
            if self.current_index >= len(self.mismatches):
                self.current_index = 0  # Loop back
            self._load_mismatch(self.current_index)

    def _reset_buttons(self):
        """Reset button states after error"""
        self.btn_upload.config(text="✅ FIX & UPDATE DATABASE", state=tk.DISABLED, bg="gray")
        self.btn_skip.config(state=tk.NORMAL)
        self.btn_paste.config(state=tk.NORMAL)

    def _show_all_clear(self):
        """Show completion message when no mismatches remain"""
        self.lbl_scan_status.config(text="✅ All Clear! No mismatches found.", fg="green")
        self.lbl_expected_fig.config(text="N/A", fg="green")
        self.lbl_current_url.config(text="Database is consistent")
        self.lbl_affected_count.config(text="0 issues")
        
        self.txt_sample_question.config(state=tk.NORMAL)
        self.txt_sample_question.delete('1.0', tk.END)
        self.txt_sample_question.insert('1.0', "No questions need fixing. Great job!")
        self.txt_sample_question.config(state=tk.DISABLED)
        
        self.btn_paste.config(state=tk.DISABLED)
        self.btn_skip.config(state=tk.DISABLED)
        self.btn_upload.config(state=tk.DISABLED)
        self.status_var.set("✨ All figure references are correctly mapped!")

if __name__ == "__main__":
    root = tk.Tk()
    app = ImageMismatchCheckerApp(root)
    root.mainloop()
