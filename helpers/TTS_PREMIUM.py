# filepath: c:\Users\ACER\Documents\codes\work\Patente B quiz\helpers\TTS_PREMIUM.py
"""
TTS with Google Cloud Text-to-Speech API - MALE VOICE SUPPORT
Setup: pip install google-cloud-texttospeech
Required: GOOGLE_APPLICATION_CREDENTIALS environment variable
"""
import os
from supabase import create_client, Client
from google.cloud import texttospeech
from dotenv import load_dotenv
import pygame
from time import sleep

# Load environment variables
load_dotenv()
# ================= CONFIGURATION =================
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
BUCKET_NAME = "quiz_audio2"
BATCH_SIZE = 50  # Process 50 questions per batch
TEST_MODE = True  # Set to False to upload to Supabase and update database
PROCESS_ALL = True  # Set to True to process ALL questions in a loop
# =================================================

# Initialize clients
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
tts_client = texttospeech.TextToSpeechClient()
pygame.mixer.init()

# Voice configurations (ALL MALE)
VOICE_CONFIG = {
    'it': {
        'language_code': 'it-IT',
        'name': 'it-IT-Wavenet-C',  # Male voice
        'gender': texttospeech.SsmlVoiceGender.MALE
    },
    'en': {
        'language_code': 'en-US',
        'name': 'en-US-Wavenet-D',  # Male voice
        'gender': texttospeech.SsmlVoiceGender.MALE
    },
    'bn': {
        'language_code': 'bn-IN',
        'name': 'bn-IN-Wavenet-B',  # Male voice ✓
        'gender': texttospeech.SsmlVoiceGender.MALE
    }
}

def play_audio(file_path):
    """Plays an audio file using pygame"""
    try:
        print(f"  🔊 Playing: {file_path}")
        pygame.mixer.music.load(file_path)
        pygame.mixer.music.play()
        
        while pygame.mixer.music.get_busy():
            sleep(0.1)
        
        print(f"  ✅ Finished playing")
        return True
    except Exception as e:
        print(f"  ❌ Error playing audio: {e}")
        return False

def generate_and_test_audio(text, lang_code, file_name):
    """Generates MP3 with MALE VOICE using Google Cloud TTS"""
    if text is None or (isinstance(text, str) and text.strip() == ""):
        print(f"  ⚠️ Skipping {lang_code}: Text is empty or None")
        return None

    temp_file = f"temp_{file_name}"
    
    try:
        print(f"  🎤 Generating MALE voice audio for {lang_code}...")
        
        # Get voice configuration
        voice_config = VOICE_CONFIG.get(lang_code)
        if not voice_config:
            raise ValueError(f"Unsupported language: {lang_code}")
        
        # Set up the synthesis request
        synthesis_input = texttospeech.SynthesisInput(text=text)
        
        voice = texttospeech.VoiceSelectionParams(
            language_code=voice_config['language_code'],
            name=voice_config['name'],
            ssml_gender=voice_config['gender']
        )
        
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.MP3,
            speaking_rate=1.0,  # Normal speed
            pitch=0.0  # Normal pitch
        )
        
        # Generate speech
        response = tts_client.synthesize_speech(
            input=synthesis_input,
            voice=voice,
            audio_config=audio_config
        )
        
        # Save to file
        with open(temp_file, 'wb') as out:
            out.write(response.audio_content)
        
        print(f"  ✅ Audio generated: {temp_file} (Voice: {voice_config['name']})")

        if TEST_MODE:
            # Test mode: Play the audio locally
            play_audio(temp_file)
            return temp_file
        else:
            # Production mode: Upload to Supabase
            with open(temp_file, 'rb') as f:
                supabase.storage.from_(BUCKET_NAME).upload(
                    path=file_name,
                    file=f,
                    file_options={"content-type": "audio/mpeg", "x-upsert": "true"}
                )
            
            # Get Public URL
            public_url = supabase.storage.from_(BUCKET_NAME).get_public_url(file_name)
            print(f"  ✅ Uploaded to: {public_url}")
            return public_url

    except Exception as e:
        print(f"  ❌ Error processing {lang_code}: {e}")
        import traceback
        traceback.print_exc()
        return None
    finally:
        # Cleanup temporary file only if not in test mode
        if not TEST_MODE and os.path.exists(temp_file):
            os.remove(temp_file)

