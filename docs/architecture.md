# Architecture

## Principles

- Flutter and Dart are the shared application stack for Windows, Linux, macOS, and Android.
- Offline-first: reading and user-created data must not require a network connection after resources have been installed.
- Local-only personal data: no account or cloud sync is required. Cross-device transfer is through an explicit export/import workflow.
- Quran text is immutable source data. Rendering options must not rewrite the source text.
- Every downloadable or bundled resource has a manifest entry, source, version, checksum, attribution, and license review status.
- Keep platform-specific APIs behind small service interfaces. Widgets should not contain storage, network, or audio business logic.

## Proposed layers

1. **Presentation**: responsive Flutter pages, accessible controls, reader typography, theme and navigation.
2. **Domain**: stable surah/ayah identifiers, reading positions, search queries, bookmarks, notes, playback state, and resource-pack metadata.
3. **Data**: repositories for Quran text, translations, tafsir, audio manifests, local user data, and resource-pack installation.
4. **Platform services**: file system, secure key storage, audio session behavior, notifications, home-screen widgets, and desktop integrations.

## Persistence

Use a transactional local database for structured content and user state. Store large audio assets and resource packs as files, with a database manifest that tracks versions, checksums, installation state, and storage usage. Never commit user backups, downloaded resources, signing keys, or personal notes.

## Resource packs

A pack should have a versioned manifest and integrity checksum. Installation must be atomic: download to a temporary location, verify the checksum and schema, run data validation, then activate it. Failed installs must leave the previous valid pack usable. The reader should clearly distinguish unavailable resources from empty content.

## Arabic text

Preserve source Unicode code points and diacritics. Uthmani and simplified representations are separate source variants, not a lossy runtime transformation. Test right-to-left layout, combining marks, ligatures, font fallback, line breaks, selection, and accessibility text on every platform.

## Qibla and prayer utilities

Keep the Quran reader as a separate app. Reusable Islamic utility components may live in a separately designed package later, but this app must not depend on the Qibla application to read or search the Quran.
