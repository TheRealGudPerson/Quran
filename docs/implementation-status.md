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
- [x] Guided first-run Tanzil import for Uthmani, Simple, and metadata source files
- [x] Preserve original Tanzil source files and license notice verbatim in local app storage
- [ ] Run formatter, analyzer, and tests locally on the latest revision (Tanzil importer tests added; not yet executed locally)

## Reader

- [x] Select and document Tanzil Quran text version 1.1 and metadata version 1.0; retain official source and license notices
- [x] Build a resource-pack manifest and verifier
- [x] Load an integrity-checked active text pack and display Arabic verses
- [x] Add Uthmani/simplified variant selection
- [x] Display available translation and transliteration layers from an installed text pack
- [x] Add surah, ayah, juz, hizb, and page navigation
- [ ] Add local search and reading-position persistence

## Study and audio

- [ ] Local database and migrations
- [ ] Bookmarks, notes, highlights, and reading plans
- [ ] Optional in-app network downloader and progress UI (first-run setup currently uses official user downloads)
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
