# Resource pack format and first-run import

## First-run source import

The Downloads screen imports three files selected together:

1. Tanzil Quran text in **Uthmani** script, downloaded as **Text (with aya numbers)**.
2. Tanzil Quran text in **Simple** (Imla'ei) script, also downloaded as **Text (with aya numbers)**.
3. Tanzil's official `quran-data.xml` metadata file.

Official sources:

- Text downloads: https://tanzil.net/download/
- Metadata XML: https://tanzil.net/res/text/metadata/quran-data.xml
- Text license: https://tanzil.net/docs/Text_License
- Metadata documentation: https://tanzil.net/docs/Quran_Metadata

Use identical options for both text editions, including pause marks, sajdah signs, and rub-el-hizb signs. Do not edit, normalize, re-serialize, or manually correct the downloaded source files. The importer keeps the original source bytes verbatim and parses each verse string without rewriting it.

The text files must use Tanzil's numbered text format, with one record per verse:

```text
surah|ayah|verse text
```

Lines beginning with `#` and blank lines are treated as file metadata/separators. All other records must have a valid surah number, ayah number, and text. The importer checks the complete Tanzil 1.1 verse-count table and rejects duplicate, missing, or extra records.

The metadata XML supplies Arabic and transliterated surah names plus page, juz, and hizb-quarter boundaries. The app converts quarter-hizb boundaries into the displayed hizb number for navigation. Metadata counts are checked against the expected Tanzil 1.1 counts.

## Internal installed payload

The app converts the two editions into its internal JSON model for rendering while preserving each verse string exactly as decoded from its original source file. This internal representation is not a replacement source edition; the unchanged downloaded source files and attribution notice are stored alongside the installed pack under the app's local support directory.

The installed payload has the following shape:

```json
{
  "schemaVersion": 1,
  "source": {
    "name": "Tanzil Project",
    "version": "1.1",
    "url": "https://tanzil.net/download/"
  },
  "chapters": [
    {
      "number": 1,
      "nameArabic": "Arabic surah name from Tanzil metadata",
      "nameTransliteration": "Transliteration from Tanzil metadata",
      "revelationPlace": "meccan",
      "verses": [
        {
          "chapterNumber": 1,
          "verseNumber": 1,
          "textVariants": {
            "uthmani": "Exact Uthmani verse string",
            "simplified": "Exact Simple verse string"
          },
          "pageNumber": 1,
          "juzNumber": 1,
          "hizbNumber": 1
        }
      ]
    }
  ]
}
```

The text above is illustrative schema, not Quran content. The importer requires 114 surahs and 6,236 ayahs and validates verse ordering, non-empty script variants, metadata counts, source metadata, and SHA-256 integrity before activation.

The internal manifest records the source, version, retrieval date, checksum, license URL, attribution, and offline-use decision. A checksum detects accidental or malicious changes to the generated payload; it does not independently prove the authenticity of the original source.

## License and attribution

Tanzil permits use of its text in applications provided the source is clearly indicated and users can follow a link to Tanzil for updates. The text itself must not be changed. The app retains the original source files and license notice locally and displays the source/license from the reader.

Tanzil metadata has its own source notice. The app credits the Tanzil Project for both the Arabic text and structural metadata. Review the current official terms before redistributing a modified build or changing the import path.

Quran Foundation content is not part of this import. For resources covered by Quran Foundation Content Sync, use its approved synchronization mechanism and comply with its update/storage terms; do not prepackage raw content without the required permission.
