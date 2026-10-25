# Implementation status

This repository is being built incrementally. A visible UI shell is not the same as a completed reader; features must not be marked complete until they work and have tests.

## Foundation

- [x] Flutter/Dart package manifest and application entry point
- [x] Responsive navigation shell for reader, study, downloads, and settings
- [x] Initial theme mode and accent color controls
- [x] Architecture, data licensing, testing, and release plans
- [x] Initial catalog integrity validator and unit tests
- [x] Resource-pack installer with SHA-256 verification, immutable version directories, active-version pointer, and rollback-safe activation
- [x] Installer integrity, tamper rejection, and failed-update tests
- [x] No GitHub Actions/workflow files; verification is run manually with Flutter CLI commands
- [ ] Generate and commit official Android, Linux, macOS, and Windows scaffolding
- [x] Local JSON manifest/payload import UI for the primary Quran text pack
- [ ] Run formatter, analyzer, and tests locally on the latest revision

## Reader

- [ ] Select and review a canonical Arabic text source and version
- [x] Build a resource-pack manifest and verifier
- [x] Load an integrity-checked active text pack and display Arabic verses
- [x] Add Uthmani/simplified variant selection
- [x] Display available translation and transliteration layers from an installed text pack
- [ ] Add surah, ayah, juz, hizb, and page navigation
- [ ] Add local search and reading-position persistence

## Study and audio

- [ ] Local database and migrations
- [ ] Bookmarks, notes, highlights, and reading plans
- [ ] Network download manager and progress UI (installer integrity and rollback-safe activation implemented)
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
