# Testing strategy

## Manual checks

- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze`
- `flutter test`
- Resource-manifest schema validation and checksum verification when resource packs are added.
- Build each target manually on its supported operating system after generating native platform scaffolding.

## Test layers

### Unit tests
- Quran data manifest parsing and validation
- Stable surah/ayah identifiers and navigation
- Arabic variant and translation alignment
- Search tokenization and normalization
- Bookmark, note, highlight, and reading-plan behavior
- Resource installation, checksums, rollback, and backup/restore

### Widget tests
- Responsive navigation and settings
- Arabic right-to-left text layout and font scaling
- Accessible labels and keyboard interactions
- Empty, loading, offline, error, and ready states

### Integration tests
- Cold start with no network
- Open a surah and navigate to an ayah
- Search Arabic and translated text offline
- Resume reading position
- Play downloaded audio and repeat a verse range
- Export and restore local data
- Install a resource pack interrupted mid-download without corrupting an existing pack

## Quran integrity gate

Never use the app's own parsing output as the sole expected result for a data-integrity test. Keep independently sourced expected counts/checksums and record the upstream edition and version. Fail the release if data validation fails.
