"""
Quick utility to check available PaddleOCR language models.
"""

import os
os.environ['KMP_DUPLICATE_LIB_OK'] = 'TRUE'

from paddleocr import PaddleOCR

print("Checking available PaddleOCR languages...\n")

# Common language codes to test
test_languages = ['en', 'it', 'latin', 'ml', 'italian', 'english']

print("Testing language codes:")
print("-" * 50)

for lang in test_languages:
    try:
        print(f"Testing '{lang}'... ", end="")
        ocr = PaddleOCR(lang=lang, use_gpu=False, show_log=False)
        print("✓ SUPPORTED")
        del ocr
    except Exception as e:
        print(f"✗ Not available")

print("\n" + "=" * 50)
print("Recommendation:")
print("- Use lang='en' for English text")
print("- Use lang='it' for Italian text (if available)")
print("- English model often works well for Italian too")
print("=" * 50)
