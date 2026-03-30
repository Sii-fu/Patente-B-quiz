import customtkinter as ctk
import pyautogui
import time
import tkinter as tk
from supabase import create_client, Client
import re
import threading

# ================= CONFIGURATION =================
SUPABASE_URL = "https://gtlzxkfkfzndfsuqiyge.supabase.co"
SUPABASE_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imd0bHp4a2ZrZnpuZGZzdXFpeWdlIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc2MzQ5MDM4NywiZXhwIjoyMDc5MDY2Mzg3fQ.pUZJ1VpO18JjGf0UTir_ViffGKWdmDP41xnbjT0vaq0"

# SCAN COORDINATES
tscan_x = 5
tscan_y = 180
tscan_w = 500
tscan_h = 300

scan_x = 5
scan_y = 220
scan_w = 500
scan_h = 800

# ================= UI & LOGIC CLASS =================

class AutoScraperApp(ctk.CTk):
    def __init__(self):
        super().__init__()

        # Window Setup
        self.title("Auto Scraper Bot - Chapter Mode")
        self.geometry("500x500")
        self.resizable(True, True)

        # State Variables
        self.running = False
        self.waiting_for_user = False  # New flag for chapter pause
        
        # Data Variables
        self.main_text = ""
        self.card_title = ""
        self.current_chapter = 0
        self.current_chapter_name = "Waiting to start..."
        self.current_card_tracker = ""

        # UI Layout
        self.create_widgets()

    # --- BUTTON ACTIONS ---
    
    def continue_action(self):
        """Unlocks the waiting loop to proceed to next chapter"""
        if self.waiting_for_user:
            self.waiting_for_user = False
            self.btn_continue.configure(state="disabled", fg_color="gray")
            self.lbl_status.configure(text="Status: RESUMING...", text_color="green")

    def update_ui_status(self, text, color="gray"):
        self.lbl_status.configure(text=f"Status: {text}", text_color=color)

    # --- THREADING ---
    def start_thread(self):
        if not self.running:
            self.running = True
            self.btn_start.configure(state="disabled", text="Running...")
            self.update_ui_status("RUNNING", "green")
            threading.Thread(target=self.run_process, daemon=True).start()

    # ================= LOGIC =================
    
    def get_clipboard_safe(self):
        try:
            return self.clipboard_get()
        except:
            return ""

    def card_data_supabase_query(self, i):
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        print(f"Chapter: {self.current_chapter_name}, Card: {self.card_title}")
        
        supabase.table("theory_cards_duplicate").insert({
            "id" : i,
            "chapter_id": self.current_chapter,
            "title_it": self.card_title,
            "text_it": self.main_text
        }).execute()
        
        print(f"{{")
        print(f'    "id" : {i},')
        print(f'    "chapter_id": {self.current_chapter},')
        print(f'    "title_it": "{self.card_title}",')
        print(f'    "text_it": "{self.main_text}"')
        print(f"}}")

    def chapter_data_supabase_query(self):
        supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        print("Connected to Supabase")

        supabase.table("theory_chapters_duplicate").insert({
            "id" : self.current_chapter,
            "name_it": self.current_chapter_name
        }).execute()
        print({
            "id" : self.current_chapter,
            "name_it": self.current_chapter_name
        })
        
    def go_back(self):
        pyautogui.click(40, 130)
        time.sleep(0.5)
        
    def chapter_name(self):
        time.sleep(0.5)
        pyautogui.hotkey('winleft', 'shift', 's')
        pyautogui.moveTo(x=tscan_x, y=tscan_y)
        time.sleep(1.5)
        pyautogui.dragTo(x=tscan_x + tscan_w, y=270, duration=1)

        time.sleep(2)
        pyautogui.click(1700, 1000)

        time.sleep(1.5)
        pyautogui.hotkey('winleft', 'up')

        time.sleep(1.5)
        pyautogui.click(1045, 60)

        time.sleep(2)
        pyautogui.click(770, 125)

        try:
            text = self.get_clipboard_safe()
        except Exception:
            print("Clipboard empty or unavailable")
            text = ""
        
        if text:
            raw = text.strip()
            raw = ' '.join(raw.splitlines())

            def is_real_all_caps(word: str) -> bool:
                if not word.isalpha(): return False
                if not word.isupper(): return False
                if len(word) < 2: return False
                return True

            self.current_chapter_name = raw 

            for m in re.finditer(r'\S+', raw):
                token = m.group(0)
                if is_real_all_caps(token):
                    self.current_chapter_name = raw[:m.start()].strip()
                    break

            self.current_chapter_name = re.sub(r'^\d+\.\s*', '', self.current_chapter_name)

        # Update labels
        self.lbl_chapter_num.configure(text=f"Chapter ID: {self.current_chapter}")
        self.lbl_chapter_name.configure(text=f"Current: {self.current_chapter_name}")

        time.sleep(0.5)
        pyautogui.hotkey('winleft', 'down')
        pyautogui.hotkey('winleft', 'down')

    def change_chapter(self, n):
        time.sleep(0.5)
        self.go_back()
        self.go_back()
        time.sleep(1)
        pyautogui.click(380, 640)
        time.sleep(0.5)
        
        pyautogui.hotkey('down')
        time.sleep(0.1)
        pyautogui.hotkey('down')
        time.sleep(0.1)

        if n < 7:
            for i in range(n):
                pyautogui.hotkey('down')
                time.sleep(0.1)
            pyautogui.hotkey('enter')
        else:
            for i in range(6):
                pyautogui.hotkey('down')
                time.sleep(0.1)
            for i in range(n-6):
                if (i%3==0)and(i!=n-6):
                    pyautogui.hotkey('down')
                    time.sleep(0.1)
                pyautogui.hotkey('down')
                time.sleep(0.1)

        pyautogui.hotkey('enter')
        time.sleep(0.5)

    def change_card(self, k, n):
        self.change_chapter(k)
        time.sleep(0.5)
        
        pyautogui.hotkey('down')
        time.sleep(0.1)
        if n>16 and k == 17: #==============================
            pyautogui.hotkey('down') 
            time.sleep(0.1)
        if n>34 and k == 3: 
            pyautogui.hotkey('down') 
            time.sleep(0.1)
                
        if k!=17 and k!=24:
            j=5
        else: 
            j=4

        if n < j:
            for i in range(n-1):
                pyautogui.hotkey('down')
                time.sleep(0.1)
            pyautogui.hotkey('enter')
        else: 
            for i in range(j-1):
                pyautogui.hotkey('down')
                time.sleep(0.1)
            for i in range(n-j):
                if (i%3==0)and(i!=n):
                    pyautogui.hotkey('down')
                    time.sleep(0.1)
                pyautogui.hotkey('down')
                time.sleep(0.1)
            pyautogui.hotkey('enter')
        
        time.sleep(0.5)

    def card_data(self, card_number):
        time.sleep(0.5)
        if not self.copy_it_title(card_number):
            self.go_back()
            return 0
        self.copy_it_main_text()
        self.go_back()
        return 1

    def copy_it_title(self, card_number):
        time.sleep(0.5)
        pyautogui.hotkey('winleft', 'shift', 's')
        pyautogui.moveTo(x=tscan_x, y=tscan_y)
        time.sleep(1.5)
        pyautogui.dragTo(x=tscan_x + tscan_w, y= tscan_h, duration=1)

        time.sleep(2)
        pyautogui.click(1700, 1000)

        time.sleep(1.5)
        pyautogui.hotkey('winleft', 'up')

        time.sleep(1.5)
        pyautogui.click(1045, 60)

        time.sleep(2)
        pyautogui.click(770, 125)

        try:
            text = self.get_clipboard_safe()
        except Exception:
            text = ""
        
        if text:
            raw = text.strip()
            try:
                title_number = int(raw[:2].strip()) if card_number>9 else int(raw[:1].strip())
                if title_number != card_number:
                    print(f"Card number mismatch: Expected {card_number}, got {title_number}")
                    time.sleep(0.5)
                    pyautogui.hotkey('winleft', 'down')
                    pyautogui.hotkey('winleft', 'down')
                    return 0
            except (ValueError, IndexError):
                print(f"Could not extract number from card title: {raw}")
                time.sleep(0.5)
                pyautogui.hotkey('winleft', 'down')
                pyautogui.hotkey('winleft', 'down')
                return 0
            print(f"Card {card_number} detected with title: {raw}")
            def is_all_caps(word):
                letters = [c for c in word if c.isalpha()]
                return bool(letters) and all(c.isupper() for c in letters)
            self.card_title = ' '.join(w for w in raw.split() if is_all_caps(w))
        
        time.sleep(0.5)
        pyautogui.hotkey('winleft', 'down')
        pyautogui.hotkey('winleft', 'down')
        return 1

    def copy_it_main_text(self):
        time.sleep(0.5)
        pyautogui.hotkey('winleft', 'shift', 's')
        pyautogui.moveTo(x=scan_x, y=scan_y)
        time.sleep(1.5)
        pyautogui.dragTo(x=scan_x + scan_w, y=scan_y + scan_h, duration=1)

        time.sleep(2)
        pyautogui.click(1700, 1000)

        time.sleep(1.5)
        pyautogui.hotkey('winleft', 'up')

        time.sleep(1.5)
        pyautogui.click(1045, 60)

        time.sleep(2)
        pyautogui.click(770, 125)

        try:
            text = self.get_clipboard_safe()
        except Exception:
            text = ""
        
        if text:
            idx = text.find("English")
            result = text[:idx] if idx != -1 else "tobechecked-"
            # Remove any leading header made of ALL-CAPS words (keep the first token that contains a lowercase letter)
            m_found = None
            for m in re.finditer(r'\S+', result):
                token = m.group(0)
                if any(ch.isalpha() and ch.islower() for ch in token):
                    m_found = m
                    break
            if m_found:
                result = result[m_found.start():]
            result = ' '.join(result.splitlines())

            while '  ' in result:
                result = result.replace('  ', '\n')
            self.main_text = result.strip()
        
        time.sleep(0.5)
        pyautogui.hotkey('winleft', 'down')
        pyautogui.hotkey('winleft', 'down')
        return 1

    def create_widgets(self):
        # Title
        self.lbl_title = ctk.CTkLabel(self, text="Chapter Automation", font=("Arial", 22, "bold"))
        self.lbl_title.pack(pady=(20, 10))

        # Info Frame
        self.frame_info = ctk.CTkFrame(self)
        self.frame_info.pack(pady=10, padx=20, fill="x")

        self.lbl_chapter_num = ctk.CTkLabel(self.frame_info, text="Chapter ID: --", font=("Arial", 14))
        self.lbl_chapter_num.pack(pady=5)

        self.lbl_chapter_name = ctk.CTkLabel(self.frame_info, text="Current: None", font=("Arial", 16, "bold"), text_color="#4ea6ff")
        self.lbl_chapter_name.pack(pady=5)
        
        self.lbl_status = ctk.CTkLabel(self.frame_info, text="Status: IDLE", text_color="gray", font=("Arial", 12))
        self.lbl_status.pack(pady=5)

        # --- CONFIGURATION FRAME ---
        self.frame_config = ctk.CTkFrame(self)
        self.frame_config.pack(pady=10, padx=20, fill="x")
        
        # Chapter Range
        self.lbl_chapter_range = ctk.CTkLabel(self.frame_config, text="Chapter Range:", font=("Arial", 12, "bold"))
        self.lbl_chapter_range.grid(row=0, column=0, padx=10, pady=5, sticky="w")
        
        self.entry_chapter_start = ctk.CTkEntry(self.frame_config, width=60, placeholder_text="Start")
        self.entry_chapter_start.grid(row=0, column=1, padx=5, pady=5)
        self.entry_chapter_start.insert(0, "4")
        
        self.lbl_to = ctk.CTkLabel(self.frame_config, text="to", font=("Arial", 12))
        self.lbl_to.grid(row=0, column=2, padx=5, pady=5)
        
        self.entry_chapter_end = ctk.CTkEntry(self.frame_config, width=60, placeholder_text="End")
        self.entry_chapter_end.grid(row=0, column=3, padx=5, pady=5)
        self.entry_chapter_end.insert(0, "25")
        
        # Initial Card Value
        self.lbl_card_start = ctk.CTkLabel(self.frame_config, text="Start Card (j):", font=("Arial", 12, "bold"))
        self.lbl_card_start.grid(row=1, column=0, padx=10, pady=5, sticky="w")
        
        self.entry_card_start = ctk.CTkEntry(self.frame_config, width=60, placeholder_text="Card")
        self.entry_card_start.grid(row=1, column=1, padx=5, pady=5)
        self.entry_card_start.insert(0, "1")
        
        # Upload Chapter Checkbox
        self.checkbox_upload_chapter = ctk.CTkCheckBox(self.frame_config, text="Upload Chapter Data", font=("Arial", 12))
        self.checkbox_upload_chapter.grid(row=2, column=0, columnspan=2, padx=10, pady=5, sticky="w")
        self.checkbox_upload_chapter.deselect()  # not Checked by default

        # --- CONTROLS ---
        
        # Start Button (Initial Start)
        self.btn_start = ctk.CTkButton(self, text="START FROM CHAPTER 4", command=self.start_thread, height=50, fg_color="green", font=("Arial", 16, "bold"))
        self.btn_start.pack(pady=(20, 10), padx=40, fill="x")

        # Continue Button (Appears between chapters)
        self.btn_continue = ctk.CTkButton(self, text="CONTINUE TO NEXT CHAPTER", command=self.continue_action, height=50, fg_color="#D97706", hover_color="#B45309", font=("Arial", 16, "bold"), state="disabled")
        self.btn_continue.pack(pady=10, padx=40, fill="x")
        
        # Reset Button
        self.btn_reset = ctk.CTkButton(self, text="RESET / STOP", command=self.reset_process, height=40, fg_color="red", hover_color="#8B0000", font=("Arial", 14, "bold"))
        self.btn_reset.pack(pady=10, padx=40, fill="x")

    def reset_process(self):
        """Stops the running process and resets everything"""
        self.running = False
        self.waiting_for_user = False
        self.current_chapter = 0
        self.current_chapter_name = "Waiting to start..."
        self.current_card_tracker = ""
        
        self.btn_start.configure(state="normal", text="START FROM CHAPTER 1")
        self.btn_continue.configure(state="disabled", fg_color="gray")
        self.update_ui_status("RESET - Ready to start", "blue")
        self.lbl_chapter_num.configure(text="Chapter ID: --")
        self.lbl_chapter_name.configure(text="Current: None")
        
        print("Process has been reset.")



    def run_process(self):
        """The Main Execution Loop"""
        try:
            # Get configuration values from UI
            try:
                chapter_start = int(self.entry_chapter_start.get())
                chapter_end = int(self.entry_chapter_end.get())
                initial_card = int(self.entry_card_start.get())
            except ValueError:
                self.update_ui_status("Invalid input values!", "red")
                self.running = False
                self.btn_start.configure(state="normal", text="START FROM CHAPTER 1")
                return
            
            for i in range(chapter_start, chapter_end):
                
                if not self.running:  # Check if reset was called
                    print("Process stopped by user.")
                    return
                
                # --- START OF CHAPTER LOGIC ---
                self.current_chapter = i
                # Check if chapter upload is enabled
                if self.checkbox_upload_chapter.get():
                    self.change_chapter(i)
                    self.chapter_name() 
                    self.chapter_data_supabase_query()
                
                self.current_card_tracker = ""
                j = initial_card

                # --- CARD LOOP (Process all cards in this chapter) ---
                while True:
                    if not self.running:  # Check if reset was called
                        print("Process stopped by user.")
                        return
                    
                    print(f"Processing Chapter {i}, Card {j}")
                    self.change_card(i, j)
                    if self.card_data(j)==0:
                        print("checking the same card again...")
                        self.change_card(i, j)
                        if self.card_data(j)==0:    
                            print("checking next card...")
                            self.change_card(i, j+1)
                            if self.card_data(j)==0:
                                print("===================================================================")
                                print("No new card detected, assuming end of chapter.")
                                print(f"Last card processed: {self.current_card_tracker}")
                                print(f"Current card title: {self.card_title}")
                                # End of chapter detected
                                initial_card = 1 # Reset card number for next chapter
                                self.entry_chapter_start.delete(0, tk.END)
                                self.entry_chapter_start.insert(0, str(i+1))
                                break
                    
                    self.card_data_supabase_query(i*100 + j)
                    self.current_card_tracker = self.card_title
                    j += 1
                    
                # --- END OF CHAPTER: PAUSE HERE ---
                print(f"Chapter {i} Finished. Waiting for user confirmation...")
                
                
                #==================================================
                #==================================================

                # Update UI to show waiting state
                self.update_ui_status(f"Chapter {i} DONE. Click Continue!", "orange")
                self.btn_continue.configure(state="normal", fg_color="#D97706") # Enable Orange Button
                self.waiting_for_user = True
                
                # Wait loop: Sleeps until user clicks the button
                while self.waiting_for_user:
                    time.sleep(0.5)
                    if not self.running: return # Exit if window closed

                #==================================================
                #==================================================



                # Reset UI for next chapter
                self.update_ui_status("RUNNING", "green")
                self.checkbox_upload_chapter.select()
            
            # --- ALL CHAPTERS DONE ---
            self.running = False
            self.update_ui_status("ALL COMPLETED", "green")
            self.btn_start.configure(state="normal", text="START FROM CHAPTER 1")

        except Exception as e:
            print(f"Error in thread: {e}")
            self.running = False
            self.update_ui_status(f"ERROR: {e}", "red")
            self.btn_start.configure(state="normal", text="START FROM CHAPTER 1")


if __name__ == "__main__":
    app = AutoScraperApp()
    app.mainloop()
    # app.change_card(8, 8)