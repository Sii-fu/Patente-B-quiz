"""
OCR Region Test Script
Captures a screen region and extracts structured text blocks with language detection.
"""

import os
os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'  # Prevent OpenMP conflicts

from mss import mss
from PIL import Image
import numpy as np
from paddleocr import PaddleOCR
from typing import List, Dict, Tuple


class ScreenRegionOCR:
    """Capture and analyze text from a specific screen region."""
    
    def __init__(self, languages: List[str] = ['en', 'it']):
        """
        Initialize PaddleOCR with specified languages.
        
        Args:
            languages: List of language codes (e.g., ['en', 'it'])
        """
        print("Initializing OCR engine...")
        # PaddleOCR language codes: 'en' for English, 'it' for Italian
        # For multilingual support, we'll use 'en' as base (works well for Italian too)
        # Or use 'it' specifically for Italian text
        
        # Default to English OCR model which works reasonably well for Italian
        # For better Italian support, change lang='it'
        self.ocr = PaddleOCR(
            lang='en',
            use_angle_cls=True
        )

        print("OCR engine initialized.\n")
    
    def capture_region(self, x: int, y: int, width: int, height: int) -> Image.Image:
        """
        Capture a screenshot of a specific screen region.
        
        Args:
            x: Left coordinate
            y: Top coordinate
            width: Region width
            height: Region height
            
        Returns:
            PIL Image of the captured region
        """
        print(f"Capturing region: x={x}, y={y}, width={width}, height={height}")
        
        with mss() as sct:
            # Define the region to capture
            monitor = {
                "left": x,
                "top": y,
                "width": width,
                "height": height
            }
            
            # Capture the screenshot
            screenshot = sct.grab(monitor)
            
            # Convert to PIL Image
            img = Image.frombytes("RGB", screenshot.size, screenshot.bgra, "raw", "BGRX")
            
        print(f"Screenshot captured: {img.size[0]}x{img.size[1]} pixels\n")
        return img
    
    def detect_language(self, text: str) -> str:
        """
        Simple language detection based on character patterns.
        
        Args:
            text: Text to analyze
            
        Returns:
            Detected language: 'Italian', 'English', or 'Unknown'
        """
        if not text or len(text.strip()) < 3:
            return "Unknown"
        
        text_lower = text.lower()
        
        # Common Italian words/patterns
        italian_indicators = [
            'è', 'à', 'ì', 'ò', 'ù',  # Accented characters
            ' di ', ' il ', ' la ', ' le ', ' gli ', ' dei ', ' delle ',
            ' con ', ' per ', ' che ', ' una ', ' uno ',
            'zione', 'mento', 'mente'  # Common endings
        ]
        
        # Common English words/patterns
        english_indicators = [
            ' the ', ' of ', ' and ', ' to ', ' in ', ' is ', ' it ',
            ' for ', ' with ', ' on ', ' at ', ' from ',
            'tion', 'ing', 'ment'
        ]
        
        italian_score = sum(1 for indicator in italian_indicators if indicator in text_lower)
        english_score = sum(1 for indicator in english_indicators if indicator in text_lower)
        
        if italian_score > english_score and italian_score > 0:
            return "Italian"
        elif english_score > italian_score and english_score > 0:
            return "English"
        else:
            return "Unknown"
    
    def extract_text_blocks(self, image: Image.Image) -> List[Dict]:
        """
        Extract structured text blocks from an image using OCR.
        
        Args:
            image: PIL Image to process
            
        Returns:
            List of text blocks with metadata
        """
        print("Running OCR analysis...")
        
        # Convert PIL Image to numpy array
        img_array = np.array(image)
        
        # Run OCR
        result = self.ocr.ocr(img_array, cls=True)
        
        if not result or not result[0]:
            print("No text detected in the image.\n")
            return []
        
        # Extract and structure text blocks
        text_blocks = []
        
        for idx, line in enumerate(result[0]):
            if not line:
                continue
                
            # PaddleOCR returns: [bbox, (text, confidence)]
            bbox = line[0]  # [[x1,y1], [x2,y2], [x3,y3], [x4,y4]]
            text_data = line[1]
            text = text_data[0]
            confidence = text_data[1]
            
            # Calculate bounding box properties
            x_coords = [point[0] for point in bbox]
            y_coords = [point[1] for point in bbox]
            
            x1, x2 = min(x_coords), max(x_coords)
            y1, y2 = min(y_coords), max(y_coords)
            
            block_height = int(y2 - y1)
            block_width = int(x2 - x1)
            
            # Detect language
            language = self.detect_language(text)
            
            text_blocks.append({
                'index': idx + 1,
                'text': text,
                'bbox': {
                    'x1': int(x1),
                    'y1': int(y1),
                    'x2': int(x2),
                    'y2': int(y2)
                },
                'block_height': block_height,
                'block_width': block_width,
                'language': language,
                'confidence': round(confidence, 3)
            })
        
        # Sort blocks by Y coordinate (top to bottom)
        text_blocks.sort(key=lambda block: block['bbox']['y1'])
        
        # Re-index after sorting
        for idx, block in enumerate(text_blocks, 1):
            block['index'] = idx
        
        print(f"Detected {len(text_blocks)} text block(s).\n")
        return text_blocks
    
    def print_results(self, text_blocks: List[Dict]):
        """
        Print text blocks in a structured, readable format.
        
        Args:
            text_blocks: List of extracted text blocks
        """
        if not text_blocks:
            print("=" * 70)
            print("NO TEXT BLOCKS DETECTED")
            print("=" * 70)
            return
        
        print("=" * 70)
        print(f"EXTRACTED TEXT BLOCKS: {len(text_blocks)} block(s)")
        print("=" * 70)
        print()
        
        for block in text_blocks:
            print(f"[BLOCK {block['index']}]")
            print(f"Text: \"{block['text']}\"")
            print(f"Language: {block['language']}")
            print(f"Bounding Box: ({block['bbox']['x1']}, {block['bbox']['y1']}, "
                  f"{block['bbox']['x2']}, {block['bbox']['y2']})")
            print(f"Block Height: {block['block_height']} px")
            print(f"Block Width: {block['block_width']} px")
            print(f"Confidence: {block['confidence']}")
            print("-" * 70)
            print()
    
    def process_region(self, x: int, y: int, width: int, height: int, 
                       save_screenshot: bool = True):
        """
        Complete workflow: capture region, extract text, and display results.
        
        Args:
            x: Left coordinate of region
            y: Top coordinate of region
            width: Width of region
            height: Height of region
            save_screenshot: Whether to save the captured image
        """
        # Capture the screen region
        image = self.capture_region(x, y, width, height)
        
        # Optionally save the screenshot
        if save_screenshot:
            screenshot_path = "captured_region.png"
            image.save(screenshot_path)
            print(f"Screenshot saved to: {screenshot_path}\n")
        
        # Extract text blocks
        text_blocks = self.extract_text_blocks(image)
        
        # Print results
        self.print_results(text_blocks)
        
        return text_blocks


