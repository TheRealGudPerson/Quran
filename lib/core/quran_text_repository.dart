import 'dart:convert';

import 'resource_pack_installer.dart';
import 'quran_text_pack.dart';

/// Loads the currently active, integrity-checked Quran text resource.
class QuranTextRepository {
  QuranTextRepository({
    required this.installer,
    this.resourceId = 'quran.arabic',
  });

  final ResourcePackInstaller installer;
  final String resourceId;

  Future<QuranTextPack?> loadActivePack() async {
    final installed = await installer.getActive(resourceId);
    if (installed == null) return null;

    final decoded = jsonDecode(await installed.payloadFile.readAsString());
    if (decoded is! Map<String, dynamic>) {
      throw const QuranTextPackValidationException(
        'Installed Quran payload root must be a JSON object.',
      );
    }

    final manifest = installed.manifest;
    if (manifest.expectedSurahs == null || manifest.expectedVerses == null) {
      throw const QuranTextPackValidationException(
        'Installed Quran manifest is missing expected surah or verse counts.',
      );
    }

    final pack = QuranTextPack.fromJson(
      decoded,
      expectedChapterCount: manifest.expectedSurahs!,
      expectedVerseCount: manifest.expectedVerses!,
    );
    if (pack.sourceName != manifest.sourceName ||
        pack.sourceUrl != manifest.sourceUrl) {
      throw const QuranTextPackValidationException(
        'Installed Quran source metadata does not match its manifest.',
      );
    }
    return pack;
  }
}
