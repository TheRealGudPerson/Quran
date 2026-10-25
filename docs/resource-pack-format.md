# Resource pack format

The first importer accepts two UTF-8 JSON files selected together:

1. A resource manifest describing provenance, checksum, and license review.
2. A Quran text payload whose exact bytes match the manifest's SHA-256 checksum.

The primary Quran text resource must use ID `quran.arabic` and kind `quranText`. Do not edit or re-serialize a licensed payload after calculating its checksum.

## Manifest shape

```json
{
  "schemaVersion": 1,
  "id": "quran.arabic",
  "version": "source-version",
  "kind": "quranText",
  "language": "ar",
  "sourceName": "Replace with the actual source",
  "sourceUrl": "https://example.org/source",
  "retrievedAt": "2026-01-01T00:00:00Z",
  "sha256": "REPLACE_WITH_64_HEX_CHARACTERS",
  "expectedSurahs": 114,
  "expectedVerses": 6236,
  "license": {
    "name": "Replace with the actual license",
    "url": "https://example.org/license",
    "attribution": "Replace with the exact required attribution",
    "reviewed": false,
    "offlineAllowed": false,
    "bundledAllowed": false,
    "redistributionAllowed": false,
    "modificationAllowed": false
  }
}
```

This is a template, not an approved manifest. The placeholder checksum is invalid, and the conservative license flags intentionally cause installation to fail until a person has reviewed the actual source terms and recorded accurate values. Do not simply flip these flags to bypass validation.

## Quran text payload shape

```json
{
  "schemaVersion": 1,
  "source": {
    "name": "Replace with the actual source",
    "version": "source-version",
    "url": "https://example.org/source"
  },
  "chapters": [
    {
      "number": 1,
      "nameArabic": "Fixture chapter name",
      "nameTransliteration": "Fixture",
      "revelationPlace": "meccan",
      "verses": [
        {
          "chapterNumber": 1,
          "verseNumber": 1,
          "textVariants": {
            "uthmani": "Fixture Arabic text",
            "simplified": "Fixture Arabic text"
          },
          "transliteration": "Fixture transliteration",
          "translations": {
            "en.example": "Fixture translation"
          },
          "tafsir": {},
          "pageNumber": 1,
          "juzNumber": 1,
          "hizbNumber": 1
        }
      ]
    }
  ]
}
```

The fixture strings above are examples, not Quran content. Production text packs must contain all required chapters and verses in sequential order, include non-empty Uthmani and simplified variants for each verse, and use the independently verified expected counts for the selected edition. The payload's `source.name` and `source.url` must match the manifest's `sourceName` and `sourceUrl`.

## Integrity and rights

- The checksum is SHA-256 over the exact payload file bytes, not over parsed JSON or reformatted JSON.
- The importer validates chapter/verse ordering, script variants, source metadata, and declared counts before activating a Quran pack.
- The installer retains previous versions and changes the active pointer only after the new version has passed validation.
- A manifest's license flags are metadata, not legal proof. Public availability does not grant offline storage or redistribution rights.
- Do not package Quran Foundation content as raw data unless its current terms explicitly permit it. Where Content Sync is required, use that approved mechanism rather than this generic file importer.
