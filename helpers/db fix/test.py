import customtkinter as ctk
import pyautogui
import pytesseract
from PIL import Image
import threading
import time
import os
import re
import pyperclip  # Used for clipboard manipulation

# ==============================================================================
#  CONFIGURATION SECTION - EDIT THIS BEFORE RUNNING
# ==============================================================================

# 1. Tesseract Path (Windows Only) - UNCOMMENT if needed
# pytesseract.pytesseract.tesseract_cmd = r'C:\Program Files\Tesseract-OCR\tesseract.exe'

# 2. OUTPUT FILE NAME
OUTPUT_FILENAME = "extracted_data.txt"

# 3. TIMING (Seconds to wait between actions)
WAIT_TIME = 1.0 

# ==============================================================================

class AutoBot(ctk.CTk):
    def __init__(self):
        super().__init__()

        self.title("Auto Bot: Scan -> Click -> Refine -> Save")
        self.geometry("700x600")
        self.is_running = False

        # --- UI LAYOUT ---
        # 1. Coordinate Finder (To help you setup)
        self.frame_setup = ctk.CTkFrame(self)
        self.frame_setup.pack(pady=10, fill="x", padx=10)
        
        ctk.CTkLabel(self.frame_setup, text="COORDINATE FINDER (Hover mouse, wait 3s)").pack()
        self.lbl_mouse_pos = ctk.CTkLabel(self.frame_setup, text="X: 0 | Y: 0", font=("Consolas", 20, "bold"), text_color="cyan")
        self.lbl_mouse_pos.pack(pady=5)
        self.btn_track = ctk.CTkButton(self.frame_setup, text="Start Tracking Mouse", command=self.track_mouse_loop)
        self.btn_track.pack(pady=5)

        # 2. Status & Controls
        self.lbl_status = ctk.CTkLabel(self, text="Status: IDLE", text_color="gray")
        self.lbl_status.pack(pady=5)

        self.btn_start = ctk.CTkButton(self, text="START AUTOMATION LOOP", fg_color="green", height=50, command=self.start_automation)
        self.btn_start.pack(pady=10, padx=20, fill="x")

        self.btn_stop = ctk.CTkButton(self, text="STOP", fg_color="red", command=self.stop_automation, state="disabled")
        self.btn_stop.pack(pady=5, padx=20, fill="x")

        # 3. Live Text Display
        ctk.CTkLabel(self, text="Refined Text Preview:").pack(pady=(10,0))
        self.textbox = ctk.CTkTextbox(self)
        self.textbox.pack(pady=10, padx=10, fill="both", expand=True)

    # --- HELPER: Mouse Tracker ---
    def track_mouse_loop(self):
        # Updates the label with current mouse position so you can find coordinates
        x, y = pyautogui.position()
        self.lbl_mouse_pos.configure(text=f"X: {x} | Y: {y}")
        self.after(100, self.track_mouse_loop)

    # --- CORE LOGIC ---
    def start_automation(self):
        self.is_running = True
        self.btn_start.configure(state="disabled")
        self.btn_stop.configure(state="normal")
        self.lbl_status.configure(text="Status: RUNNING", text_color="green")
        
        # Run in background thread
        self.thread = threading.Thread(target=self.automation_sequence)
        self.thread.daemon = True
        self.thread.start()

    def stop_automation(self):
        self.is_running = False
        self.btn_start.configure(state="normal")
        self.btn_stop.configure(state="disabled")
        self.lbl_status.configure(text="Status: STOPPED", text_color="red")

    def refine_text(self, text):
        """
        CLEANS THE TRASH CHARACTERS.
        Modify this regex to keep what you want.
        """
        if not text: return ""

        # 1. Join hyphenated words (e.g. "con-\ntinue" -> "continue")
        text = text.replace("-\n", "")

        # 2. Fix broken newlines (join lines that shouldn't be broken)
        # Replaces single newlines with space, keeps double newlines as paragraphs
        text = re.sub(r'(?<!\n)\n(?!\n)', ' ', text)

        # 3. Remove weird symbols (Keep letters, numbers, basic punctuation)
        # If Italian, make sure to keep àèìòù
        # This regex keeps basic text and specific punctuation
        text = re.sub(r'[^\w\s.,;:?!\'àèìòùé€$]', '', text)

        # 4. Collapse multiple spaces
        text = re.sub(r'\s+', ' ', text).strip()

        return text

    def automation_sequence(self):
        """
        THIS IS THE LOOP. EDIT COORDINATES HERE.
        """
        while self.is_running:
            try:
                # ========================================================
                # STEP 1: DEFINE SCREENSHOT AREA (X, Y, Width, Height)
                # ========================================================
                # UPDATE THESE NUMBERS using the Coordinate Finder at top
                scan_x = 5
                scan_y = 220
                scan_w = 500
                scan_h = 1000
                
                self.update_ui_log("1. Taking Screenshot...")
                time.sleep(0.5)
                # Capture the region using PIL
                screenshot = pyautogui.screenshot(region=(scan_x, scan_y, scan_w, scan_h))
                # ========================================================
                # STEP 2: EXTRACT TEXT (OCR)
                # ========================================================
                # Note: lang='ita' is better if you installed Italian data
                raw_text = pytesseract.image_to_string(screenshot, lang='ita')
                
                # ========================================================
                # STEP 3: PERFORM INTERACTION CLICKS (Inside the content)
                # ========================================================
                # If you need to click INSIDE the scanned area or a button
                # self.update_ui_log("2. Clicking interaction buttons...")
                pyautogui.click(x=300, y=500) 
                time.sleep(0.5)
                
                # ========================================================
                # STEP 4: REFINE & SHOW IN UI
                # ========================================================
                final_text = self.refine_text(raw_text)
                
                self.textbox.delete("0.0", "end")
                self.textbox.insert("0.0", final_text)
                
                # ========================================================
                # STEP 5: SAVE TO FILE
                # ========================================================
                if final_text:
                    with open(OUTPUT_FILENAME, "a", encoding="utf-8") as f:
                        f.write(final_text + "\n\n" + "-"*20 + "\n\n")
                    self.update_ui_log("3. Saved to file.")
                else:
                    self.update_ui_log("3. No text found, skipping save.")

                # ========================================================
                # STEP 6: CLICK "NEXT" BUTTON (To go to next page)
                # ========================================================
                self.update_ui_log("4. Clicking NEXT...")
                
                # !!! CHANGE THESE COORDINATES TO WHERE YOUR 'NEXT' BUTTON IS !!!
                # pyautogui.click(x=900, y=500) 
                
                # Wait for animation to finish before looping
                time.sleep(WAIT_TIME)

            except Exception as e:
                self.update_ui_log(f"ERROR: {e}")
                time.sleep(2)

    def update_ui_log(self, msg):
        print(msg) # Print to console
        # If you want it on the label:
        self.lbl_status.configure(text=msg)

if __name__ == "__main__":
    app = AutoBot()
    app.mainloop()