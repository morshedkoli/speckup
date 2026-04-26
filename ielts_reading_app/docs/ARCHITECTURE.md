# Architecture

See PRD §8. This file is a living document — expand here as decisions are made.

## Layering

```
presentation (UI)  →  providers (Riverpod)  →  repository  →  service (OpenRouter / Firestore)
```

The UI never imports `cloud_firestore` or the OpenRouter service layer directly.
