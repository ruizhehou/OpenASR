# OpenASR

> A fast, private, offline-capable macOS speech-to-text app powered by [OpenAI Whisper](https://github.com/openai/whisper) via [whisper.cpp](https://github.com/ggerganov/whisper.cpp).

![macOS 13+](https://img.shields.io/badge/macOS-13%2B-blue)
![Swift 5.9](https://img.shields.io/badge/Swift-5.9-orange)
![whisper.cpp](https://img.shields.io/badge/whisper.cpp-latest-green)
![License: MIT](https://img.shields.io/badge/License-MIT-yellow)

---

## Features

- **Real-time transcription** — Live speech-to-text from your microphone with a sliding-window inference engine
- **File transcription** — Drag & drop or open any audio/video file (MP3, WAV, M4A, MP4, FLAC, OGG, AAC, AIFF…)
- **Auto-copy to clipboard** — Transcription results are automatically copied when recording stops
- **History with export** — Browse past transcriptions, search by text, and export as `.txt`, `.srt`, `.vtt`, or `.json`
- **Multiple Whisper models** — Download and switch between Tiny, Base, Small, Medium, and Large v3 models
- **100% local & private** — All inference runs on-device using Metal GPU acceleration; no data leaves your machine
- **Menu bar app** — Minimal footprint, always accessible from the macOS menu bar
- **Global hotkey** — Toggle recording with ⌘⇧R from any app

---

## Requirements

| Requirement | Version |
|-------------|---------|
| macOS | 13.0 Ventura or later |
| Xcode | 15.0 or later |
| CMake | 3.21+ (for building whisper.cpp) |
| Apple Silicon | Recommended (M1/M2/M3 for real-time use with Small/Medium models) |

Disk space needed for models:

| Model | Size | Languages | Real-time? |
|-------|------|-----------|-----------|
| Tiny (EN) | 75 MB | English only | ✅ |
| Tiny | 75 MB | Multilingual | ✅ |
| Base (EN) | 142 MB | English only | ✅ |
| Base | 142 MB | Multilingual | ✅ |
| Small (EN) | 466 MB | English only | ✅ |
| Small | 466 MB | Multilingual | ✅ |
| Medium | 1.5 GB | Multilingual | ⚠️ Apple Silicon only |
| Large v3 | 3.1 GB | Multilingual | ❌ Too slow for real-time |

---

## Building from Source

### 1. Clone the repository

```bash
git clone --recursive https://github.com/yourusername/OpenASR.git
cd OpenASR
```

> The `--recursive` flag clones the `whisper.cpp` submodule automatically.

### 2. Build whisper.cpp

```bash
cd Packages/whisper.cpp
cmake -B build-macos \
  -DCMAKE_BUILD_TYPE=Release \
  -DGGML_METAL=ON \
  -DGGML_ACCELERATE=ON \
  -DWHISPER_BUILD_TESTS=OFF \
  -DWHISPER_BUILD_EXAMPLES=OFF
cmake --build build-macos --config Release -j$(sysctl -n hw.logicalcpu)
cd ../..
```

### 3. Generate the Xcode project

```bash
# Install xcodegen if needed
brew install xcodegen

xcodegen generate
```

### 4. Open in Xcode and build

```bash
open OpenASR.xcodeproj
```

Press **⌘B** to build, or **⌘R** to run.

Alternatively, build from the command line:

```bash
xcodebuild build \
  -project OpenASR.xcodeproj \
  -scheme OpenASR \
  -configuration Release \
  CODE_SIGNING_ALLOWED=NO
```

---

## Usage

### Menu Bar

After launching, OpenASR appears as a waveform icon (⌇) in the menu bar. Click it to open the popover.

### Real-Time Transcription

1. Open the popover and select a downloaded model from the dropdown
2. Click **Record** (or press **⌘⇧R**)
3. Speak — transcription appears live as you talk
4. Click **Stop** — the final transcript is copied to your clipboard automatically

### File Transcription

1. Drag an audio or video file onto the drop zone in the popover or main window
2. Alternatively, click **Choose File...** to open a file picker
3. OpenASR extracts audio, chunks it into 30-second windows, and transcribes each chunk
4. Progress is shown in real time; the result is saved to history and copied to clipboard

### History

Click the arrow icon (↗) in the popover header to open the main window, then navigate to **History** to:
- Browse all past transcriptions
- Search by text content
- Export selected records as TXT, SRT (subtitles), VTT (WebVTT), or JSON

### Model Management

Navigate to **Models** in the main window (or **Settings → Models**) to:
- Download models from Hugging Face
- See speed/accuracy ratings for each model
- Switch the active model
- Delete models you no longer need

### Settings

Open **Settings** (⌘,) to configure:
- Transcription language (auto-detect or specific language)
- Translation to English (multilingual models only)
- Timestamp display
- Auto-copy to clipboard
- Launch at login

---

## Architecture

```
OpenASR
├── App/               NSStatusItem menu bar + NSWindow management
├── Bridge/            Objective-C++ wrapper around whisper.cpp C API
│   └── WhisperBridge  Sole ABI boundary between Swift and C++
├── Engine/
│   ├── WhisperEngine  Swift actor — serializes inference (thread safety)
│   ├── AudioCapture   AVAudioEngine tap → 16 kHz mono Float32 PCM
│   └── FileEngine     AVAssetReader pipeline → chunked transcription
├── Models/            Pure value types (Codable, Sendable)
├── Services/
│   ├── ModelManager   Download, verify, cache GGUF model files
│   ├── HistoryStore   JSON persistence + SRT/VTT/TXT/JSON export
│   ├── Clipboard      NSPasteboard wrapper
│   └── Hotkey         Carbon EventHotKey global shortcut
├── ViewModels/        @MainActor ObservableObjects bridging engine ↔ UI
└── Views/             SwiftUI views (menu bar popover + main window)
```

**Key design decisions:**

- **`actor WhisperEngine`** — `whisper_context` is not thread-safe; Swift actors enforce serial access at the language level with zero boilerplate
- **Sliding window** — Whisper is not a streaming model. We maintain a 30-second rolling buffer and run inference every second, giving the appearance of real-time transcription
- **JSON history** — Simple, portable, directly debuggable. Trivially migratable to SQLite if needed
- **Prebuilt dylibs** — whisper.cpp is compiled once via CMake and linked as dylibs, keeping the Xcode build fast

---

## Running Tests

```bash
xcodebuild test \
  -project OpenASR.xcodeproj \
  -scheme OpenASRTests \
  -configuration Debug \
  CODE_SIGNING_ALLOWED=NO
```

Tests cover: `HistoryStore` (CRUD, search, export), `ModelManager` (paths, properties), `TranscriptionSegment` (formatting, timestamps), and `TranscriptionRecord` (full text, preview).

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit your changes: `git commit -m "Add my feature"`
4. Push: `git push origin feature/my-feature`
5. Open a Pull Request

**Code style:** Follow Swift API Design Guidelines. Run `swiftlint` before submitting (config coming soon).

---

## License

OpenASR is released under the [MIT License](LICENSE).

whisper.cpp is also MIT licensed — see [Packages/whisper.cpp/LICENSE](Packages/whisper.cpp/LICENSE).

OpenAI Whisper model weights are released under the [MIT License](https://github.com/openai/whisper/blob/main/LICENSE).

---

## Acknowledgements

- [OpenAI Whisper](https://github.com/openai/whisper) — the underlying ASR model
- [ggerganov/whisper.cpp](https://github.com/ggerganov/whisper.cpp) — highly optimized C/C++ inference with Metal support
- [Hugging Face](https://huggingface.co/ggerganov/whisper.cpp) — model hosting
