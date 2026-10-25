import 'package:flutter_test/flutter_test.dart';
import 'package:quran_reader/core/quran_catalog.dart';

void main() {
  group('QuranCatalog.validate', () {
    test('rejects a catalog with the wrong number of surahs', () {
      const catalog = QuranCatalog(
        surahs: [
          SurahMetadata(number: 1, name: 'Example', verseCount: 7),
        ],
      );

      expect(catalog.validate, throwsA(isA<QuranCatalogValidationException>()));
    });

    test('rejects non-sequential surah numbers', () {
      const catalog = QuranCatalog(
        expectedSurahCount: 2,
        expectedVerseCount: 3,
        surahs: [
          SurahMetadata(number: 1, name: 'First', verseCount: 1),
          SurahMetadata(number: 3, name: 'Second', verseCount: 2),
        ],
      );

      expect(catalog.validate, throwsA(isA<QuranCatalogValidationException>()));
    });

    test('rejects empty names and non-positive verse counts', () {
      const emptyName = QuranCatalog(
        expectedSurahCount: 1,
        expectedVerseCount: 1,
        surahs: [SurahMetadata(number: 1, name: ' ', verseCount: 1)],
      );
      const invalidCount = QuranCatalog(
        expectedSurahCount: 1,
        expectedVerseCount: 0,
        surahs: [SurahMetadata(number: 1, name: 'Example', verseCount: 0)],
      );

      expect(emptyName.validate,
          throwsA(isA<QuranCatalogValidationException>()));
      expect(invalidCount.validate,
          throwsA(isA<QuranCatalogValidationException>()));
    });

    test('accepts a small fixture when its expected counts are explicit', () {
      const catalog = QuranCatalog(
        expectedSurahCount: 2,
        expectedVerseCount: 3,
        surahs: [
          SurahMetadata(number: 1, name: 'Fixture one', verseCount: 1),
          SurahMetadata(number: 2, name: 'Fixture two', verseCount: 2),
        ],
      );

      expect(catalog.validate, returnsNormally);
      expect(catalog.totalVerses, 3);
    });
  });
}
