# Cross-platform build and release strategy

Flutter platform scaffolding should be generated with the selected stable Flutter SDK, then committed to the feature branch. Do not fabricate native project files by hand.

## Targets

- **Windows:** Windows desktop build, then package as an installer and optionally a portable archive.
- **Linux:** Linux desktop build, then package as AppImage and/or a distribution-native package. Validate required system libraries on clean environments.
- **macOS:** Build the app bundle on a macOS runner; package as DMG or ZIP. Configure Developer ID signing and notarization when distribution requirements and credentials are available.
- **Android:** Build APK for direct testing and AAB for Google Play distribution. Keep signing material outside source control.

## Manual verification

No automated repository workflows are used. Run formatting, static analysis, and unit tests locally, then build each platform manually on its supported operating system. Use secure local signing configuration for release credentials. Never commit private keys, passwords, tokens, or generated personal data.

## Release checklist

- All local unit and widget tests pass.
- Quran data and all resource licenses are reviewed.
- Third-party notices and attribution are included.
- Offline smoke tests pass.
- Accessibility and Arabic rendering are checked on target devices.
- Build artifacts are versioned and checksums published.
- Signing and notarization are completed where applicable.
