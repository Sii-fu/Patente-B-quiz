import os
from typing import Any, Dict, List, Optional
from dotenv import load_dotenv  # type: ignore

# Modern UI Library
import ttkbootstrap as ttk  # type: ignore
from ttkbootstrap.constants import *  # type: ignore
from ttkbootstrap.dialogs import Messagebox  # type: ignore

# Backend Libraries
from supabase import create_client  # type: ignore

# Load env vars
load_dotenv()

class CardCheckerApp(ttk.Window):
    def __init__(self):
        super().__init__(themename="superhero")
        self.title("🔍 Theory Card Checker")
        self.geometry("900x700")
        
        # --- App State ---
        self.supabase: Any = None
        self.cards: List[Dict[str, Any]] = []
        self.current_index: int = 0
        
        # --- Layout ---
        self.create_header()
        self.create_main_area()
        self.create_status_bar()

        # --- Auto-Load Credentials ---
        self.connect_db()

    def create_header(self):
        """Top configuration area"""
        header = ttk.Frame(self, padding=15, bootstyle="secondary")
        header.pack(fill="x")

        ttk.Label(header, text="🔌 Database Connection", font=("Helvetica", 10, "bold")).grid(row=0, column=0, columnspan=2, sticky="w", pady=(0, 10))
        
        # Connection status
        self.conn_status = ttk.Label(header, text="● Disconnected", foreground="red")
        self.conn_status.grid(row=0, column=2, sticky="e", padx=10)
        
        ttk.Button(header, text="🔄 Reload Cards", command=self.load_cards, bootstyle="info-outline").grid(row=0, column=3, padx=5)

    def create_main_area(self):
        """Main card display and editing area"""
        main = ttk.Frame(self, padding=20)
        main.pack(fill="both", expand=True)
        
        # Progress Info
        progress_frame = ttk.Frame(main)
        progress_frame.pack(fill="x", pady=(0, 15))
        
        self.progress_label = ttk.Label(progress_frame, text="No cards loaded", font=("Helvetica", 12, "bold"))
        self.progress_label.pack(side="left")
        
        # Card Info Display
        info_frame = ttk.LabelFrame(main, text="📋 Card Information")
        info_frame.pack(fill="x", pady=(0, 15), padx=5)
        
        # ID
        ttk.Label(info_frame, text="Card ID:", bootstyle="inverse-primary").grid(row=0, column=0, sticky="w", pady=5, padx=15)
        self.id_label = ttk.Label(info_frame, text="-", font=("Helvetica", 10, "bold"))
        self.id_label.grid(row=0, column=1, sticky="w", padx=10, pady=5)
        
        # Chapter ID
        ttk.Label(info_frame, text="Chapter ID:", bootstyle="inverse-primary").grid(row=1, column=0, sticky="w", pady=5, padx=15)
        self.chapter_label = ttk.Label(info_frame, text="-")
        self.chapter_label.grid(row=1, column=1, sticky="w", padx=10, pady=5)
        
        # Title IT
        ttk.Label(info_frame, text="Title (IT):", bootstyle="inverse-primary").grid(row=2, column=0, sticky="w", pady=5, padx=15)
        self.title_label = ttk.Label(info_frame, text="-", wraplength=600)
        self.title_label.grid(row=2, column=1, sticky="w", padx=10, pady=5)
        
        # Current Text (tobechecked-)
        ttk.Label(info_frame, text="Current Text:", bootstyle="inverse-primary").grid(row=3, column=0, sticky="w", pady=5, padx=15)
        self.current_text_label = ttk.Label(info_frame, text="-", foreground="#ff4444", font=("Helvetica", 10, "bold"))
        self.current_text_label.grid(row=3, column=1, sticky="w", padx=10, pady=(5, 15))
        
        # Input Area
        input_frame = ttk.LabelFrame(main, text="✏️ Enter Correct Italian Text")
        input_frame.pack(fill="both", expand=True, pady=(0, 15), padx=5)
        
        self.text_input = ttk.Text(input_frame, height=8, font=("Arial", 11), wrap="word")
        self.text_input.pack(fill="both", expand=True, padx=10, pady=10)
        
        # Action Buttons
        btn_frame = ttk.Frame(main)
        btn_frame.pack(fill="x")
        
        self.btn_save = ttk.Button(btn_frame, text="💾 Save & Next", command=self.save_and_next, 
                                     bootstyle="success", width=20, state="disabled")
        self.btn_save.pack(side="left", padx=5)
        
        self.btn_skip = ttk.Button(btn_frame, text="⏭️ Skip", command=self.skip_card, 
                                     bootstyle="warning", width=15, state="disabled")
        self.btn_skip.pack(side="left", padx=5)
        
        self.btn_prev = ttk.Button(btn_frame, text="⏮️ Previous", command=self.previous_card, 
                                     bootstyle="info-outline", width=15, state="disabled")
        self.btn_prev.pack(side="left", padx=5)
        
        ttk.Button(btn_frame, text="🔄 Refresh", command=self.load_cards, 
                   bootstyle="secondary-outline", width=15).pack(side="right", padx=5)

    def create_status_bar(self):
        self.status_var = ttk.StringVar(value="Connecting to database...")
        status = ttk.Label(self, textvariable=self.status_var, relief="sunken", anchor="w", padding=5, bootstyle="secondary-inverse")
        status.pack(side="bottom", fill="x")

    # --- Database Functions ---

    def connect_db(self):
        try:
            url = os.getenv("SUPABASE_URL")
            key = os.getenv("SUPABASE_KEY")
            
            self.supabase = create_client(url, key)
            self.conn_status.config(text="● Connected", foreground="green")
            self.status_var.set("✅ Connected to database")
            
            # Auto-load cards
            self.load_cards()
            
        except Exception as e:
            self.conn_status.config(text="● Error", foreground="red")
            self.status_var.set(f"❌ Connection failed: {e}")
            Messagebox.show_error(f"Database connection error:\n{e}", "Connection Error")

    def load_cards(self):
        if not self.supabase:
            Messagebox.show_warning("Please connect to the database first", "Not Connected")
            return
        
        try:
            self.status_var.set("Loading cards...")
            
            # Fetch cards where text_it = "tobechecked-"
            res = self.supabase.table("theory_cards_duplicate").select("*").eq("text_it", "tobechecked-").order("id").execute()  # type: ignore
            self.cards = res.data  # type: ignore
            
            if not self.cards:
                Messagebox.show_info("No cards found with text_it = 'tobechecked-'", "No Cards")
                self.status_var.set("No cards to check")
                self.progress_label.config(text="No cards found")
                return
            
            self.current_index = 0
            self.display_current_card()
            self.enable_buttons()
            self.status_var.set(f"✅ Loaded {len(self.cards)} cards to check")
            
        except Exception as e:
            self.status_var.set(f"❌ Error loading cards: {e}")
            Messagebox.show_error(f"Failed to load cards:\n{e}", "Load Error")

    def display_current_card(self):
        if not self.cards or self.current_index >= len(self.cards):
            return
        
        card = self.cards[self.current_index]
        
        # Update progress
        self.progress_label.config(text=f"Card {self.current_index + 1} of {len(self.cards)}")
        
        # Update card info
        self.id_label.config(text=str(card.get("id", "-")))
        self.chapter_label.config(text=str(card.get("chapter_id", "-")))
        self.title_label.config(text=card.get("title_it", "-"))
        self.current_text_label.config(text=card.get("text_it", "-"))
        
        # Clear input
        self.text_input.delete("1.0", "end")
        self.text_input.focus()

    def enable_buttons(self):
        self.btn_save.config(state="normal")
        self.btn_skip.config(state="normal")
        self.btn_prev.config(state="normal")

    def save_and_next(self):
        new_text = self.text_input.get("1.0", "end-1c").strip()
        
        if not new_text:
            Messagebox.show_warning("Please enter the correct Italian text", "Empty Input")
            return
        
        try:
            card = self.cards[self.current_index]
            card_id = card.get("id")
            
            # Update the database
            self.supabase.table("theory_cards_duplicate").update({"text_it": new_text}).eq("id", card_id).execute()  # type: ignore
            
            self.status_var.set(f"✅ Saved Card ID {card_id}")
            
            # Move to next card
            if self.current_index < len(self.cards) - 1:
                self.current_index += 1
                self.display_current_card()
            else:
                Messagebox.show_info("All cards have been processed!", "Complete")
                self.load_cards()  # Reload to check if any remain
            
        except Exception as e:
            self.status_var.set(f"❌ Save failed: {e}")
            Messagebox.show_error(f"Failed to save:\n{e}", "Save Error")

    def skip_card(self):
        if self.current_index < len(self.cards) - 1:
            self.current_index += 1
            self.display_current_card()
            self.status_var.set("⏭️ Skipped to next card")
        else:
            Messagebox.show_info("This is the last card", "End of List")

    def previous_card(self):
        if self.current_index > 0:
            self.current_index -= 1
            self.display_current_card()
            self.status_var.set("⏮️ Moved to previous card")
        else:
            Messagebox.show_info("This is the first card", "Start of List")

if __name__ == "__main__":
    app = CardCheckerApp()
    app.mainloop()
