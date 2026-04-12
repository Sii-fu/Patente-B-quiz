# 🚀 Batch Processing Configuration

## ✅ Updated: Both TTS.py and TTS_PREMIUM.py

### New Configuration Options

```python
BATCH_SIZE = 50        # Process 50 questions per batch
TEST_MODE = True       # Test locally (True) or upload to Supabase (False)
PROCESS_ALL = True     # Process ALL questions automatically (True) or single batch (False)
```

## 📊 Processing Modes

### Mode 1: Process ALL Questions (PROCESS_ALL = True)
**Current setting** - Will process all 7000+ questions in batches

```
🚀 BATCH MODE: Processing ALL questions without audio
📦 Batch size: 50 questions per batch

======================================================================
BATCH #1
======================================================================
📊 Questions remaining: 7000
[Processing 50 questions...]
✅ Batch #1 complete
📈 Total processed so far: 50

======================================================================
BATCH #2
======================================================================
📊 Questions remaining: 6950
[Processing 50 questions...]
✅ Batch #2 complete
📈 Total processed so far: 100

... (continues until all done)

======================================================================
🎉 ALL PROCESSING COMPLETE!
📊 Total questions processed: 7000
📦 Total batches: 140
======================================================================
```

### Mode 2: Single Batch (PROCESS_ALL = False)
Only processes 50 questions and stops

## ⚙️ Configuration Guide

### For Testing (Current Setup)
```python
BATCH_SIZE = 50        # Test with smaller batches
TEST_MODE = True       # Play audio locally, don't upload
PROCESS_ALL = True     # But will process all in your batch
```

### For Production Upload
```python
BATCH_SIZE = 50        # 50 questions at a time (safe rate)
TEST_MODE = False      # Upload to Supabase bucket
PROCESS_ALL = True     # Process all 7000+ questions
```

### For Quick Single Batch Test
```python
BATCH_SIZE = 5         # Just 5 questions
TEST_MODE = True       # Test locally
PROCESS_ALL = False    # Stop after one batch
```

## 🎯 How It Works

1. **Queries database** for questions with `audio_it_url = NULL`
2. **Fetches BATCH_SIZE questions** (e.g., 50)
3. **Generates TTS** for Italian, English, Bangla
4. **If TEST_MODE = True**: Plays audio locally
5. **If TEST_MODE = False**: Uploads to `quiz_audio2` bucket and updates database
6. **If PROCESS_ALL = True**: Repeats until no questions remain
7. **Progress tracking**: Shows batch number, total processed, remaining count

## 💡 Recommendations

### During Development/Testing
```python
BATCH_SIZE = 10
TEST_MODE = True
PROCESS_ALL = False  # Test one batch at a time
```

### Production Run (All 7000 questions)
```python
BATCH_SIZE = 50      # Good balance between speed and stability
TEST_MODE = False    # Upload and save to database
PROCESS_ALL = True   # Don't stop until all done
```

## 🛑 Stopping the Process

- Press **Ctrl+C** to stop at any time
- Progress is saved after each question
- Safe to resume - only processes questions where `audio_it_url IS NULL`

## 📈 Estimated Time (for 7000 questions)

- **gTTS (TTS.py)**: ~2-3 seconds per question = **5-6 hours total**
- **Google Cloud TTS (TTS_PREMIUM.py)**: ~1-2 seconds per question = **2-4 hours total**

With `BATCH_SIZE = 50` and 2-second delays between batches:
- ~140 batches
- ~280 seconds (4.6 min) of waiting time between batches

## 🚨 Important Notes

1. **Resume capability**: If interrupted, just run again - it only processes missing audio
2. **Rate limiting**: 2-second delay between batches (only in production mode)
3. **Error handling**: If one language fails, others still process and save
4. **Database updates**: Only updates when TEST_MODE = False
5. **Temp files**: Automatically cleaned up in production mode

## 🎬 Quick Start

```bash
# 1. Install dependencies (if not already)
.venv\Scripts\python.exe -m pip install pygame

# 2. Test with 5 questions locally
# Edit TTS.py: BATCH_SIZE=5, TEST_MODE=True, PROCESS_ALL=False
.venv\Scripts\python.exe TTS.py

# 3. Once satisfied, run full production
# Edit TTS.py: BATCH_SIZE=50, TEST_MODE=False, PROCESS_ALL=True
.venv\Scripts\python.exe TTS.py

# Go grab coffee ☕ - it will process all 7000+ questions automatically!
```
