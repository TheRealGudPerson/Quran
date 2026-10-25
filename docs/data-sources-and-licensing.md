# Data sources and licensing

This document is a release gate, not a claim that any resource has already been approved for redistribution.

## Candidate sources

### Arabic Quran text: Tanzil

- Project: https://tanzil.net/
- Text license: https://tanzil.net/docs/Text_License
- Candidate use: versioned Arabic text after reviewing current terms, preserving required attribution, and validating the downloaded edition.
- Rule: do not modify the source text. Any alternate script representation must have its own documented source and validation.

### Quran Foundation / Quran.com APIs

- API documentation: https://api-docs.quran.com/docs/api-reference/
- Content sync documentation: https://api-docs.quran.com/docs/tutorials/content-sync/getting-started/
- Candidate use: discover available translations, tafsir, recitations, word-level data, and supported offline synchronization.
- Current developer terms: https://api-docs.quran.com/legal/developer-terms/
- Rule: QF content may be displayed inside the application under its terms, but raw QF content must not be redistributed as a separate dataset or content package without the required written license.
- Rule: if a resource is available through Content Sync, use Content Sync as the only permitted way to obtain and maintain its offline copy. Sync at least every 7 days when connectivity permits, apply available changes, and sync promptly after connectivity returns.
- Rule: Content Sync's storage exception does not itself permit prepackaging a QF content database in the installer. Offline support must be implemented in accordance with the current terms.

## Required metadata per resource

Every resource must record:
- Stable resource ID and display name
- Content type and language
- Author, translator, reciter, or publisher where applicable
- Canonical source URL and retrieval date
- Upstream version or revision
- License name and URL, plus a human-reviewed redistribution decision
- Required attribution text
- Checksum and expected schema
- Whether offline download, bundling, modification, and commercial distribution are permitted

## Release policy

- Do not bundle a resource until its license and attribution have been reviewed.
- Do not treat public-domain status of the underlying work as proof that a particular digital edition or recording can be redistributed.
- Do not transform or silently normalize canonical Quran text.
- Keep attribution visible in-app and include third-party notices in each release.
- If a source requires a designated synchronization or download mechanism, use that mechanism and obey its terms.
- Store source data separately from application code so datasets can be updated and audited independently.

## Verification

Before a text pack is accepted, validate the expected 114 surahs, verse ordering, source-specific verse counts and numbering conventions, uniqueness of stable identifiers, and consistency between every Arabic variant and its metadata. The reference edition and counting convention must be stated explicitly; tests must not assume every edition represents verse boundaries identically.
