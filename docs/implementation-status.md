# Implementation status

This repository is being built incrementally. A visible UI shell is not the same as a completed reader; features must not be marked complete until they work and have tests.

## Foundation

- [x] Flutter/Dart package manifest and application entry point
- [x] Responsive navigation shell for reader, study, downloads, and settings
- [x] Initial theme mode and accent color controls
- [x] Architecture, data licensing, testing, and release plans
- [x] Initial catalog integrity validator and unit tests
- [x] Flutter validation workflow
- [ ] Generate and commit official Android, Linux, macOS, and Windows scaffolding
- [ ] Run formatter, analyzer, and tests on a real Flutter SDK

## Reader

- [ ] Select and review a canonical Arabic text source and version
- [ ] Build a resource-pack manifest and verifier
- [ ] Load a verified text pack and display Arabic verses
- [ ] Add Uthmani/simplified variant selection
- [ ] Add translation and transliteration layers
- [ ] Add surah, ayah, juz, hizb, and page navigation
- [ ] Add local search and reading-position persistence

## Study and audio

- [ ] Local database and migrations
- [ ] Bookmarks, notes, highlights, and reading plans
- [ ] Resource download manager with integrity checks and rollback
- [ ] Audio playback and verse synchronization
- [ ] Tafsir, tajweed display, and word-level audio
- [ ] Backup/restore and accessibility pass
- [ ] Android widgets and desktop integration adapters

## Release

- [ ] Windows packaging
- [ ] Linux packaging
- [ ] macOS packaging, signing, and notarization plan
- [ ] Android APK/AAB builds
- [ ] Cross-platform smoke tests and release checklist
