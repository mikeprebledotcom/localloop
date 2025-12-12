# Local Loop

**Open-source, self-hosted voice diary and transcription system.**

Local Loop is an alternative to commercial always-on voice recorders like Limitless, Plaud, and Rewind. Instead of trusting a startup with your most personal data, you control the entire pipeline: your iPhone records, your Google Drive stores, your Mac transcribes, your notes app saves the results.

## Why Local Loop?

- **Own your data** - Recordings go to YOUR Google Drive, transcripts to YOUR notes app
- **No subscriptions** - One-time setup, minimal ongoing costs (~$0-5/month)
- **No vendor lock-in** - Standard formats (M4A audio, Markdown text)
- **No third-party servers** - Your data never touches someone else's startup servers
- **Fully customizable** - Modify the code to fit your workflow

## Features

### iOS App
- Continuous background audio recording
- 10-minute chunks with seamless 5-second overlap
- Automatic upload to Google Drive
- WiFi-only and charging-only upload modes
- Minimal battery impact (~5-10% additional daily drain)

### Python Transcriber
- Downloads audio from Google Drive
- **Voice Activity Detection (VAD)** - Skips silent chunks to save API costs
- Gemini-powered transcription with custom context
- Markdown output organized by time of day
- Scheduled daily runs via macOS launchd (or cron on Linux)

## Architecture

```
┌─────────────┐     ┌──────────────┐     ┌─────────────────┐     ┌──────────────┐
│   iPhone    │────▶│ Google Drive │────▶│ Mac Transcriber │────▶│ Notes App    │
│  (Records)  │     │  (Storage)   │     │    (Gemini)     │     │  (Markdown)  │
└─────────────┘     └──────────────┘     └─────────────────┘     └──────────────┘
```

## Requirements

- **iOS App**: macOS with Xcode 15+, Apple Developer account (free works for personal use)
- **Transcriber**: macOS or Linux, Python 3.10+
- **APIs**: Google Cloud account (free), Gemini API key (free tier available)
- **Storage**: Google Drive (free 15GB is plenty)

## Cost Breakdown

| Component | Cost |
|-----------|------|
| Google Drive | Free (15GB included) |
| Google Cloud OAuth | Free |
| Gemini API | Free tier: ~1,500 requests/day |
| Apple Developer (device install) | Free (with limitations) or $99/year |

**Typical monthly cost: $0-5** depending on usage. The free Gemini tier handles most personal use cases. VAD filtering reduces API calls by 50-80% by skipping silent audio.

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
# Recording - 2025-01-15

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

## FAQ

### "Privacy-focused but uses Google?"

Fair point. Let me be clear about what this project offers:

- **What it IS**: Data ownership. Your recordings stay in YOUR Google account, not a startup's servers. You can delete everything anytime. No company is training models on your conversations.
- **What it ISN'T**: End-to-end encrypted, zero-knowledge, or "Google can't see it." Google theoretically has access to your Drive files and Gemini processes your audio.

If you need true privacy, you'd want local-only transcription (like Whisper). That's a great PR opportunity - contributions welcome!

### "Why Google Drive instead of local/S3/Dropbox?"

Google Drive was chosen because:
1. Free 15GB storage
2. Google Sign-In SDK is well-maintained for iOS
3. Single auth flow for both storage and Gemini API

Want to add S3, Dropbox, or local-only support? PRs welcome!

### "Why Gemini instead of Whisper?"

Gemini was chosen for:
1. No local GPU/CPU requirements
2. Excellent accuracy with context hints
3. Free tier is generous

Local Whisper support would be a great addition for true offline/privacy use. The transcriber is modular enough to swap backends.

### "What about Android?"

Not currently supported. The iOS app would need to be rewritten. If you're an Android developer interested in contributing, please open an issue!

### "Battery drain?"

Expect roughly 5-10% additional daily battery drain. The app uses AVAudioRecorder with hardware-accelerated AAC encoding, which is fairly efficient. Tips:
- Enable "WiFi-only" uploads to avoid cellular radio usage
- Enable "Require charging" to batch uploads

### "Is this legal?"

**You are responsible for complying with local laws.** Many jurisdictions have wiretapping/eavesdropping laws:

- **One-party consent** (e.g., most US states): You can record conversations you're part of
- **Two-party/all-party consent** (e.g., California, many EU countries): All parties must consent

This tool is designed for **personal voice memos** - recording your own thoughts, ideas, and reminders. If you use it to record conversations with others, ensure you have appropriate consent.

**The authors accept no liability for misuse of this software.**

### "Can I use this for [meeting transcription/interviews/etc]?"

Technically yes, but consider:
1. Legal consent requirements (see above)
2. Better tools exist for structured recordings (Otter.ai, etc.)
3. This is optimized for personal, continuous capture

## Roadmap / Contribution Ideas

- [ ] Local Whisper transcription option
- [ ] Android app
- [ ] Alternative cloud storage (S3, Dropbox, local)
- [ ] Web UI for browsing transcripts
- [ ] Better search/tagging system
- [ ] Speaker diarization (who said what)

## Contributing

Contributions are welcome! Please:
1. Fork the repository
2. Create a feature branch
3. Submit a pull request

See the roadmap above for ideas, or open an issue to discuss new features.

## License

MIT License - See [LICENSE](LICENSE) for details.

## Acknowledgments

- [Silero VAD](https://github.com/snakers4/silero-vad) - Voice Activity Detection
- [Google Sign-In for iOS](https://github.com/google/GoogleSignIn-iOS)
- [Google API Client for REST](https://github.com/google/google-api-objectivec-client-for-rest)
- [Gemini API](https://ai.google.dev/)
