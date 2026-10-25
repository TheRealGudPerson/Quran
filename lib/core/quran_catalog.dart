/// Metadata used to validate an installed Quran text pack.
///
/// This class deliberately does not contain Quran text. Resource packs must be
/// independently sourced, licensed, and verified before they are installed.
class SurahMetadata {
  const SurahMetadata({
    required this.number,
    required this.name,
    required this.verseCount,
  });

  final int number;
  final String name;
  final int verseCount;
}

class QuranCatalogValidationException implements Exception {
  const QuranCatalogValidationException(this.message);

  final String message;

  @override
  String toString() => 'QuranCatalogValidationException: $message';
}

class QuranCatalog {
  const QuranCatalog({
    required this.surahs,
    this.expectedSurahCount = 114,
    this.expectedVerseCount = 6236,
  });

  final List<SurahMetadata> surahs;
  final int expectedSurahCount;
  final int expectedVerseCount;

  int get totalVerses =>
      surahs.fold<int>(0, (total, surah) => total + surah.verseCount);

  /// Validates basic catalog integrity for the selected verse-count convention.
  ///
  /// The expected total must match the edition documented by the resource pack.
  /// Do not use this as a substitute for checking the pack against its upstream
  /// source and checksum.
  void validate() {
    if (surahs.length != expectedSurahCount) {
      throw QuranCatalogValidationException(
        'Expected $expectedSurahCount surahs, found ${surahs.length}.',
      );
    }

    for (var index = 0; index < surahs.length; index++) {
      final surah = surahs[index];
      final expectedNumber = index + 1;
      if (surah.number != expectedNumber) {
        throw QuranCatalogValidationException(
          'Surah at position $expectedNumber has number ${surah.number}.',
        );
      }
      if (surah.name.trim().isEmpty) {
        throw QuranCatalogValidationException(
          'Surah $expectedNumber has an empty display name.',
        );
      }
      if (surah.verseCount <= 0) {
        throw QuranCatalogValidationException(
          'Surah $expectedNumber has an invalid verse count.',
        );
      }
    }

    if (totalVerses != expectedVerseCount) {
      throw QuranCatalogValidationException(
        'Expected $expectedVerseCount verses for the selected convention, '
        'found $totalVerses.',
      );
    }
  }
}
