import os
from supabase import create_client, Client
from gtts import gTTS
from dotenv import load_dotenv
import pygame
from time import sleep
import httpx

# Load environment variables
load_dotenv()
# ================= CONFIGURATION =================
SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")
BUCKET_NAME = "quiz_audio2"  # Supabase bucket for audio files
BATCH_SIZE = 100
PROCESS_ALL = True  # Set to True to process ALL cards in a loop
TEST_MODE = False  # Set to False to upload to Supabase and update database
# =================================================

# Initialize Supabase Client
supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)

# Initialize pygame mixer for audio playback
pygame.mixer.init()


def play_audio(file_path):
    """Plays an audio file using pygame"""
    try:
        print(f"  🔊 Playing: {file_path}")
        pygame.mixer.music.load(file_path)
        pygame.mixer.music.play()

        # Wait for the audio to finish playing
        while pygame.mixer.music.get_busy():
            sleep(0.1)

        print("  ✅ Finished playing")
        return True
    except Exception as e:
        print(f"  ❌ Error playing audio: {e}")
        return False


def generate_and_test_audio(text, lang_code, file_name):
    """Generates MP3 and tests it locally (or uploads if TEST_MODE=False)"""
    # Handle None or empty text
    if text is None or (isinstance(text, str) and text.strip() == ""):
        print(f"  ⚠️ Skipping {lang_code}: Text is empty or None")
        return None

    temp_file = f"temp_{file_name}"

    try:
        # 1. Generate Audio (Text to Speech)
        print(f"  🎤 Generating audio for {lang_code}...")

        # Configure TTS with language-specific settings
        # Note: gTTS doesn't support gender selection, but we use 'tld' for variation
        # For Bangla, using 'com' domain for more natural male-sounding voice
        if lang_code == "bn":
            # Bangla - attempt to get deeper/male voice using domain variation
            tts = gTTS(text=text, lang=lang_code, slow=False, tld="com")
            print("  🗣️ Using male-oriented voice settings for Bangla")
        else:
            # Italian and English - standard voice
            tts = gTTS(text=text, lang=lang_code, slow=False)

        tts.save(temp_file)
        print(f"  ✅ Audio generated: {temp_file}")

        if TEST_MODE:
            # Test mode: Play the audio locally
            play_audio(temp_file)
            return temp_file  # Return local path in test mode
        else:
            # Production mode: Upload to Supabase
            with open(temp_file, "rb") as f:
                execute_with_retry(
                    lambda: supabase.storage.from_(BUCKET_NAME).upload(
                        path=file_name,
                        file=f,
                        file_options={"content-type": "audio/mpeg", "x-upsert": "true"},
                    ),
                    operation_desc=f"upload audio {file_name}",
                )

            # Get Public URL
            public_url = supabase.storage.from_(BUCKET_NAME).get_public_url(file_name)
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


def is_missing_audio_url(url_value):
    """True when URL is NULL or empty/whitespace"""
    return url_value is None or (isinstance(url_value, str) and url_value.strip() == "")


def safe_preview(text, max_len=100):
    if text is None:
        return "N/A"
    return str(text)[:max_len]


def execute_with_retry(operation, operation_desc, max_attempts=5, base_delay_seconds=2):
    """Execute network operations with exponential backoff for transient timeouts."""
    attempt = 1
    while attempt <= max_attempts:
        try:
            return operation()
        except (httpx.TimeoutException, httpx.ConnectTimeout) as e:
            if attempt == max_attempts:
                print(f"❌ {operation_desc} failed after {max_attempts} attempts: {e}")
                raise
            wait_time = base_delay_seconds * (2 ** (attempt - 1))
            print(f"⚠️ Timeout during {operation_desc} (attempt {attempt}/{max_attempts}). Retrying in {wait_time}s...")
            sleep(wait_time)
            attempt += 1
        except Exception as e:
            # Retry known TLS handshake timeout variants that bubble up as generic exceptions.
            err_text = str(e).lower()
            if "handshake operation timed out" not in err_text and "connecttimeout" not in err_text:
                raise
            if attempt == max_attempts:
                print(f"❌ {operation_desc} failed after {max_attempts} attempts: {e}")
                raise
            wait_time = base_delay_seconds * (2 ** (attempt - 1))
            print(f"⚠️ Network error during {operation_desc} (attempt {attempt}/{max_attempts}). Retrying in {wait_time}s...")
            sleep(wait_time)
            attempt += 1


