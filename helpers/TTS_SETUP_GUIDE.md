# 🎤 TTS Setup Summary

## ✅ Changes Made

### 1. **Fixed NoneType Errors**
   - Proper null checking for database fields
   - Uses `q.get('text_it')` instead of `q['text_it']`
   - Gracefully handles missing text data

### 2. **Bucket Configuration**
   - ✅ Bucket name set to: `"quiz_audio2"`
   - Audio files will be uploaded to this Supabase bucket
   - Public URLs will be stored in database columns:
     - `audio_it_url` (Italian)
     - `audio_en_url` (English)
     - `audio_bn_url` (Bangla)

### 3. **Bangla Male Voice** (Limited)
   - ⚠️ **gTTS has limited gender control**
   - Applied: `tld='com'` parameter for Bangla to attempt male-like voice
   - **Note**: This is not a guaranteed male voice, just a variation

## 📁 Files Created

### `TTS.py` (Updated - Basic Version)
- Uses **gTTS** (Google Translate TTS) - FREE
- Bucket: `quiz_audio2`
- TEST_MODE for local audio playback
- Bangla voice optimization (limited)

### `TTS_PREMIUM.py` (New - Full Male Voice)
- Uses **Google Cloud Text-to-Speech API**
- ✅ **Guaranteed MALE voices** for all languages
- ✅ **Bangla male voice**: `bn-IN-Wavenet-B`
- Better quality audio
- FREE tier: 4M characters/month (enough for 7000 questions)

### `TTS_UPGRADE_INFO.md` (Documentation)
- Explains voice gender limitations
- Setup instructions for Google Cloud TTS
- Pricing information

## 🚀 How to Use

### Option 1: Basic (gTTS) - Current TTS.py

```bash
# 1. Install pygame for audio playback
.venv\Scripts\python.exe -m pip install pygame

# 2. Test locally (plays audio)
.venv\Scripts\python.exe TTS.py

# 3. When ready to upload to Supabase:
#    Edit TTS.py: Set TEST_MODE = False
.venv\Scripts\python.exe TTS.py
```

### Option 2: Premium (Google Cloud TTS) - TTS_PREMIUM.py

```bash
# 1. Install Google Cloud TTS
.venv\Scripts\python.exe -m pip install google-cloud-texttospeech pygame

# 2. Set up Google Cloud (see TTS_UPGRADE_INFO.md)

# 3. Run
.venv\Scripts\python.exe TTS_PREMIUM.py
```

## 🎯 Production Workflow

When `TEST_MODE = False`, the script will:

1. ✅ Generate MP3 files for all 3 languages
2. ✅ Upload to `quiz_audio2` Supabase bucket
3. ✅ Get public URLs from Supabase
4. ✅ Update database columns:
   ```sql
   UPDATE questions SET 
     audio_it_url = 'https://...q_1_it.mp3',
     audio_en_url = 'https://...q_1_en.mp3',
     audio_bn_url = 'https://...q_1_bn.mp3'
   WHERE id = 1;
   ```

## ⚙️ Batch Processing

To process all 7000 questions, modify `BATCH_SIZE`:

```python
BATCH_SIZE = 100  # Process 100 at a time
```

Or run in a loop:
```python
while True:
    process_questions()
    # Stops when no more questions found
```

## 📊 Database Structure Expected

```sql
-- questions table should have these columns:
id (primary key)
text_it (text) - Italian question
text_en (text) - English question  
text_bn (text) - Bangla question
audio_it_url (text) - Italian audio URL
audio_en_url (text) - English audio URL
audio_bn_url (text) - Bangla audio URL
```

## 💡 Recommendations

1. **For Testing**: Use `TTS.py` with `TEST_MODE = True`
2. **For Production with basic voice**: Use `TTS.py` with `TEST_MODE = False`
3. **For TRUE male voices**: Use `TTS_PREMIUM.py` (requires Google Cloud setup)

The Google Cloud TTS is **FREE for your use case** (7000 questions ≈ 700K characters << 4M limit).