def main():
    """
    Main execution function.
    Configure your screen region coordinates here.
    """
    print("=" * 70)
    print("OCR REGION TEST - Text Extraction & Classification")
    print("=" * 70)
    print()
    
    # ===================================================================
    # CONFIGURE YOUR SCREEN REGION HERE
    # ===================================================================
    # Example: Capture a 800x600 region starting at position (100, 100)
    
    REGION_X = 100        # Left edge (pixels from left)
    REGION_Y = 100        # Top edge (pixels from top)
    REGION_WIDTH = 800    # Width in pixels
    REGION_HEIGHT = 600   # Height in pixels
    
    # ===================================================================
    
    print("Configuration:")
    print(f"  Region: ({REGION_X}, {REGION_Y}) - {REGION_WIDTH}x{REGION_HEIGHT}")
    print()
    print("Note: Adjust REGION_X, REGION_Y, REGION_WIDTH, REGION_HEIGHT in the script")
    print("      to match your target screen area.")
    print()
    input("Press ENTER to capture and analyze the region...")
    print()
    
    # Initialize OCR engine
    ocr_processor = ScreenRegionOCR(languages=['en', 'it'])
    
    # Process the region
    ocr_processor.process_region(
        x=REGION_X,
        y=REGION_Y,
        width=REGION_WIDTH,
        height=REGION_HEIGHT,
        save_screenshot=True
    )
    
    print("=" * 70)
    print("ANALYSIS COMPLETE")
    print("=" * 70)


if __name__ == "__main__":
    main()
