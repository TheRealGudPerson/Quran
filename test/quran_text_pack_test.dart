import 'package:flutter_test/flutter_test.dart';
import 'package:quran_reader/core/quran_text_pack.dart';

Map<String, dynamic> validPack() => {
      'schemaVersion': 1,
      'source': {
        'name': 'Fixture only',
        'version': 'test-1',
        'url': 'https://example.org/quran',
      },
      'chapters': [
        {
          'number': 1,
          'nameArabic': 'اختبار',
          'nameTransliteration': 'Ikhtibar',
          'verses': [
            {
              'chapterNumber': 1,
              'verseNumber': 1,
              'textVariants': {
                'uthmani': 'Fixture Arabic one',
                'simplified': 'Fixture Arabic one',
              },
              'translations': {'en.example': 'Fixture translation one'},
              'transliteration': 'fixture one',
            },
          ],
        },
        {
          'number': 2,
          'nameArabic': 'مثال',
          'nameTransliteration': 'Mithal',
          'verses': [
            {
              'chapterNumber': 2,
              'verseNumber': 1,
              'textVariants': {
                'uthmani': 'Fixture Arabic two',
                'simplified': 'Fixture Arabic two',
              },
            },
            {
              'chapterNumber': 2,
              'verseNumber': 2,
              'textVariants': {
                'uthmani': 'Fixture Arabic three',
                'simplified': 'Fixture Arabic three',
              },
            },
          ],
        },
      ],
    };

void main() {
  group('QuranTextPack', () {
    test('parses variants, translations, and stable verse identifiers', () {
      final pack = QuranTextPack.fromJson(
        validPack(),
        expectedChapterCount: 2,
        expectedVerseCount: 3,
      );

      expect(pack.sourceName, 'Fixture only');
      expect(pack.totalVerses, 3);
      expect(pack.verseAt(1, 1)?.id, '1:1');
      expect(pack.verseAt(1, 1)?.translations['en.example'], 'Fixture translation one');
      expect(pack.verseAt(2, 2)?.textFor('uthmani'), 'Fixture Arabic three');
      expect(pack.verseAt(3, 1), isNull);
    });

    test('rejects chapters with incorrect numbering', () {
      final json = validPack();
      (json['chapters'] as List)[1]['number'] = 4;

      expect(
        () => QuranTextPack.fromJson(
          json,
          expectedChapterCount: 2,
          expectedVerseCount: 3,
        ),
        throwsA(isA<QuranTextPackValidationException>()),
      );
    });

    test('rejects a missing required Arabic script variant', () {
      final json = validPack();
      final firstVerse =
          ((json['chapters'] as List).first as Map<String, dynamic>)['verses'] as List;
      (firstVerse.first as Map<String, dynamic>)['textVariants'] = {
        'uthmani': 'Fixture Arabic one',
      };

      expect(
        () => QuranTextPack.fromJson(
          json,
          expectedChapterCount: 2,
          expectedVerseCount: 3,
        ),
        throwsA(isA<QuranTextPackValidationException>()),
      );
    });

    test('rejects incorrect verse counts', () {
      expect(
        () => QuranTextPack.fromJson(
          validPack(),
          expectedChapterCount: 2,
          expectedVerseCount: 6236,
        ),
        throwsA(isA<QuranTextPackValidationException>()),
      );
    });
  });
}
