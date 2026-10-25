# Resource manifests

This directory contains resource metadata, not Quran text or audio payloads.

A resource manifest must include:
- Schema version, stable resource ID, and upstream version
- Resource kind and language
- Canonical source URL and retrieval date
- SHA-256 checksum of the exact resource payload
- Expected surah/verse counts for Quran text resources
- License name and URL, required attribution, and explicit reviewed/offline/bundled/redistribution/modification flags

The app refuses to install a manifest whose license is not marked reviewed, whose required attribution is missing, whose checksum is malformed, or whose declared rights do not permit the requested storage mode.

The metadata flags are not a substitute for legal review. In particular, do not mark `reviewed: true` merely because a resource is publicly accessible. A future pack installer must verify the payload checksum independently before activating a pack.

For Quran Foundation resources available through Content Sync, the installer/sync engine must use the approved Content Sync mechanism and honor its update and storage requirements. Do not package raw QF content into installers without the required separate written license.
