import pyautogui
import time
import tkinter as tk
import tkinter.messagebox as messagebox
from supabase import create_client, Client
import re
import os

#for title
tscan_x = 5
tscan_y = 180
tscan_w = 500
tscan_h = 300

#for main text
scan_x = 5
scan_y = 220
scan_w = 500
scan_h = 800

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

if not SUPABASE_URL or not SUPABASE_KEY:
    raise RuntimeError(
        "Missing SUPABASE_URL or SUPABASE_KEY environment variable."
    )



main_text = ""
card_title = ""
current_chapter = 0
current_chapter_name = ""




def card_data_supabase_query(i):

    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    print(f"Chapter: {current_chapter_name}, Card: {card_title}")
    supabase.table("theory_cards_duplicate").insert({
        "id" : i,
        "chapter_id": current_chapter,
        "title_it": card_title,
        "text_it": main_text
    }).execute()
    print(f"{{")
    print(f'    "id" : {i},')
    print(f'    "chapter_id": {current_chapter},')
    print(f'    "title_it": "{card_title}",')
    print(f'    "text_it": "{main_text}"')
    print(f"}}")

def chapter_data_supabase_query():
    supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
    print("Connected to Supabase")

    supabase.table("theory_chapters_duplicate").insert({
        "id" : current_chapter,
        "name_it": current_chapter_name
    }).execute()
    print({
        "id" : current_chapter,
        "name_it": current_chapter_name
    })
    
def go_back():
    pyautogui.click(40, 130)
    time.sleep(0.5)
    
def chapter_name():
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


    root = tk.Tk()
    root.withdraw()
    try:
        text = root.clipboard_get()
    except Exception:
        print("Clipboard empty or unavailable")
    else:
        global current_chapter

        raw = text.strip()
        raw = ' '.join(raw.splitlines())

        def is_real_all_caps(word: str) -> bool:
            # must be only letters (no dots, no numbers)
            if not word.isalpha():
                return False

            # must be all uppercase
            if not word.isupper():
                return False

            # single-letter words are ignored
            if len(word) < 2:
                return False

            return True


        current_chapter = raw

        for m in re.finditer(r'\S+', raw):
            token = m.group(0)

            if is_real_all_caps(token):
                current_chapter = raw[:m.start()].strip()
                break

        # remove leading numeric-dot like "1." or "23."
        current_chapter = re.sub(r'^\d+\.\s*', '', current_chapter)



    finally:
        root.destroy()
    
    # print(f"Title: {current_chapter}")

    global current_chapter_name
    current_chapter_name = current_chapter


    time.sleep(0.5)
    pyautogui.hotkey('winleft', 'down')
    pyautogui.hotkey('winleft', 'down')

def change_chapter(n):
    time.sleep(0.5)
    go_back()
    go_back()
    time.sleep(0.5)
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
                # print(f"Scrolled extra for chapter {n} at iteration {i}")
            pyautogui.hotkey('down')
            time.sleep(0.1)

    pyautogui.hotkey('enter')
    time.sleep(0.5)

def change_card(k,n):
    
    change_chapter(k)
    time.sleep(0.5)
    
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
                # print(f"Scrolled extra for card {n} at iteration {i}")
            pyautogui.hotkey('down')
            time.sleep(0.1)
        pyautogui.hotkey('enter')
    
    time.sleep(0.5)


def card_data():
    time.sleep(0.5)
    copy_it_title()
    copy_it_main_text()
    go_back()


def copy_it_title():
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


    root = tk.Tk()
    root.withdraw()
    try:
        text = root.clipboard_get()
    except Exception:
        print("Clipboard empty or unavailable")
    else:
        global card_title
        raw = text.strip()
        def is_all_caps(word):
            letters = [c for c in word if c.isalpha()]
            return bool(letters) and all(c.isupper() for c in letters)
        card_title = ' '.join(w for w in raw.split() if is_all_caps(w))
    finally:
        root.destroy()

    
    
    # print(f"Title: {card_title}")

    time.sleep(0.5)
    pyautogui.hotkey('winleft', 'down')
    pyautogui.hotkey('winleft', 'down')
def copy_it_main_text():
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


    root = tk.Tk()
    root.withdraw()
    try:
        text = root.clipboard_get()
    except Exception:
        print("Clipboard empty or unavailable")
    else:
        idx = text.find("English")
        result = text[:idx] if idx != -1 else "tobechecked-"
        result = ' '.join(result.splitlines())

        # turn double spaces into newlines
        while '  ' in result:
            result = result.replace('  ', '\n')
        result = result.strip()
        global main_text
        main_text = result
    finally:
        root.destroy()

    # print(f"Main Text: {main_text}")
    
    time.sleep(0.5)
    pyautogui.hotkey('winleft', 'down')
    pyautogui.hotkey('winleft', 'down')

if __name__ == "__main__":
    
    for i in range(1, 26):
        chapter_name()
        chapter_data_supabase_query()
        global current_card
        current_card = ""
        current_chapter=i
        j=1
        while True:
            print(f"Processing Chapter {i}, Card {j}")
            change_card(i,j)
            card_data()
            if current_card == card_title:
                break
            card_data_supabase_query(i*100 + j)
            current_card = card_title
            j += 1




        

