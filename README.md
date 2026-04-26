# SpeakUp Reading — IELTS Reading Trainer

Flutter + Firebase + Google Gemini. Bring-your-own-key, adaptive passages, and tap-to-define words with Bangla meanings.

## Contents of this starter package

- **`SpeakUp_Reading_PRD.docx`** — complete product requirements document (21 sections)
- **`CONTEXT.md`** — single source of truth for AI coding agents (Claude Code, Antigravity, Cursor)
- **`scaffold_project.sh`** — one-shot script that creates the full folder tree with placeholder files so you can open it in an IDE and start building

## Quick start

```bash
# 1. Create the project skeleton
chmod +x scaffold_project.sh
./scaffold_project.sh

# 2. Move into the created folder
cd ielts_reading_app

# 3. Create a Flutter project inside (keeps the skeleton, adds android/ios/etc.)
flutter create --project-name ielts_reading_app --platforms=android --org com.morshed .

# 4. Open in your IDE of choice
code .    # VS Code
# or: android-studio .

# 5. Point your AI agent at docs/PRD.docx and docs/CONTEXT.md, then say:
#    "Read docs/PRD.docx and docs/CONTEXT.md, then scaffold M0."
```

## Before writing code

1. Create a Firebase project and run `flutterfire configure`.
2. Get a Gemini API key from https://aistudio.google.com (this is what each end-user will also do).
3. Register SHA-1 of your debug keystore in Firebase for Google Sign-In.

## Recommended AI agent kick-off prompt

> Read `docs/PRD.docx` and `docs/CONTEXT.md` in full. Summarize back the 8 golden rules from CONTEXT.md to confirm understanding. Then implement milestone **M0** only: set up `pubspec.yaml`, configure Riverpod + GoRouter + Firebase init in `main.dart`, and create the theme. Stop and show me a diff.
