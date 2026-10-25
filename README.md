# Quran Reader

A cross-platform Quran reading and study application built with Flutter and Dart for Windows, Linux, macOS, and Android.

## Current status

The project foundation is in progress on `feature/flutter-quran-reader`. The current commit includes a responsive UI shell, theme controls, architecture and licensing documentation, Quran catalog and text-pack validators, a checksum-verifying resource-pack installer with versioned activation and rollback safety, a local JSON pack-import screen, and a reader view with Uthmani/simplified script switching plus translation/transliteration display. The repository intentionally contains no GitHub Actions workflows.

**This is not yet a functional Quran reader.** No Quran text, translations, tafsir, recitations, or fonts are bundled yet. The app intentionally does not invent or silently transform sacred text while the source edition and redistribution terms are being verified.

See [implementation status](docs/implementation-status.md) for the current checklist.

## Product goals

- Offline-first reading and local-only personal data.
- Switchable Uthmani and simplified Arabic representations from separately verified source variants.
- Multiple translations, transliteration, and tafsir.
- Surah, ayah, juz, hizb, and page navigation.
- Recitation playback, verse synchronization, repeat and memorization tools, and word-level audio where permitted.
- Search, bookmarks, notes, highlights, tajweed display, reading plans, accessibility, widgets, and encrypted backup/restore.
- Customizable appearance and Arabic typography.
- Release packages for Windows, Linux, macOS, and Android.
- Quran reader remains a separate app from Qibla/prayer utilities.

## Requirements

Install the current stable Flutter SDK and the platform tools described in the [Flutter installation guide](https://docs.flutter.dev/get-started/install).

From the repository root, generate missing native platform scaffolding first:

```bash
flutter doctor
bash tool/bootstrap-platforms.sh
flutter pub get
flutter run
```

Then run checks:

```bash
dart format lib test
flutter analyze
flutter test
```

The native project directories are generated from Flutter tooling. The bootstrap script only copies platform directories that do not already exist.

## Data integrity and licensing

The Quran text must be sourced from a traceable, versioned reference and validated before release. Translation, tafsir, audio, and font resources must each have explicit licensing and attribution records. Public availability does not imply permission to redistribute.

See [data sources and licensing](docs/data-sources-and-licensing.md) before adding any resource pack.

## Documentation

- [Architecture](docs/architecture.md)
- [Data sources and licensing](docs/data-sources-and-licensing.md)
- [Resource pack format](docs/resource-pack-format.md)
- [Testing strategy](docs/testing.md)
- [Cross-platform releases](docs/releases.md)
- [Implementation status](docs/implementation-status.md)

## License

The software license has not yet been selected. No license should be inferred for third-party Quran resources from this project README.
