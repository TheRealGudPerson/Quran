# Quran Reader

A cross-platform Quran reading and study application built with Flutter and Dart for Windows, Linux, macOS, and Android.

## Project status

Planning and foundation stage. No Quran text, translations, tafsir, recitations, or fonts are bundled yet. Each resource must have documented provenance, attribution, and redistribution terms before inclusion.

## Product goals

- Offline-first reading and local-only personal data.
- Switchable Uthmani and simplified Arabic representations.
- Multiple translations, transliteration, and tafsir.
- Surah, ayah, juz, hizb, and page navigation.
- Recitation playback, verse synchronization, repeat and memorization tools, and word-level audio where permitted.
- Search, bookmarks, notes, highlights, tajweed display, reading plans, accessibility, widgets, and encrypted backup/restore.
- Customizable appearance and Arabic typography.
- Release packages for Windows, Linux, macOS, and Android.

## Data integrity and licensing

The Quran text must be sourced from a traceable, versioned reference and validated before release. Translation, tafsir, audio, and font resources must each have explicit licensing and attribution records. Public availability does not imply permission to redistribute. See `docs/data-sources-and-licensing.md` once the foundation documentation is added.

## Development

The application uses Flutter/Dart. Platform scaffolding should be generated with Flutter tooling rather than hand-authored. See `docs/architecture.md`, `docs/testing.md`, and `docs/releases.md` for the planned implementation standards.

## License

The software license has not yet been selected. No license should be inferred for third-party Quran resources from this project README.
