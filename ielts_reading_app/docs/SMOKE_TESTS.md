# Smoke test checklist (manual, pre-release)

- [ ] Fresh install → Google Sign-In works
- [ ] Invalid OpenRouter key → user sees clear error, can retry
- [ ] Valid OpenRouter key → diagnostic intro loads
- [ ] Diagnostic test completes and persists result
- [ ] Home shows 3+ passage cards matched to the user's band
- [ ] Passage opens; tap any word → dialog shows Bangla + English meaning
- [ ] Cached word taps load in < 500 ms
- [ ] "Save word" writes to Firestore; appears in Vocabulary tab
- [ ] Questions screen scores correctly; explanations render markdown
- [ ] Progress dashboard reflects the new session
- [ ] Settings → sign out clears secure storage and returns to /login
