# Local Loop

**Privacy-focused, self-hosted voice diary and transcription system.**

Local Loop is an open-source alternative to commercial always-on voice recorders like Limitless, Plaud, and Rewind. Your voice data stays on your devices and your cloud accounts - no third-party servers, no Big Tech surveillance.

## Why Local Loop?

- **Own your data** - Recordings go to YOUR Google Drive, transcripts to YOUR notes app
- **No subscriptions** - One-time setup, no monthly fees
- **No cloud lock-in** - Standard formats (M4A audio, Markdown text)
- **Privacy first** - No telemetry, no tracking, no data mining
- **Fully customizable** - Modify the code to fit your workflow

## Features

### iOS App
- Continuous background audio recording
- 10-minute chunks with seamless 5-second overlap
- Automatic upload to Google Drive
- WiFi-only and charging-only upload modes
- Retry logic with exponential backoff

### Python Transcriber
- Downloads audio from Google Drive
- **Voice Activity Detection (VAD)** - Skips silent chunks to save API costs
- Gemini-powered transcription with custom domain context
- Markdown output organized by time of day
- Scheduled daily runs via macOS launchd

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐     ┌──────────────┐
│   iPhone    │────▶│ Google Drive │────▶│ Mac Transcriber │────▶│ Notes App    │
│  (Records)  │     │  (Storage)   │     │    (Gemini)     │     │  (Markdown)  │
└─────────────┘     └──────────────┘     └─────────────────┘     └──────────────┘
```

## Requirements

- **iOS App**: macOS with Xcode 15+, Apple Developer account
- **Transcriber**: macOS or Linux, Python 3.10+
- **APIs**: Google Cloud account, Gemini API key
- **Storage**: Google Drive (free tier works)

## Quick Start

1. **Clone this repo**
   ```bash
   git clone https://github.com/mikeprebledotcom/localloop.git
   cd localloop
   ```

2. **Set up Google Cloud credentials** - See [SETUP.md](SETUP.md#google-cloud-setup)

3. **Get a Gemini API key** - See [SETUP.md](SETUP.md#gemini-api-setup)

4. **Build and install the iOS app** - See [SETUP.md](SETUP.md#ios-app-setup)

5. **Configure the Python transcriber** - See [SETUP.md](SETUP.md#python-transcriber-setup)

6. **Schedule daily transcription** - See [SETUP.md](SETUP.md#scheduling)

For detailed instructions, see **[SETUP.md](SETUP.md)**.

## Configuration

### iOS App
Edit `ios/LocalLoop/Resources/Info.plist` with your Google OAuth Client ID.

### Python Transcriber
Copy `transcriber/config.example.yaml` to `transcriber/config.yaml` and fill in:
- Google Drive folder ID
- Gemini API key
- Output directory path
- Speaker name and domain context (optional, improves accuracy)

## Output Format

Transcripts are saved as Markdown files organized by time of day:

```markdown
# Phone Recording - 2025-01-15

## Morning

- Speaker (1/15/25 8:30 AM): First thought of the day...

## Afternoon

- Speaker (1/15/25 2:15 PM): Meeting notes here...
```

## Voice Activity Detection

Local Loop includes Silero VAD to automatically skip silent audio chunks. This saves significant API costs when you have long periods without speaking (e.g., working at your desk).

Configure in `config.yaml`:
```yaml
vad:
  enabled: true
  threshold: 0.5  # Speech probability (0-1)
```

## Legal Notice

**Important**: Recording conversations may be subject to local laws. Many jurisdictions require consent from all parties being recorded. This software is intended for personal voice memos and should be used responsibly and legally.

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

## License

MIT License - See [LICENSE](LICENSE) for details.

## Acknowledgments

- [Silero VAD](https://github.com/snakers4/silero-vad) - Voice Activity Detection
- [Google Sign-In for iOS](https://github.com/google/GoogleSignIn-iOS)
- [Google API Client for REST](https://github.com/google/google-api-objectivec-client-for-rest)
- [Gemini API](https://ai.google.dev/)
