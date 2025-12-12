# Local Loop Setup Guide

This guide walks you through setting up Local Loop from scratch.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Google Cloud Setup](#google-cloud-setup)
3. [Gemini API Setup](#gemini-api-setup)
4. [iOS App Setup](#ios-app-setup)
5. [Python Transcriber Setup](#python-transcriber-setup)
6. [Scheduling](#scheduling)
7. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### For iOS App
- macOS with Xcode 15 or later
- Apple Developer account (free or paid)
- [Homebrew](https://brew.sh/) package manager
- XcodeGen: `brew install xcodegen`

### For Python Transcriber
- Python 3.10 or later
- FFmpeg: `brew install ffmpeg`
- pip (comes with Python)

### Accounts Needed
- Google account (for Drive storage)
- Google Cloud account (for OAuth - free tier)
- Gemini API key (free tier available)

---

## Google Cloud Setup

### 1. Create a Google Cloud Project

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Click "Select a project" → "New Project"
3. Name it something like "Local Loop"
4. Click "Create"

### 2. Enable Google Drive API

1. In the Cloud Console, go to "APIs & Services" → "Library"
2. Search for "Google Drive API"
3. Click on it and press "Enable"

### 3. Configure OAuth Consent Screen

1. Go to "APIs & Services" → "OAuth consent screen"
2. Choose "External" (unless you have a Workspace account)
3. Fill in required fields:
   - App name: "Local Loop"
   - User support email: your email
   - Developer contact: your email
4. Click "Save and Continue"
5. Skip Scopes (click "Save and Continue")
6. Add yourself as a test user
7. Click "Save and Continue"

### 4. Create OAuth Credentials

#### For iOS App:

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "OAuth client ID"
3. Application type: **iOS**
4. Name: "Local Loop iOS"
5. Bundle ID: `com.example.localloop` (or your custom bundle ID)
6. Click "Create"
7. **Copy the Client ID** - you'll need this for Info.plist

#### For Python Transcriber:

1. Click "Create Credentials" → "OAuth client ID"
2. Application type: **Desktop app**
3. Name: "Local Loop Transcriber"
4. Click "Create"
5. Click "Download JSON"
6. Save as `credentials.json` in the `transcriber/` directory

---

## Gemini API Setup

1. Go to [Google AI Studio](https://aistudio.google.com/)
2. Sign in with your Google account
3. Click "Get API Key" → "Create API Key"
4. Select your Google Cloud project (or create one)
5. **Copy the API key** - you'll need this for config.yaml

**Note**: Gemini has a free tier with generous limits for personal use.

---

## iOS App Setup

### 1. Configure Credentials

Edit `ios/LocalLoop/Resources/Info.plist`:

```xml
<!-- Find and replace YOUR_GOOGLE_CLIENT_ID with your actual client ID -->
<key>GIDClientID</key>
<string>YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com</string>

<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_GOOGLE_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

### 2. Configure Bundle ID

Edit `ios/project.yml`:

```yaml
options:
  bundleIdPrefix: com.yourcompany  # Change this

targets:
  LocalLoop:
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.yourcompany.localloop  # Change this
```

**Important**: The bundle ID must match what you registered in Google Cloud.

### 3. Generate Xcode Project

```bash
cd ios
xcodegen generate
```

This creates `LocalLoop.xcodeproj`.

### 4. Open in Xcode

```bash
open LocalLoop.xcodeproj
```

### 5. Configure Signing

1. Select the "LocalLoop" target
2. Go to "Signing & Capabilities"
3. Select your Team (Apple Developer account)
4. Let Xcode manage signing

### 6. Build and Run

1. Connect your iPhone
2. Select your device as the build target
3. Press Cmd+R to build and run

### 7. First Launch

1. Open the app on your iPhone
2. Go to Settings tab
3. Sign in with Google
4. Select or create a Google Drive folder for recordings
5. Grant microphone permission when prompted
6. Start recording!

---

## Python Transcriber Setup

### 1. Create Virtual Environment

```bash
cd transcriber
python3 -m venv venv
source venv/bin/activate
```

### 2. Install Dependencies

```bash
pip install -r requirements.txt
```

### 3. Install FFmpeg

```bash
brew install ffmpeg
```

### 4. Configure Settings

```bash
cp config.example.yaml config.yaml
```

Edit `config.yaml`:

```yaml
google_drive:
  folder_id: "YOUR_FOLDER_ID"  # From Google Drive URL

paths:
  work_dir: "/tmp/localloop"
  output_dir: "/path/to/your/notes/Transcripts"  # Where transcripts go

transcription:
  speaker_name: "YourName"  # Your name for transcripts
  common_names: "John, Jane"  # People you talk to often (optional)
  domain_context: ""  # Work terms, proper nouns (optional)

gemini:
  api_key: "YOUR_GEMINI_API_KEY"
  model: "gemini-2.0-flash"
  temperature: 0.2

vad:
  enabled: true
  threshold: 0.5
  min_speech_duration_ms: 250

logging:
  level: "INFO"
```

### 5. Set Up Google OAuth

Place your `credentials.json` (downloaded from Google Cloud) in the `transcriber/` directory.

### 6. First Run (OAuth Flow)

```bash
source venv/bin/activate
python transcribe.py
```

On first run:
1. A browser window will open
2. Sign in with your Google account
3. Grant Drive access
4. The script will save `token.json` for future runs

---

## Scheduling

### macOS (launchd)

1. Copy the example plist:
   ```bash
   cp transcriber/com.localloop.transcriber.example.plist ~/Library/LaunchAgents/com.localloop.transcriber.plist
   ```

2. Edit the plist with your paths:
   ```bash
   nano ~/Library/LaunchAgents/com.localloop.transcriber.plist
   ```

   Update:
   - `/path/to/your/venv/bin/python3` → your actual venv path
   - `/path/to/local-loop/transcriber` → your actual transcriber path

3. Load the schedule:
   ```bash
   launchctl load ~/Library/LaunchAgents/com.localloop.transcriber.plist
   ```

4. Verify it's loaded:
   ```bash
   launchctl list | grep localloop
   ```

**Default schedule**: Daily at 2:00 AM

### Linux (cron)

Add to crontab (`crontab -e`):
```
0 2 * * * cd /path/to/transcriber && ./venv/bin/python transcribe.py >> /tmp/localloop.log 2>&1
```

---

## Troubleshooting

### iOS App

**"Invalid Bundle ID" error**
- Ensure the bundle ID in `project.yml` matches your Google Cloud OAuth configuration

**Google Sign-In fails**
- Verify the Client ID in Info.plist is correct
- Check that the URL scheme matches the client ID
- Ensure you're a test user in Google Cloud Console

**Recording stops unexpectedly**
- Check that Background Modes are enabled (audio, fetch, processing)
- Disable battery optimization for the app

### Python Transcriber

**"No module named 'google'"**
- Activate the virtual environment: `source venv/bin/activate`
- Reinstall dependencies: `pip install -r requirements.txt`

**OAuth error / Invalid credentials**
- Delete `token.json` and run again to re-authenticate
- Verify `credentials.json` is the Desktop app credentials

**"No new files to process"**
- Check the Google Drive folder ID is correct
- Verify files are being uploaded by the iOS app
- Check the `.processed` file isn't blocking files

**FFmpeg not found**
- Install with Homebrew: `brew install ffmpeg`
- Or add FFmpeg to your PATH

**VAD model fails to load**
- Ensure PyTorch is installed: `pip install torch torchaudio`
- Check you have enough memory (~500MB for the model)

### General

**View logs**
```bash
cat /tmp/localloop-transcriber.log
```

**Reprocess all files**
```bash
echo "" > .processed
python transcribe.py
```

**Test transcription manually**
```bash
source venv/bin/activate
python transcribe.py
```

---

## Getting Help

- Check [GitHub Issues](https://github.com/mikeprebledotcom/localloop/issues)
- Review the [README](README.md) for architecture overview
