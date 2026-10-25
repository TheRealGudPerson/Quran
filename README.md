# Quran Reader

A cross-platform Quran reading and study application built with Flutter and Dart for Windows, Linux, macOS, and Android.

## Current status

The reader foundation now includes:

- A responsive Flutter shell with Reader, Study, Downloads, and Settings sections.
- A verified resource-pack installer with SHA-256 validation, versioned storage, and rollback-safe activation.
- A guided first-run import for the official Tanzil Quran text editions.
- Uthmani and Simple/Imla'ei script switching.
- Surah, ayah, juz, hizb, and page navigation from official Tanzil metadata.
- Translation and transliteration display support when those layers are supplied by a compatible pack.
- Visible source/license information in the reader.

**No Quran text is bundled in the repository or application installer.** For the first reading session, download the source files directly from Tanzil and import them in the app. The original source files are retained unchanged in the app's local support directory. The current importer supports the Tanzil 1.1 Hafs text and the accompanying version 1.0 structural metadata.

There are intentionally **no GitHub Actions workflows** in this repository. Formatting, analysis, tests, and builds are manual commands.

See [implementation status](docs/implementation-status.md) for the feature checklist and unverified items.

## First-run Quran setup

1. Install Flutter and the platform tools described in the [Flutter installation guide](https://docs.flutter.dev/get-started/install).
2. Launch the app and open **Downloads**.
3. Open the official [Tanzil text download page](https://tanzil.net/download/). Agree to Tanzil's terms, download the **Uthmani** edition and the **Simple** edition, and select **Text (with aya numbers)** for both. Keep the pause-mark, sajdah, rub-el-hizb, and other options identical for the two files.
4. Download the official [Quran metadata XML](https://tanzil.net/res/text/metadata/quran-data.xml).
5. Select the three files together in the app. Their filenames must contain `uthmani` and `simple` respectively, and the metadata file must end in `.xml`.
6. The app validates all 114 surahs and 6,236 ayahs, checks the page/juz/hizb boundaries, verifies the generated pack, and activates it only after validation succeeds.

Tanzil's license permits use in an application with attribution and a link back to Tanzil, but **the text itself must not be changed**. The importer preserves each verse string as supplied and stores the original downloaded files unchanged. The app retains the required copyright/license notice and shows source information in the reader. Review the [Tanzil text license](https://tanzil.net/docs/Text_License) and [metadata documentation](https://tanzil.net/docs/Quran_Metadata).

## Build and run

From the repository root, generate missing native platform scaffolding first:

```bash
flutter doctor
bash tool/bootstrap-platforms.sh
flutter pub get
flutter run
```

Run manual checks:

```bash
dart format lib test
flutter analyze
flutter test
```

Build on a machine with the relevant platform toolchain installed:

```bash
flutter build linux
flutter build windows
flutter build macos
flutter build apk
```

Run only the build command supported by the current host. For example, Windows and macOS builds require their respective host environments. These commands are not executed automatically by GitHub.

The native project directories are generated from Flutter tooling. The bootstrap script only copies platform directories that do not already exist.

## Product goals

- Offline-first reading and local-only personal data.
- Switchable Uthmani and simplified Arabic representations from separately verified source variants.
- Multiple translations, transliteration, and tafsir.
- Surah, ayah, juz, hizb, and page navigation.
- Recitation playback, verse synchronization, repeat and memorization tools, and word-level audio where permitted.
- Search, bookmarks, notes, highlights, tajweed, reading plans, accessibility, widgets, and encrypted backup/restore.
- Customizable appearance and Arabic typography.
- Release packages for Windows, Linux, macOS, and Android.
- Quran reader remains separate from Qibla/prayer utilities.

## Data integrity and licensing

Every resource must have a traceable source, version, checksum, license record, and visible attribution. Public availability does not imply permission to redistribute. Quran Foundation content is not bundled; any future integration must follow its current Content Sync and offline-storage requirements.

See [data sources and licensing](docs/data-sources-and-licensing.md) and [resource pack format](docs/resource-pack-format.md).

## Documentation

- [Architecture](docs/architecture.md)
- [Data sources and licensing](docs/data-sources-and-licensing.md)
- [Resource pack format](docs/resource-pack-format.md)
- [Testing strategy](docs/testing.md)
- [Cross-platform releases](docs/releases.md)
- [Implementation status](docs/implementation-status.md)

## Software license

The application software license has not yet been selected. Do not infer a license for this repository or for third-party Quran resources from this README.
