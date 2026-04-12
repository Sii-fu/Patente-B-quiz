# TTS Voice Gender Control - Upgrade Options

## Current Implementation (gTTS)
- ✅ **Free and simple**
- ❌ **No gender control** - gTTS uses Google Translate's TTS which doesn't expose voice gender options
- ⚠️ **Workaround applied**: Using `tld='com'` for Bangla may provide slight voice variation, but **not guaranteed to be male**

## Recommended Upgrade: Google Cloud Text-to-Speech API

### Why Google Cloud TTS?
- ✅ **Full gender control** (MALE, FEMALE, NEUTRAL)
- ✅ **Multiple voice options** per language
- ✅ **Better quality** audio
- ✅ **Supports Bangla** with male voices (e.g., `bn-IN-Wavenet-B` is male)

### Pricing
- **FREE tier**: 0-4 million characters/month
- Your 7000 questions ≈ 700,000 characters (well within free tier)

### Implementation Example

```python
from google.cloud import texttospeech

# Initialize client
client = texttospeech.TextToSpeechClient()

def generate_audio_with_gender(text, lang_code, gender='MALE'):
    # Language mapping for Google Cloud TTS
    voice_map = {
        'it': 'it-IT-Wavenet-C',  # Italian Male
        'en': 'en-US-Wavenet-D',  # English Male
        'bn': 'bn-IN-Wavenet-B',  # Bangla Male ✓
    }
    
    synthesis_input = texttospeech.SynthesisInput(text=text)
    
    voice = texttospeech.VoiceSelectionParams(
        language_code=lang_code if lang_code != 'bn' else 'bn-IN',
        name=voice_map.get(lang_code),
        ssml_gender=texttospeech.SsmlVoiceGender.MALE
    )
    
    audio_config = texttospeech.AudioConfig(
        audio_encoding=texttospeech.AudioEncoding.MP3
    )
    
    response = client.synthesize_speech(
        input=synthesis_input, 
        voice=voice, 
        audio_config=audio_config
    )
    
    return response.audio_content
```

### Setup Steps
1. Install: `pip install google-cloud-texttospeech`
2. Create Google Cloud project
3. Enable Text-to-Speech API
4. Download service account JSON key
5. Set environment variable: `GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json`

### Alternative: pyttsx3 (Offline)
- ✅ **Free and offline**
- ✅ **Gender control** on Windows (SAPI5 voices)
- ❌ **Limited Bangla support** (depends on OS voices)
- ❌ **Lower quality** than cloud solutions

```python
import pyttsx3

engine = pyttsx3.init()
voices = engine.getProperty('voices')

# Set male voice (index varies by system)
engine.setProperty('voice', voices[0].id)  # Usually male
engine.save_to_file(text, filename)
engine.runAndWait()
```

## Recommendation
If budget allows, **upgrade to Google Cloud TTS** for proper male voice in Bangla. The free tier is generous enough for your 7000 questions.