def process_theory_cards():
    print("🔍 Fetching theory cards with missing audio URLs...")
    print(f"🧪 TEST MODE: {TEST_MODE} (audio will be {'played locally' if TEST_MODE else 'uploaded to Supabase'})\n")

    # Fetch cards where any audio URL is missing (NULL or empty string)
    response = execute_with_retry(
        lambda: supabase.table("theory_cards")
        .select("id, text_it, text_en, text_bn, audio_it_url, audio_en_url, audio_bn_url")
        .or_(
            'audio_it_url.is.null,audio_it_url.eq."",audio_en_url.is.null,audio_en_url.eq."",audio_bn_url.is.null,audio_bn_url.eq.""'
        )
        .limit(BATCH_SIZE)
        .execute(),
        operation_desc="fetch theory cards batch",
    )

    cards = response.data

    if not cards:
        print("✅ All theory cards have audio generated!")
        return

    print(f"🚀 Found {len(cards)} theory cards to process.\n")

    for card in cards:
        card_id = card["id"]
        print(f"{'=' * 60}")
        print(f"Processing Theory Card ID: {card_id}")
        print(f"{'=' * 60}")

        # Display the text content
        print("\n📝 Text Preview:")
        print(f"  IT: {safe_preview(card.get('text_it'))}...")
        print(f"  EN: {safe_preview(card.get('text_en'))}...")
        print(f"  BN: {safe_preview(card.get('text_bn'))}...")
        print()

        # Generate file names
        name_it = f"theory_card_{card_id}_it.mp3"
        name_en = f"theory_card_{card_id}_en.mp3"
        name_bn = f"theory_card_{card_id}_bn.mp3"

        url_it = None
        url_en = None
        url_bn = None

        # Generate only missing audio URLs
        if is_missing_audio_url(card.get("audio_it_url")):
            print("🎵 Processing Italian audio:")
            url_it = generate_and_test_audio(card.get("text_it"), "it", name_it)
        else:
            print("✅ Italian audio already present, skipping")

        if is_missing_audio_url(card.get("audio_en_url")):
            print("\n🎵 Processing English audio:")
            url_en = generate_and_test_audio(card.get("text_en"), "en", name_en)
        else:
            print("✅ English audio already present, skipping")

        if is_missing_audio_url(card.get("audio_bn_url")):
            print("\n🎵 Processing Bangla audio:")
            url_bn = generate_and_test_audio(card.get("text_bn"), "bn", name_bn)
        else:
            print("✅ Bangla audio already present, skipping")

        if not TEST_MODE:
            # Update Database with new URLs (only in production mode)
            update_data = {}
            if url_it:
                update_data["audio_it_url"] = url_it
            if url_en:
                update_data["audio_en_url"] = url_en
            if url_bn:
                update_data["audio_bn_url"] = url_bn

            if update_data:
                execute_with_retry(
                    lambda: supabase.table("theory_cards").update(update_data).eq("id", card_id).execute(),
                    operation_desc=f"update theory card {card_id}",
                )
                print(f"\n  ✅ Database updated for ID: {card_id}")
        else:
            print("\n  🧪 TEST MODE: Skipping database update")

        print(f"\n{'=' * 60}\n")


if __name__ == "__main__":
    try:
        if PROCESS_ALL:
            # Process all theory cards in batches until none remain
            total_processed = 0
            batch_count = 0

            print("🚀 BATCH MODE: Processing ALL theory cards with missing audio URLs")
            print(f"📦 Batch size: {BATCH_SIZE} cards per batch\n")

            while True:
                batch_count += 1
                print(f"\n{'=' * 70}")
                print(f"BATCH #{batch_count}")
                print(f"{'=' * 70}\n")

                # Get count before processing
                response_before = execute_with_retry(
                    lambda: supabase.table("theory_cards")
                    .select("id", count="exact")
                    .or_(
                        'audio_it_url.is.null,audio_it_url.eq."",audio_en_url.is.null,audio_en_url.eq."",audio_bn_url.is.null,audio_bn_url.eq.""'
                    )
                    .limit(1)
                    .execute(),
                    operation_desc="count remaining theory cards",
                )

                remaining = response_before.count if hasattr(response_before, "count") else 0

                if remaining == 0:
                    print("\n✅ No more theory cards to process!")
                    break

                print(f"📊 Theory cards remaining: {remaining}\n")

                # Process this batch
                process_theory_cards()

                # Count how many we processed (estimate)
                batch_processed = min(BATCH_SIZE, remaining)
                total_processed += batch_processed

                print(f"\n✅ Batch #{batch_count} complete")
                print(f"📈 Total processed so far: {total_processed}")

                # Small delay between batches to avoid rate limiting
                if not TEST_MODE:
                    print("⏳ Waiting 2 seconds before next batch...")
                    sleep(2)

            print(f"\n{'=' * 70}")
            print("🎉 ALL PROCESSING COMPLETE!")
            print(f"📊 Total theory cards processed: {total_processed}")
            print(f"📦 Total batches: {batch_count - 1}")
            print(f"{'=' * 70}")
        else:
            # Single batch mode
            process_theory_cards()
            print("\n🎉 Processing complete!")

    except KeyboardInterrupt:
        print("\n\n⚠️ Process interrupted by user")
        print("💾 Progress saved to database")
    except Exception as e:
        print(f"\n\n💥 Unexpected error: {e}")
        import traceback

        traceback.print_exc()
    finally:
        pygame.mixer.quit()
