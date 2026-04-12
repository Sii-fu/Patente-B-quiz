"""
Quick script to test Bangla TTS voice with gTTS variations
Run this to compare different TLD (Top Level Domain) options
"""
from gtts import gTTS
import pygame
from time import sleep

pygame.mixer.init()

test_text = "এই একটি পরীক্ষা। গাড়ি চালানোর সময় সতর্ক থাকুন।"  # "This is a test. Be careful while driving."

print("🎤 Testing Bangla TTS Voice Variations\n")
print(f"Test text: {test_text}\n")

# Test different TLD options
tld_options = ['com', 'co.in', 'com.bd', 'co.uk']

for tld in tld_options:
    try:
        print(f"🔊 Trying TLD: {tld}")
        tts = gTTS(text=test_text, lang='bn', slow=False, tld=tld)
        filename = f"test_bn_{tld.replace('.', '_')}.mp3"
        tts.save(filename)
        
        print(f"   ✅ Generated: {filename}")
        print(f"   ▶️ Playing...")
        
        pygame.mixer.music.load(filename)
        pygame.mixer.music.play()
        
        while pygame.mixer.music.get_busy():
            sleep(0.1)
        
        print(f"   ✓ Done\n")
        sleep(1)  # Pause between samples
        
    except Exception as e:
        print(f"   ❌ Error with {tld}: {e}\n")

print("🎉 Test complete! Check the generated MP3 files to compare voices.")
print("💡 Choose the TLD that sounds most male/natural to you.")

pygame.mixer.quit()
