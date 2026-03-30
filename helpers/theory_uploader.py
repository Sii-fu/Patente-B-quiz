import threading
import time
import os
import re
import fitz  # PyMuPDF
from PIL import Image
import io
import customtkinter as ctk
from supabase import create_client, Client
from deep_translator import GoogleTranslator
from dotenv import load_dotenv

load_dotenv()

# ==========================================
# CONFIGURATION
# ==========================================
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
PDF_PATH = "C:\\Users\\ACER\\Downloads\\scuolaguida-manuale-teoria-A1-A-B.pdf"
BUCKET_NAME = "theory-images"
# ==========================================

ctk.set_appearance_mode("Dark")
ctk.set_default_color_theme("blue")

class TheoryUploaderApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        # --- Supabase & Tools ---
        try:
            self.supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
            print("Supabase connected.")
        except Exception as e:
            print(f"Supabase Error: {e}")

        self.trans_en = GoogleTranslator(source='it', target='en')
        self.trans_bn = GoogleTranslator(source='it', target='bn')

        # --- State ---
        self.current_chapter_id = None
        self.pause_event = threading.Event()
        self.pause_event.set()
        self.stop_thread = False

        # --- GUI Setup ---
        self.title("Final PDF Processor (Serialized Images)")
        self.geometry("1200x850")
        self.grid_columnconfigure(1, weight=1)
        self.grid_rowconfigure(0, weight=1)

        # Sidebar
        self.sidebar = ctk.CTkFrame(self, width=300, corner_radius=0)
        self.sidebar.grid(row=0, column=0, sticky="nsew")
        
        ctk.CTkLabel(self.sidebar, text="CONTROLS", font=("Arial", 20, "bold")).pack(pady=20)
        
        ctk.CTkLabel(self.sidebar, text="Start Page:", font=("Arial", 12)).pack(pady=(10,0))
        self.entry_page = ctk.CTkEntry(self.sidebar, width=100)
        self.entry_page.insert(0, "1")
        self.entry_page.pack(pady=5)

        self.btn_start = ctk.CTkButton(self.sidebar, text="START PROCESSING", command=self.start_process, fg_color="green", height=40)
        self.btn_start.pack(padx=20, pady=20, fill="x")

        self.btn_continue = ctk.CTkButton(self.sidebar, text="CONFIRM & CONTINUE", command=self.user_confirm_continue, state="disabled", fg_color="orange", height=50)
        self.btn_continue.pack(padx=20, pady=20, fill="x")

        self.lbl_status = ctk.CTkLabel(self.sidebar, text="Status: Ready", wraplength=280, font=("Arial", 14))
        self.lbl_status.pack(pady=20)

        self.progress_bar = ctk.CTkProgressBar(self.sidebar)
        self.progress_bar.pack(padx=20, pady=10, fill="x")
        self.progress_bar.set(0)

        # Main Log
        self.main_area = ctk.CTkFrame(self, corner_radius=0)
        self.main_area.grid(row=0, column=1, sticky="nsew")

        self.log_box = ctk.CTkTextbox(self.main_area, width=600, height=400, font=("Consolas", 12))
        self.log_box.pack(padx=20, pady=20, fill="both", expand=True)

        self.img_preview = ctk.CTkLabel(self.main_area, text="[Image Preview]", width=250, height=250, fg_color="#2b2b2b")
        self.img_preview.pack(pady=20)

    def log(self, msg):
        self.log_box.insert("end", f"{msg}\n")
        self.log_box.see("end")

    def clean_text_speech(self, text):
        if not text: return ""
        text = text.replace('-\n', '') 
        text = text.replace('\n', ' ') 
        text = re.sub(r'\s+', ' ', text)
        return text.strip()

    def translate(self, text):
        if not text or len(text) < 2: return "", ""
        try:
            clean = self.clean_text_speech(text)
            en = self.trans_en.translate(clean)
            bn = self.trans_bn.translate(clean)
            return en, bn
        except: return "", ""

    def start_process(self):
        self.btn_start.configure(state="disabled")
        try: p = int(self.entry_page.get()) - 1
        except: p = 0
        threading.Thread(target=self.process_pdf, args=(p,), daemon=True).start()

    def user_confirm_continue(self):
        self.pause_event.set()
        self.btn_continue.configure(state="disabled")
        self.lbl_status.configure(text="Resuming...", text_color="white")

    def process_pdf(self, start_page):
        doc = fitz.open(PDF_PATH)
        
        for page_num in range(start_page, len(doc)):
            page = doc[page_num]
            self.progress_bar.set((page_num+1)/len(doc))
            
            # --- 1. PRE-LOAD AND SORT ALL IMAGES ON PAGE ---
            # We create a list of dictionaries to track "used" status
            page_images_data = []
            
            image_list = page.get_images(full=True)
            for img in image_list:
                xref = img[0]
                # Get the location (rect) of the image
                rects = page.get_image_rects(xref)
                if not rects: continue
                
                # An image might appear multiple times, we take the first instance
                # rects[0] is a Rect object (x0, y0, x1, y1)
                img_data = {
                    "xref": xref,
                    "y": rects[0].y0, # Vertical position
                    "used": False     # TRACKING FLAG
                }
                page_images_data.append(img_data)
            
            # SORT images from Top to Bottom based on 'y'
            page_images_data.sort(key=lambda x: x["y"])

            # --- 2. PREPARE TEXT LINES ---
            blocks = page.get_text("dict")["blocks"]
            blocks.sort(key=lambda b: b["bbox"][1]) 

            all_lines = []
            for b in blocks:
                if "lines" in b:
                    for l in b["lines"]:
                        line_text = " ".join([s["text"] for s in l["spans"]]).strip()
                        if line_text:
                            all_lines.append({
                                "text": line_text,
                                "y": l["bbox"][1] # Text Y position
                            })

            # --- 3. PROCESS CONTENT ---
            i = 0
            while i < len(all_lines):
                line_obj = all_lines[i]
                text = line_obj["text"]
                y_pos = line_obj["y"]

                # --- IGNORE TRASH ---
                if "....." in text or re.search(r'^\d+$', text) or "Manuale di teoria" in text:
                    i += 1
                    continue

                # ========================================================
                # LOGIC A: LESSON DETECTION
                # ========================================================
                if text.lower().startswith("lezione") and len(text) < 100:
                    clean_title = re.split(r'\.\s{2,}', text)[0] 
                    if len(clean_title) > 100: clean_title = clean_title[:100]

                    match = re.search(r"Lezione\s+(\d+)\.?\s*(.*)", clean_title, re.IGNORECASE)
                    
                    if match:
                        num = match.group(1)
                        name = match.group(2).strip()
                        
                        if not name and i+1 < len(all_lines):
                            name = all_lines[i+1]["text"]
                            i += 1

                        self.log(f"\n>>> [NEW LESSON] {num}: {name}")

                        if self.current_chapter_id:
                            self.lbl_status.configure(text="PAUSED: Click Continue", text_color="orange")
                            self.btn_continue.configure(state="normal")
                            self.pause_event.clear()
                            self.pause_event.wait()

                        en, bn = self.translate(name)
                        res = self.supabase.table("theory_chapters").insert({
                            "name_it": name, "name_en": en, "name_bn": bn, "display_order": num
                        }).execute()
                        self.current_chapter_id = res.data[0]['id']
                        self.log("    -> Chapter Saved.")
                        i += 1
                        continue

                # ========================================================
                # LOGIC B: CARD DETECTION
                # ========================================================
                if self.current_chapter_id and text.isupper() and len(text) > 3 and "LEZIONE" not in text:
                    
                    card_title = text
                    self.log(f"  [CARD] {card_title}")

                    # Find Description
                    card_desc = ""
                    j = i + 1
                    while j < len(all_lines):
                        next_line = all_lines[j]["text"]
                        if next_line.lower().startswith("lezione"): break
                        if next_line.isupper() and len(next_line) > 3 and len(next_line) < 80: break
                        card_desc += " " + next_line
                        j += 1
                    
                    i = j - 1 

                    if not card_desc.strip():
                        i += 1
                        continue

                    # --- FIND IMAGE (SERIALIZED FIX) ---
                    img_url = None
                    
                    for img_data in page_images_data:
                        # 1. Skip if already assigned to a previous card
                        if img_data["used"]:
                            continue
                        
                        # 2. Check Vertical Alignment (Tolerance 150px)
                        if abs(y_pos - img_data["y"]) < 150:
                            
                            self.log("    -> Image Match Found!")
                            
                            # Extract
                            base = doc.extract_image(img_data["xref"])
                            img_bytes = base["image"]
                            ext = base["ext"]
                            
                            # Preview
                            try:
                                pil_img = Image.open(io.BytesIO(img_bytes))
                                ct_img = ctk.CTkImage(pil_img, size=(150, 150))
                                self.img_preview.configure(image=ct_img, text="")
                            except: pass

                            # Upload
                            fname = f"ch{self.current_chapter_id}_{card_title.replace(' ', '_')[:20]}_{int(time.time())}.{ext}"
                            try:
                                self.supabase.storage.from_(BUCKET_NAME).upload(fname, img_bytes, {"content-type": f"image/{ext}"})
                                img_url = self.supabase.storage.from_(BUCKET_NAME).get_public_url(fname)
                                self.log("    -> Image Uploaded.")
                            except:
                                img_url = self.supabase.storage.from_(BUCKET_NAME).get_public_url(fname)
                            
                            # 3. CRITICAL: MARK AS USED SO NEXT CARD CAN'T TAKE IT
                            img_data["used"] = True 
                            
                            break # Stop looking for images for THIS card

                    # --- UPLOAD CARD ---
                    self.log("    -> Saving Data...")
                    t_en, t_bn = self.translate(card_title)
                    d_en, d_bn = self.translate(card_desc)
                    
                    self.supabase.table("theory_cards").insert({
                        "chapter_id": self.current_chapter_id,
                        "title_it": card_title, "title_en": t_en, "title_bn": t_bn,
                        "text_it": self.clean_text_speech(card_desc), 
                        "text_en": d_en, "text_bn": d_bn,
                        "image_url": img_url, "display_order": i
                    }).execute()
                
                i += 1 

        self.log("\nDONE.")
        self.lbl_status.configure(text="Finished", text_color="green")

if __name__ == "__main__":
    app = TheoryUploaderApp()
    app.mainloop()