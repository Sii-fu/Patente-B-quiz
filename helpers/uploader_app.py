import os
import tkinter as tk
from tkinter import messagebox
from PIL import Image, ImageTk, ImageGrab
from supabase import create_client, Client
from dotenv import load_dotenv
import io
import threading # To prevent app freezing during upload

load_dotenv()

# ================= CONFIGURATION =================
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

BUCKET_NAME = "quiz_images"
BATCH_SIZE = 50 
# =================================================

class ImageUploaderApp:
    def __init__(self, root):
        self.root = root
        self.root.title("Supabase Mass Uploader")
        self.root.geometry("600x700")
        self.root.configure(bg="#f0f0f0")

        self.questions_batch = []
        self.current_question = None
        self.is_uploading = False

        # Initialize Supabase
        try:
            self.supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
            print("Connected to Supabase")
        except Exception as e:
            messagebox.showerror("Connection Error", f"Could not connect:\n{e}")

        self._setup_ui()
        # Start loading in background to not freeze UI
        self.root.after(100, self._load_next_batch)

    def _setup_ui(self):
        # Header
        tk.Label(self.root, text="Quiz Image Mapper", font=("Segoe UI", 16, "bold"), bg="#f0f0f0").pack(pady=10)

        # Info Card
        info_frame = tk.Frame(self.root, bg="white", bd=1, relief=tk.RAISED)
        info_frame.pack(pady=5, fill=tk.X, padx=20)
        
        tk.Label(info_frame, text="Looking for:", bg="white", font=("Segoe UI", 10, "bold"), fg="#555").pack(anchor=tk.W, padx=10, pady=(5,0))
        self.lbl_fig_name = tk.Label(info_frame, text="Loading...", bg="white", font=("Segoe UI", 14, "bold"), fg="#D32F2F")
        self.lbl_fig_name.pack(anchor=tk.W, padx=10, pady=5)

        tk.Label(info_frame, text="Context (Question):", bg="white", font=("Segoe UI", 10, "bold"), fg="#555").pack(anchor=tk.W, padx=10)
        self.lbl_question_text = tk.Label(info_frame, text="...", bg="white", font=("Segoe UI", 10), wraplength=500, justify=tk.LEFT)
        self.lbl_question_text.pack(anchor=tk.W, padx=10, pady=(0, 10))

        # Instructions
        tk.Label(self.root, text="1. Snapshot PDF (Win+Shift+S)  |  2. Click Paste or Ctrl+V", bg="#f0f0f0", fg="#666").pack(pady=5)

        # Paste Button
        self.btn_paste = tk.Button(self.root, text="PASTE IMAGE (Ctrl+V)", command=self.paste_image, 
                              bg="#2196F3", fg="white", font=("Segoe UI", 11, "bold"), height=2, relief=tk.FLAT)
        self.btn_paste.pack(pady=5, fill=tk.X, padx=20)

        # Preview
        self.lbl_preview = tk.Label(self.root, text="[ No Image in Clipboard ]", bg="#e0e0e0", height=15)
        self.lbl_preview.pack(fill=tk.BOTH, expand=True, padx=20, pady=5)

        # Upload Button
        self.btn_upload = tk.Button(self.root, text="UPLOAD & SAVE", command=self.start_upload_thread, 
                                    bg="#4CAF50", fg="white", font=("Segoe UI", 12, "bold"), state=tk.DISABLED, height=2, relief=tk.FLAT)
        self.btn_upload.pack(pady=15, fill=tk.X, padx=20)

        # Status Bar
        self.status_var = tk.StringVar(value="Initializing...")
        tk.Label(self.root, textvariable=self.status_var, bd=1, relief=tk.SUNKEN, anchor=tk.W, bg="#333", fg="white").pack(side=tk.BOTTOM, fill=tk.X)

        # Bindings
        self.root.bind('<Return>', lambda e: self.start_upload_thread())
        self.root.bind('<Control-v>', lambda e: self.paste_image())

    def _load_next_batch(self):
        self.status_var.set("Fetching questions from DB...")
        self.root.update_idletasks()
        
        try:
            # Logic: Get rows where image_url is NOT NULL and NOT a URL yet
            response = self.supabase.table('questions') \
                .select('id, text_it, image_url') \
                .not_.is_('image_url', 'null') \
                .not_.ilike('image_url', 'http%') \
                .limit(BATCH_SIZE) \
                .execute()
            
            print("Fetched batch from DB:", response.data)
            self.questions_batch = response.data
            
            if len(self.questions_batch) > 0:
                self._load_current_question(0)
            else:
                self._show_complete()
                
        except Exception as e:
            messagebox.showerror("DB Error", str(e))

    def _load_current_question(self, index):
        if index < len(self.questions_batch):
            self.current_question = self.questions_batch[index]
            
            # CLEANUP FILE NAME LOGIC
            raw_val = self.current_question['image_url']
            # If DB says "fig_910.png", keep it. If "910", make it "fig_910.png"
            if "fig_" not in raw_val:
                self.target_filename = f"fig_{raw_val}.png"
            elif not raw_val.endswith(".png"):
                self.target_filename = f"{raw_val}.png"
            else:
                self.target_filename = raw_val

            self.lbl_fig_name.config(text=self.target_filename)
            self.lbl_question_text.config(text=self.current_question['text_it'][:200] + "...")
            self.status_var.set(f"Waiting for image: {self.target_filename}")
            
            # Reset UI elements
            self.lbl_preview.config(image='', text="Paste Image Here")
            self.current_image = None
            self.btn_upload.config(state=tk.DISABLED, bg="gray")
        else:
            self._load_next_batch()

    def paste_image(self):
        try:
            image = ImageGrab.grabclipboard()
            if isinstance(image, Image.Image):
                self.current_image = image
                
                # Preview logic
                preview = image.copy()
                preview.thumbnail((450, 350))
                self.photo = ImageTk.PhotoImage(preview)
                self.lbl_preview.config(image=self.photo, text="")
                
                self.btn_upload.config(state=tk.NORMAL, bg="#4CAF50")
                self.status_var.set("Ready to upload. Press ENTER.")
            else:
                self.status_var.set("Clipboard does not contain an image.")
        except Exception:
            pass

    def start_upload_thread(self):
        if not self.current_image or self.is_uploading: return
        self.is_uploading = True
        self.btn_upload.config(text="Uploading...", state=tk.DISABLED)
        threading.Thread(target=self.upload_process).start()

    def upload_process(self):
        try:
            # 1. Prepare Image
            img_byte_arr = io.BytesIO()
            self.current_image.save(img_byte_arr, format='PNG')
            img_byte_arr = img_byte_arr.getvalue()

            # 2. Upload to Storage
            file_name = self.target_filename
            self.supabase.storage.from_(BUCKET_NAME).upload(
                path=file_name,
                file=img_byte_arr,
                file_options={"content-type": "image/png", "x-upsert": "true"}
            )

            # 3. Get Public URL
            public_url = self.supabase.storage.from_(BUCKET_NAME).get_public_url(file_name)

            # 4. BULK UPDATE DATABASE
            # Update ALL questions that were waiting for this specific filename/placeholder
            raw_placeholder = self.current_question['image_url']
            
            self.supabase.table('questions') \
                .update({'image_url': public_url}) \
                .eq('image_url', raw_placeholder) \
                .execute()

            # 5. Refresh UI (Back on main thread)
            self.root.after(0, self.on_upload_success)

        except Exception as e:
            self.root.after(0, lambda: messagebox.showerror("Error", str(e)))
            self.root.after(0, lambda: self.btn_upload.config(text="UPLOAD", state=tk.NORMAL))
            self.is_uploading = False

    def on_upload_success(self):
        self.is_uploading = False
        self.status_var.set("Upload Success! Fetching next...")
        # Reload batch because the bulk update might have cleared multiple items from our current local list
        self._load_next_batch()

    def _show_complete(self):
        self.lbl_fig_name.config(text="ALL DONE!", fg="green")
        self.lbl_question_text.config(text="No more images pending in database.")
        self.btn_paste.config(state=tk.DISABLED)
        self.btn_upload.config(state=tk.DISABLED)

if __name__ == "__main__":
    root = tk.Tk()
    app = ImageUploaderApp(root)
    root.mainloop()