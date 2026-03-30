import fitz  # PyMuPDF
import os
import re

# REPLACE with your PDF filename
pdf_filename = "C:\\Users\\ACER\\Downloads\\scuolaguida-manuale-teoria-A1-A-B.pdf" 
# Create a folder for results
output_folder = "extracted_signs"

def sanitize_filename(name):
    """Removes invalid characters from filenames"""
    return re.sub(r'[\\/*?:"<>|]', "", name).strip()

def extract_and_rename_images(pdf_path):
    if not os.path.exists(output_folder):
        os.makedirs(output_folder)

    doc = fitz.open(pdf_path)
    print(f"Processing {pdf_path}...")

    for page_num in range(doc.page_count):
        page = doc.load_page(page_num)
        # 1. Get all Text Lines with their coordinates
        # We look for lines that are likely titles (UPPERCASE)
        text_instances = []
        blocks = page.get_text("dict")["blocks"]
        
        for b in blocks:
            if "lines" in b:
                for line in b["lines"]:
                    for span in line["spans"]:
                        text = span["text"].strip()
                        # HEURISTIC: We assume titles are Uppercase and at least 3 chars long
                        # You can adjust this rule based on your PDF's real font data
                        if text.isupper() and len(text) > 2:
                            # bbox is (x0, y0, x1, y1)
                            text_instances.append({
                                "text": text,
                                "y": span["bbox"][1] # The vertical start position
                            })

        # 2. Get all Images with their coordinates
        image_list = page.get_images(full=True)
        
        for img_index, img in enumerate(image_list):
            xref = img[0]
            
            # get_image_rects tells us WHERE the image is on the page
            image_rects = page.get_image_rects(xref)
            
            if not image_rects:
                continue

            # We usually take the first occurrence of the image on the page
            img_y = image_rects[0].y0 

            # 3. MATCHING LOGIC
            # Find the title that is closest to this image vertically (Y-axis)
            # We look for a title that is slightly above or at the same level as the image
            best_match_title = "Unknown_Topic"
            min_dist = 1000 # Start with a large number

            for t in text_instances:
                # Calculate vertical distance between Title top and Image top
                dist = abs(t["y"] - img_y)
                
                # We assume the title is usually within 50 pixels vertically of the image top
                if dist < 100 and dist < min_dist:
                    min_dist = dist
                    best_match_title = t["text"]

            # 4. Save the Image
            base_image = doc.extract_image(xref)
            image_bytes = base_image["image"]
            ext = base_image["ext"]
            
            clean_name = sanitize_filename(best_match_title)
            # Add page number to avoid overwriting if titles repeat
            filename = f"{clean_name}_p{page_num+1}.{ext}"
            save_path = os.path.join(output_folder, filename)

            with open(save_path, "wb") as f:
                f.write(image_bytes)
            
            print(f"Saved: {filename} (Matched '{best_match_title}' with Image at Y={int(img_y)})")

extract_and_rename_images(pdf_filename)
