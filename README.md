# 🦜 Parrot

**A free, private, on-device meeting recorder for macOS.**

Parrot sits quietly on your Mac and records your Google Meet, Zoom, or any other meeting — transcribing everything in real-time, completely locally. No cloud. No API costs. No data leaving your machine. Just you and your Mac.

---

## Why I Built This

I got tired of paying for meeting transcription services that send my conversations to some server I don't control. I wanted something like [Otter.ai](https://otter.ai/) but fully local and free. So I started building Parrot — a native macOS app that does speech-to-text entirely on-device using [WhisperKit](https://github.com/argmaxinc/WhisperKit) and Apple's Neural Engine.

This is a personal project. I'm building it for fun and learning. It's not perfect, but it works, and I'm sharing it because maybe you want the same thing.

## What It Does

- **Records system audio + microphone** — Captures what everyone says in a meeting (via ScreenCaptureKit) plus your own voice
- **Real-time transcription** — Watch the transcript appear as people talk, powered by WhisperKit running on your Mac's Neural Engine
- **Speaker diarization** — Tries to figure out who said what (basic energy-based approach for now)
- **Searchable history** — All your meetings stored locally with full-text search
- **Export** — Save transcripts as TXT or SRT (subtitle format)
- **Menu bar extra** — Quick start/stop recording from the menu bar
- **Dark mode** — Because of course

## Tech Stack

| What | How |
|------|-----|
| UI | SwiftUI, native macOS (no Electron!) |
| Speech-to-Text | [WhisperKit](https://github.com/argmaxinc/WhisperKit) — on-device, runs on Neural Engine |
| System Audio | ScreenCaptureKit (no virtual audio drivers needed) |
| Microphone | AVAudioEngine |
| Storage | SwiftData + SQLite |
| Target | macOS 14.0+ (Sonoma and later) |

## Screenshots

*Coming soon — the app has a clean dashboard with a big red record button, a sidebar with your meeting history, and a live transcription view.*

## Getting Started

### Prerequisites
- macOS 14.0 (Sonoma) or later
- Xcode 15+
- A Mac with Apple Silicon (recommended) or Intel

### Build & Run

```bash
git clone https://github.com/turantekin/Parrot.git
cd Parrot
open Parrot.xcodeproj
```

Then hit **Run** in Xcode (or `Cmd+R`).

### Permissions

On first launch, Parrot will ask for:
1. **Screen Recording** — needed to capture system audio from meetings (it only records audio, never your screen content)
2. **Microphone** — to capture your voice

Grant both in **System Settings > Privacy & Security**. You may need to restart the app after granting Screen Recording permission (macOS requirement).

### Choose a Model

Parrot uses WhisperKit models for transcription. Pick one during onboarding:

| Model | Size | Speed | Accuracy |
|-------|------|-------|----------|
| tiny | ~40 MB | Fastest | Basic |
| base | ~140 MB | Fast | Good |
| small | ~460 MB | Moderate | Better |
| large-v3-turbo | ~1.5 GB | Slower | Best |

The model downloads automatically on first use. `base` is a good default.

## Project Structure

```
Parrot/
  ParrotApp.swift              # App entry point
  Models/
    Meeting.swift              # Meeting data model (SwiftData)
    TranscriptSegment.swift    # Individual transcript segments
  Services/
    AudioCaptureManager.swift  # System audio + mic capture
    TranscriptionEngine.swift  # WhisperKit wrapper
    DiarizationEngine.swift    # Speaker identification
    RecordingManager.swift     # Orchestrates everything
    ExportService.swift        # TXT/SRT export
  Views/
    ContentView.swift          # Main navigation
    DashboardView.swift        # Landing page with record button
    LiveRecordingView.swift    # Active recording UI
    MeetingDetailView.swift    # Meeting playback + transcript
    SidebarView.swift          # Meeting list
    OnboardingView.swift       # First-launch wizard
    SettingsView.swift         # App preferences
    MenuBarView.swift          # Menu bar extra
```

## What's Next (Ideas / TODOs)

- [ ] Better speaker diarization (integrate [SpeakerKit](https://github.com/argmaxinc/argmax-oss-swift) from Argmax)
- [ ] Meeting summaries & action items (local LLM, maybe MLX?)
- [ ] Calendar integration (auto-name meetings)
- [ ] Audio playback synced with transcript highlighting
- [ ] Keyword bookmarks during recording
- [ ] Better waveform visualization
- [ ] App icon (currently using system bird icon)
- [ ] Notarize and distribute outside Xcode

## Contributing

This is a personal/learning project, but I'd love help! If you want to:

- **Fix a bug** — Open a PR, I'll review it
- **Improve diarization** — The current approach is very basic (energy-based). If you know CoreML/Pyannote, I'd love your help
- **Add a feature** — Open an issue first so we can chat about it
- **Report an issue** — Just open one, no template needed

## Known Issues

- Screen Recording permission can be finicky when running from Xcode (the binary gets re-signed each build, which can invalidate the permission). If recording fails, remove Parrot from Screen Recording in System Settings, re-add it, and restart.
- WhisperKit model download requires internet on first run
- Speaker diarization is basic — it alternates speakers based on silence gaps, not voice fingerprinting

## License

This project is open source. Use it, learn from it, improve it.

---

*Built with SwiftUI, WhisperKit, and a lot of Claude Code sessions at 3am.* 🌙