def process_questions():
    print("🔍 Fetching questions without audio...")
    print(f"🧪 TEST MODE: {TEST_MODE}")
    print(f"🗣️ VOICE: All languages using MALE voices\n")
    
    # Fetch questions where audio_it_url is NULL
    response = supabase.table('questions').select('id, text_it, text_en, text_bn')\
        .is_('audio_it_url', 'null').limit(BATCH_SIZE).execute()
    
    questions = response.data

    if not questions:
        print("✅ All questions have audio generated!")
        return

    print(f"🚀 Found {len(questions)} questions to process.\n")

    for q in questions:
        q_id = q['id']
        print(f"{'='*60}")
        print(f"Processing Question ID: {q_id}")
        print(f"{'='*60}")

        # Display the text content
        print(f"\n📝 Text Preview:")
        print(f"  IT: {q.get('text_it', 'N/A')[:100]}...")
        print(f"  EN: {q.get('text_en', 'N/A')[:100]}...")
        print(f"  BN: {q.get('text_bn', 'N/A')[:100]}...")
        print()

        # Generate file names
        name_it = f"q_{q_id}_it.mp3"
        name_en = f"q_{q_id}_en.mp3"
        name_bn = f"q_{q_id}_bn.mp3"

        # Generate & Test/Upload MP3s
        print("🎵 Processing Italian audio (MALE):")
        url_it = generate_and_test_audio(q.get('text_it'), 'it', name_it)
        
        print("\n🎵 Processing English audio (MALE):")
        url_en = generate_and_test_audio(q.get('text_en'), 'en', name_en)
        
        print("\n🎵 Processing Bangla audio (MALE):")
        url_bn = generate_and_test_audio(q.get('text_bn'), 'bn', name_bn)

        if not TEST_MODE:
            # Update Database with new URLs (only in production mode)
            update_data = {}
            if url_it: update_data['audio_it_url'] = url_it
            if url_en: update_data['audio_en_url'] = url_en
            if url_bn: update_data['audio_bn_url'] = url_bn

            if update_data:
                supabase.table('questions').update(update_data).eq('id', q_id).execute()
                print(f"\n  ✅ Database updated for ID: {q_id}")
        else:
            print(f"\n  🧪 TEST MODE: Skipping database update")
        
        print(f"\n{'='*60}\n")

if __name__ == "__main__":
    try:
        # Check for Google Cloud credentials
        if not os.getenv("GOOGLE_APPLICATION_CREDENTIALS"):
            print("⚠️ WARNING: GOOGLE_APPLICATION_CREDENTIALS not set!")
            print("Set it to your service account JSON file path")
            print("Example: set GOOGLE_APPLICATION_CREDENTIALS=path/to/key.json\n")
        
        if PROCESS_ALL:
            # Process all questions in batches until none remain
            total_processed = 0
            batch_count = 0
            
            print("🚀 BATCH MODE: Processing ALL questions without audio")
            print(f"📦 Batch size: {BATCH_SIZE} questions per batch")
            print(f"🗣️ All voices: MALE\n")
            
            while True:
                batch_count += 1
                print(f"\n{'='*70}")
                print(f"BATCH #{batch_count}")
                print(f"{'='*70}\n")
                
                # Get count before processing
                response_before = supabase.table('questions')\
                    .select('id', count='exact')\
                    .is_('audio_it_url', 'null')\
                    .limit(1)\
                    .execute()
                
                remaining = response_before.count if hasattr(response_before, 'count') else 0
                
                if remaining == 0:
                    print("\n✅ No more questions to process!")
                    break
                
                print(f"📊 Questions remaining: {remaining}\n")
                
                # Process this batch
                process_questions()
                
                # Count how many we processed (estimate)
                batch_processed = min(BATCH_SIZE, remaining)
                total_processed += batch_processed
                
                print(f"\n✅ Batch #{batch_count} complete")
                print(f"📈 Total processed so far: {total_processed}")
                
                # Small delay between batches to avoid rate limiting
                if not TEST_MODE:
                    print("⏳ Waiting 2 seconds before next batch...")
                    sleep(2)
            
            print(f"\n{'='*70}")
            print(f"🎉 ALL PROCESSING COMPLETE!")
            print(f"📊 Total questions processed: {total_processed}")
            print(f"📦 Total batches: {batch_count - 1}")
            print(f"{'='*70}")
        else:
            # Single batch mode
            process_questions()
            print("\n🎉 Processing complete!")
            
    except KeyboardInterrupt:
        print("\n\n⚠️ Process interrupted by user")
        print(f"💾 Progress saved to database")
    except Exception as e:
        print(f"\n\n💥 Unexpected error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        pygame.mixer.quit()
