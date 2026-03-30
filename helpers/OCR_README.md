# OCR Region Test - Documentation

## Overview
This script captures a specific screen region and performs OCR (Optical Character Recognition) to extract and classify text blocks. It supports both Italian and English text detection.

## Features
- ✅ Capture screenshots of specific screen regions using fixed coordinates
- ✅ Modern OCR using PaddleOCR or EasyOCR (no deprecated libraries)
- ✅ Structured text block extraction with metadata
- ✅ Automatic language detection (Italian, English, or Unknown)
- ✅ Bounding box coordinates for each text block
- ✅ Block height calculation (font-size proxy)
- ✅ Top-to-bottom text block sorting
- ✅ Confidence scores for each detection

## Files
- **ocr_region_test.py** - Main script using PaddleOCR (recommended)
- **ocr_region_test_easyocr.py** - Alternative using EasyOCR
- **requirements_ocr.txt** - Required Python packages

## Installation

### Step 1: Install Dependencies

**For PaddleOCR version (recommended):**
```powershell
pip install mss Pillow numpy paddlepaddle paddleocr
```

**For EasyOCR version:**
```powershell
pip install mss Pillow numpy easyocr torch torchvision
```

**Or use the requirements file:**
```powershell
pip install -r requirements_ocr.txt
```

### Step 2: First Run Model Download
The first time you run the script, it will download OCR models (100-300 MB). This is normal and only happens once.

## Usage

### 1. Configure Screen Region
Edit the script and set your target coordinates:

```python
REGION_X = 100        # Left edge (pixels from left)
REGION_Y = 100        # Top edge (pixels from top)
REGION_WIDTH = 800    # Width in pixels
REGION_HEIGHT = 600   # Height in pixels
```

### 2. Run the Script

**PaddleOCR version:**
```powershell
python ocr_region_test.py
```

**EasyOCR version:**
```powershell
python ocr_region_test_easyocr.py
```

### 3. View Results
The script will:
1. Initialize the OCR engine
2. Wait for you to press ENTER
3. Capture the specified region
4. Save a screenshot as `captured_region.png`
5. Extract and display text blocks in the terminal

## Output Format

```
[BLOCK 1]
Text: "19. STRADA A DOPPIO SENSO CON QUATTRO CORSIE"
Language: Italian
Bounding Box: (45, 120, 755, 162)
Block Height: 42 px
Block Width: 710 px
Confidence: 0.987
----------------------------------------------------------------------

[BLOCK 2]
Text: "È composta da una carreggiata a due corsie..."
Language: Italian
Bounding Box: (45, 185, 690, 215)
Block Height: 30 px
Block Width: 645 px
Confidence: 0.965
----------------------------------------------------------------------
```

## How to Find Screen Coordinates

### Method 1: Windows Snipping Tool
1. Open Snipping Tool
2. Use rectangular selection
3. The cursor shows X,Y coordinates in the bottom-left corner

### Method 2: PowerToys (Recommended)
1. Install Microsoft PowerToys
2. Enable Screen Ruler or Color Picker
3. Use the pixel coordinate display

### Method 3: Python Script
Run this quick helper:
```python
import pyautogui
print("Move mouse to top-left corner of region and press Ctrl+C")
try:
    while True:
        x, y = pyautogui.position()
        print(f"\rPosition: X={x} Y={y}", end="")
except KeyboardInterrupt:
    print(f"\n\nCaptured: X={x}, Y={y}")
```

## Comparing PaddleOCR vs EasyOCR

### PaddleOCR (Recommended)
✅ **Pros:**
- Faster inference speed
- Better accuracy for European languages
- Handles rotated text well
- Lower memory footprint

❌ **Cons:**
- Slightly more complex installation
- Less intuitive API

### EasyOCR
✅ **Pros:**
- Very simple API
- Excellent documentation
- Good multi-language support

❌ **Cons:**
- Slower than PaddleOCR
- Requires PyTorch (larger installation)
- Higher memory usage

## Language Detection Logic
The script uses pattern matching to detect languages:

**Italian indicators:**
- Accented characters: è, à, ì, ò, ù
- Common words: di, il, la, con, per, che
- Endings: -zione, -mento, -mente

**English indicators:**
- Common words: the, of, and, to, in, for
- Endings: -tion, -ing, -ment

If neither pattern matches strongly, returns "Unknown".

## Troubleshooting

### Issue: "No module named 'paddleocr'"
**Solution:** Install PaddleOCR:
```powershell
pip install paddleocr paddlepaddle
```

### Issue: "KMP_DUPLICATE_LIB_OK" error
**Solution:** Already handled in the script via:
```python
os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'
```

### Issue: No text detected
**Possible causes:**
- Wrong screen coordinates
- Text is too small or blurry
- Insufficient contrast
- Region is empty

**Solutions:**
- Verify coordinates using Snipping Tool
- Increase region size
- Check `captured_region.png` to see what was captured

### Issue: Slow performance
**Solutions:**
- Use PaddleOCR instead of EasyOCR
- Enable GPU if available (set `use_gpu=True` or `gpu=True`)
- Reduce region size

### Issue: Wrong language detection
**Note:** The language detection is simple and heuristic-based. For production use, consider:
- `langdetect` library
- `fasttext` language identification
- Cloud services (Google Translate API, Azure Text Analytics)

## Performance Tips
1. **Smaller regions = faster processing**: Only capture what you need
2. **GPU acceleration**: If you have NVIDIA GPU with CUDA, set `use_gpu=True`
3. **Batch processing**: If analyzing multiple regions, reuse the OCR instance
4. **Image preprocessing**: For low-quality images, apply sharpening or contrast enhancement

## Example Use Cases
- Extracting quiz questions from educational apps
- Automating data entry from legacy systems
- Screen reader accessibility tools
- Game text translation overlays
- Documentation screenshot analysis

## Limitations
- Local desktop only (no remote screen capture)
- Requires target content to be visible on screen
- OCR accuracy depends on text clarity and contrast
- Language detection is heuristic-based (not ML-powered)
- No GUI provided (terminal-based interface)

## Next Steps
After verifying OCR works correctly, you can:
1. Integrate with automation tools (pyautogui, selenium)
2. Process multiple regions in sequence
3. Save results to JSON/CSV for further analysis
4. Build a GUI using tkinter or PyQt
5. Add database storage for extracted text

## License
This is a test/utility script. Modify and use as needed.

## Support
For OCR library documentation:
- PaddleOCR: https://github.com/PaddlePaddle/PaddleOCR
- EasyOCR: https://github.com/JaidedAI/EasyOCR
