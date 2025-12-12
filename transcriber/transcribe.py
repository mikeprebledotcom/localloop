#!/usr/bin/env python3
"""
Local Loop Transcription Pipeline

Downloads audio from Google Drive, transcribes with Gemini,
outputs formatted markdown.

https://github.com/mikeprebledotcom/localloop
"""

import os
import sys
import yaml
import logging
from pathlib import Path
from datetime import datetime
from collections import defaultdict

from google.oauth2.credentials import Credentials
from google_auth_oauthlib.flow import InstalledAppFlow
from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaIoBaseDownload

import google.generativeai as genai

# Script directory for relative paths
SCRIPT_DIR = Path(__file__).parent.absolute()

# Load config
with open(SCRIPT_DIR / "config.yaml") as f:
    CONFIG = yaml.safe_load(f)

SCOPES = ["https://www.googleapis.com/auth/drive.readonly"]

# Setup logging
logging.basicConfig(
    level=getattr(logging, CONFIG.get("logging", {}).get("level", "INFO")),
    format="%(asctime)s - %(levelname)s - %(message)s",
    handlers=[
        logging.FileHandler("/tmp/localloop-transcriber.log"),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

# VAD model cache
_vad_model = None


def get_vad_model():
    """Load and cache Silero VAD model."""
    global _vad_model
    if _vad_model is None:
        from silero_vad import load_silero_vad
        _vad_model = load_silero_vad()
    return _vad_model


def detect_speech(audio_path: Path) -> tuple[bool, float]:
    """
    Detect if audio contains speech using Silero VAD.
    Returns (has_speech, speech_duration_seconds).
    """
    import tempfile
    import os
    from pydub import AudioSegment
    from silero_vad import read_audio, get_speech_timestamps

    vad_config = CONFIG.get("vad", {})
    if not vad_config.get("enabled", True):
        return True, 0.0

    # Convert M4A to WAV (Silero needs raw audio)
    audio = AudioSegment.from_file(str(audio_path), format="m4a")
    audio = audio.set_frame_rate(16000).set_channels(1)

    with tempfile.NamedTemporaryFile(suffix=".wav", delete=False) as tmp:
        tmp_path = tmp.name
        audio.export(tmp_path, format="wav")

    try:
        model = get_vad_model()
        wav = read_audio(tmp_path, sampling_rate=16000)

        speech_timestamps = get_speech_timestamps(
            wav, model,
            threshold=vad_config.get("threshold", 0.5),
            sampling_rate=16000,
            min_speech_duration_ms=vad_config.get("min_speech_duration_ms", 250),
            return_seconds=True
        )

        speech_duration = sum(ts["end"] - ts["start"] for ts in speech_timestamps)
        return len(speech_timestamps) > 0, speech_duration
    finally:
        os.unlink(tmp_path)


def get_drive_service():
    """Authenticate and return Drive service."""
    creds = None
    token_path = SCRIPT_DIR / "token.json"
    credentials_path = SCRIPT_DIR / "credentials.json"

    if token_path.exists():
        creds = Credentials.from_authorized_user_file(str(token_path), SCOPES)

    if not creds or not creds.valid:
        if creds and creds.expired and creds.refresh_token:
            creds.refresh(Request())
        else:
            if not credentials_path.exists():
                logger.error("credentials.json not found. Download from Google Cloud Console.")
                sys.exit(1)
            flow = InstalledAppFlow.from_client_secrets_file(str(credentials_path), SCOPES)
            creds = flow.run_local_server(port=0)

        token_path.write_text(creds.to_json())

    return build("drive", "v3", credentials=creds)


def download_new_files(service, folder_id: str, local_dir: Path) -> list[Path]:
    """Download unprocessed audio files from Drive."""
    local_dir.mkdir(parents=True, exist_ok=True)

    results = service.files().list(
        q=f"'{folder_id}' in parents and mimeType='audio/mp4' and trashed=false",
        fields="files(id, name, createdTime)",
        orderBy="createdTime"
    ).execute()

    downloaded = []
    processed_log = SCRIPT_DIR / ".processed"
    processed = set()

    if processed_log.exists():
        processed = set(processed_log.read_text().splitlines())

    for file in results.get("files", []):
        if file["id"] in processed:
            continue

        local_path = local_dir / file["name"]
        logger.info(f"Downloading: {file['name']}")

        request = service.files().get_media(fileId=file["id"])
        with open(local_path, "wb") as f:
            downloader = MediaIoBaseDownload(f, request)
            done = False
            while not done:
                status, done = downloader.next_chunk()

        downloaded.append(local_path)

        with open(processed_log, "a") as f:
            f.write(file["id"] + "\n")

    return downloaded


def parse_chunk_time(filename: str) -> tuple[datetime, int]:
    """
    Parse date and time from chunk filename.
    Format: YYYY-MM-DD_HHmm.m4a -> (date, seconds_from_midnight)
    """
    stem = filename.rsplit(".", 1)[0]
    date_part, time_part = stem.split("_")

    date = datetime.strptime(date_part, "%Y-%m-%d")
    hours = int(time_part[:2])
    minutes = int(time_part[2:4])
    base_seconds = hours * 3600 + minutes * 60

    return date, base_seconds


def format_time_12h(seconds: int, date: datetime) -> str:
    """Format seconds as M/D/YY H:MM AM/PM."""
    hours = seconds // 3600
    minutes = (seconds % 3600) // 60

    period = "AM" if hours < 12 else "PM"
    hours_12 = hours % 12 or 12

    return f"{date.month}/{date.day}/{date.strftime('%y')} {hours_12}:{minutes:02d} {period}"


def get_section_title(seconds: int) -> str:
    """Get section title based on time of day."""
    hours = seconds // 3600

    if hours < 6:
        return "Early morning"
    elif hours < 9:
        return "Morning"
    elif hours < 12:
        return "Late morning"
    elif hours < 14:
        return "Midday"
    elif hours < 17:
        return "Afternoon"
    elif hours < 20:
        return "Evening"
    else:
        return "Night"


def transcribe_with_gemini(audio_path: Path, start_time: int, date: datetime) -> list[dict]:
    """
    Transcribe a single audio file with Gemini.
    Returns list of {timestamp: str, text: str} entries.
    """
    time_str = format_time_12h(start_time, date)

    # Build context from config
    transcription_config = CONFIG.get("transcription", {})
    speaker = transcription_config.get("speaker_name", "Speaker")
    common_names = transcription_config.get("common_names", "")
    domain_context = transcription_config.get("domain_context", "")

    # Build context lines
    context_lines = [
        f"- This is a personal voice diary recorded starting at {time_str}",
        f"- Speaker: {speaker}"
    ]
    if common_names:
        context_lines.append(f"- Common names: {common_names}")
    if domain_context:
        context_lines.append(f"- Domain context: {domain_context}")

    context_block = "\n".join(context_lines)

    prompt = f"""Transcribe this audio recording accurately.

Context:
{context_block}

Instructions:
1. Transcribe all spoken words accurately
2. Use proper punctuation and capitalization
3. Remove filler words (um, uh, like, you know)
4. If there are distinct conversation topics or pauses, separate them with [BREAK]
5. Output ONLY the transcript text, no commentary

Example output:
First topic discussion here. More details about the first thing.
[BREAK]
Second topic starts here. Different subject matter.
[BREAK]
Third segment of conversation."""

    try:
        # Upload and transcribe
        uploaded_file = genai.upload_file(str(audio_path))

        # Wait for processing
        import time
        while uploaded_file.state.name == "PROCESSING":
            time.sleep(1)
            uploaded_file = genai.get_file(uploaded_file.name)

        if uploaded_file.state.name == "FAILED":
            logger.error(f"Gemini upload failed for {audio_path.name}")
            return []

        model = genai.GenerativeModel(CONFIG.get("gemini", {}).get("model", "gemini-2.0-flash"))
        generation_config = genai.types.GenerationConfig(
            temperature=CONFIG.get("gemini", {}).get("temperature", 0.2)
        )
        response = model.generate_content([prompt, uploaded_file], generation_config=generation_config)

        # Cleanup
        try:
            genai.delete_file(uploaded_file.name)
        except Exception:
            pass

        if not response.text:
            return []

        # Parse response into segments
        segments = []
        raw_text = response.text.strip()

        # Split on [BREAK] markers
        parts = [p.strip() for p in raw_text.split("[BREAK]") if p.strip()]

        # Clean up each part - remove internal newlines
        parts = [" ".join(p.split()) for p in parts]

        # Distribute timestamps across segments (rough estimate)
        chunk_duration = 10 * 60  # 10 minute chunks
        time_per_segment = chunk_duration // max(len(parts), 1)

        for i, text in enumerate(parts):
            if len(text) > 10:  # Skip very short fragments
                seg_time = start_time + (i * time_per_segment)
                segments.append({
                    "timestamp": format_time_12h(seg_time, date),
                    "text": text,
                    "seconds": seg_time
                })

        return segments

    except Exception as e:
        logger.error(f"Gemini transcription failed: {e}")
        return []


def format_markdown(segments: list[dict], date: datetime) -> str:
    """Format segments as markdown."""
    if not segments:
        return ""

    # Get speaker name from config
    speaker = CONFIG.get("transcription", {}).get("speaker_name", "Speaker")

    lines = [
        f"# Recording - {date.strftime('%Y-%m-%d')}",
        ""
    ]

    current_section = None

    for seg in segments:
        # Add section header if time period changed
        section = get_section_title(seg["seconds"])
        if section != current_section:
            current_section = section
            lines.append(f"## {section}")
            lines.append("")

        # Format speaker line
        lines.append(f"- {speaker} ({seg['timestamp']}): {seg['text']}")
        lines.append("")

    return "\n".join(lines)


def main():
    logger.info("=" * 50)
    logger.info("Starting Local Loop transcription")

    # Configure Gemini
    api_key = CONFIG.get("gemini", {}).get("api_key")
    if not api_key:
        logger.error("Gemini API key not configured")
        sys.exit(1)
    genai.configure(api_key=api_key)

    try:
        service = get_drive_service()
        work_dir = Path(CONFIG["paths"]["work_dir"])
        output_dir = Path(CONFIG["paths"]["output_dir"])

        # Download new files
        logger.info("Checking for new audio files...")
        files = download_new_files(
            service,
            CONFIG["google_drive"]["folder_id"],
            work_dir
        )

        if not files:
            logger.info("No new files to process.")
            return

        logger.info(f"Processing {len(files)} file(s)...")

        # Group files by date
        files_by_date = defaultdict(list)
        for f in sorted(files):
            try:
                date, base_seconds = parse_chunk_time(f.name)
                files_by_date[date].append((f, base_seconds))
            except (ValueError, IndexError) as e:
                logger.warning(f"Skipping invalid filename: {f.name} - {e}")

        # Process each date
        for date, file_list in files_by_date.items():
            logger.info(f"Processing {len(file_list)} file(s) for {date.strftime('%Y-%m-%d')}")

            all_segments = []

            for audio_path, base_seconds in sorted(file_list, key=lambda x: x[1]):
                # Check for speech using VAD
                if CONFIG.get("vad", {}).get("enabled", False):
                    has_speech, speech_duration = detect_speech(audio_path)
                    if not has_speech:
                        time_str = format_time_12h(base_seconds, date)
                        logger.info(f"  Skipping {audio_path.name}: No speech detected (starts {time_str})")
                        continue
                    logger.info(f"  Speech detected: {speech_duration:.1f}s in {audio_path.name}")

                logger.info(f"  Transcribing: {audio_path.name}")

                segments = transcribe_with_gemini(audio_path, base_seconds, date)
                all_segments.extend(segments)

                logger.info(f"    Got {len(segments)} segment(s)")

            if not all_segments:
                logger.info(f"  No content for {date.strftime('%Y-%m-%d')}")
                continue

            # Sort by time
            all_segments.sort(key=lambda x: x["seconds"])

            # Format and save
            markdown = format_markdown(all_segments, date)

            output_path = output_dir / f"{date.strftime('%Y-%m-%d')}-recording.md"
            output_path.parent.mkdir(parents=True, exist_ok=True)

            with open(output_path, "w") as f:
                f.write(markdown)

            logger.info(f"  Saved: {output_path}")

        logger.info("Pipeline completed successfully")

    except Exception as e:
        logger.exception(f"Pipeline failed: {e}")
        sys.exit(1)


if __name__ == "__main__":
    main()
