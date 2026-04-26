# CONTEXT.md — SpeakUp Reading (IELTS Reading Trainer)

> Read this file **first** if you are an AI coding agent (Claude Code, Antigravity, Cursor, etc.) working on this repository. It is the single source of truth for conventions, constraints, and wiring decisions. The detailed PRD lives in `docs/PRD.docx`.

---

## 1. What this app is

An Android app built in Flutter that helps learners (primarily from Bangladesh) improve their **IELTS Reading** band score. Every passage, question, explanation, and word definition is generated on demand by **Google Gemini**, using **each user's own API key** (Bring-Your-Own-Key). Firebase handles auth, storage, and persistence.

The signature feature: inside any passage, **every word is tappable** and opens a dialog showing the Bangla meaning, English meaning, pronunciation, part of speech, and an example sentence.

---

## 2. Stack (non-negotiable)

| Layer | Choice |
|-------|--------|
| UI | Flutter 3.x, Material 3 |
| State | Riverpod 2.x (code-gen) |
| Routing | go_router |
| Auth | Firebase Auth + Google Sign-In |
| DB | Cloud Firestore (asia-south1) |
| AI | `google_generative_ai` Dart SDK (Gemini 2.5 Flash) |
| Secure store | `flutter_secure_storage` |
| Offline cache | Hive + hive_flutter |
| Models | freezed + json_serializable |
| Logging | `logger` package + Crashlytics in release |

---

## 3. Golden rules for agents

1. **Never hard-code a Gemini API key.** Always read it through `SecureStorageService` via an injected Riverpod provider.
2. **No Firestore calls in UI.** UI → provider → repository → firestore_service. One-way, no shortcuts.
3. **Every Gemini prompt lives in `lib/services/gemini/prompts.dart`** and is referenced by name, never inlined.
4. **Every Gemini response must be typed.** Ask for JSON, parse with freezed models, retry once on failure, surface a friendly error on the second failure.
5. **Feature-first folders.** New screen goes under `lib/features/<feature_name>/` with `data/`, `domain/`, `presentation/`, `providers/` subfolders.
6. **Run codegen after model/provider changes:**
   `dart run build_runner build --delete-conflicting-outputs`
7. **Do not introduce new packages** without updating `pubspec.yaml` AND a short justification in `docs/DECISIONS.md`.
8. **One feature per diff.** Do not touch `features/reading` and `features/progress` in the same PR.

---

## 4. Routing map (GoRouter)

```
/splash                   → SplashPage (decides next route)
/onboarding               → first-run carousel
/login                    → Google Sign-In
/api-key-setup            → paste + validate Gemini key (blocks further progress)
/diagnostic/intro         → diagnostic intro
/diagnostic/test          → placement test runner
/diagnostic/result        → band result
/home                     → recommended passages
/passage/:passageId       → reading view with tappable words
/passage/:passageId/questions → questions for the passage
/passage/:passageId/result    → per-session result
/vocabulary               → saved words list
/progress                 → dashboard
/settings                 → profile, key management, retake diagnostic, sign out
```

**Redirect rule (in `app_router.dart`):**
```
if (!signedIn)                → /login
if (signedIn && !apiKeySet)   → /api-key-setup
if (signedIn && apiKeySet && !diagnosticTaken) → /diagnostic/intro
else → /home
```

---

## 5. Firestore schema (summary)

```
/users/{uid}                          → profile + band + streak
/users/{uid}/sessions/{sessionId}     → one per completed reading set
/users/{uid}/savedWords/{wordId}      → user's personal vocab
/passages/{passageId}                 → shared cache of generated passages
/wordDefinitions/{word}               → shared cache of word definitions (key = lowercased word)
```

Security rules: each user may read/write only their own `/users/{uid}/**` subtree. `/passages` and `/wordDefinitions` are readable by any signed-in user; writes happen via Cloud Functions (service account) only.

---

## 6. Gemini contract — word definition (example)

Prompt → **must** request `responseMimeType: "application/json"` with this exact shape:

```json
{
  "word": "ubiquitous",
  "ipa": "/juːˈbɪkwɪtəs/",
  "partOfSpeech": "adjective",
  "banglaMeaning": "সর্বব্যাপী",
  "englishMeaning": "present, appearing, or found everywhere",
  "exampleEn": "Smartphones have become ubiquitous in modern life.",
  "exampleBn": "আধুনিক জীবনে স্মার্টফোন সর্বব্যাপী হয়ে উঠেছে।"
}
```

Before calling Gemini, **always** check `/wordDefinitions/{lowercasedWord}` in Firestore. On cache miss, call Gemini, then write the response back to the cache before resolving the UI promise.

---

## 7. Build-order guidance (recommended for agents)

1. `core/` (router, theme, storage, utils)
2. `services/gemini/` + `services/firebase/`
3. `features/auth/`
4. `features/api_key_setup/`
5. `features/diagnostic/`
6. `features/home/`
7. `features/reading/` (passage view → TappableText → WordDefinitionDialog → questions → result)
8. `features/vocabulary/`
9. `features/progress/`
10. `features/settings/`
11. Firestore rules + CI + Crashlytics + release build

Stop and show a diff **after every milestone** (M0–M7 in the PRD).

---

## 8. Done-criteria for the reading feature (hardest part)

- [ ] Passage is rendered with `TappableText`, which splits the passage into word-tokens and punctuation.
- [ ] Tapping any word opens `WordDefinitionDialog` within 300 ms for cached words.
- [ ] On cache miss, dialog shows a skeleton loader, then populates within ~4 s.
- [ ] Dialog has a "Save word" button that writes to `/users/{uid}/savedWords`.
- [ ] Questions screen supports TFNG, MCQ, matching headings, and short-answer.
- [ ] Result screen shows per-question correctness + AI-written explanations in markdown.
- [ ] Session is persisted to `/users/{uid}/sessions`.
- [ ] Progress dashboard picks up the new session on the next open.

---

## 9. Things the agent should **not** do

- Don't add ads, analytics SDKs, or tracking SDKs beyond Firebase Analytics.
- Don't add a backend of your own; we already use Firebase.
- Don't switch state management away from Riverpod.
- Don't use `setState` in new code — use Riverpod providers.
- Don't add iOS-specific configuration; keep the code iOS-compatible but don't target it.
