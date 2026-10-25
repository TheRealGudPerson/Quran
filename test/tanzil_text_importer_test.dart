import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quran_reader/core/tanzil_text_importer.dart';

String fixtureText(String script) {
  final lines = <String>[];
  for (var chapter = 1;
      chapter <= TanzilTextImporter.verseCounts.length;
      chapter++) {
    for (var verse = 1;
        verse <= TanzilTextImporter.verseCounts[chapter - 1];
        verse++) {
      lines.add('$chapter|$verse|$script $chapter:$verse');
    }
  }
  return lines.join('\n');
}

String fixtureMetadata() {
  final chapters = <String>[];
  for (var chapter = 1; chapter <= 114; chapter++) {
    chapters.add(
      '<sura index="$chapter" name="سورة $chapter" tname="Surah $chapter" ename="Chapter $chapter" type="Meccan" rukus="1" />',
    );
  }
  return '''
<?xml version="1.0" encoding="UTF-8"?>
<quran>
  ${chapters.join('\n')}
  <page index="1" sura="1" aya="1" />
  <juz index="1" sura="1" aya="1" />
  <hizb index="1" sura="1" aya="1" />
</quran>
''';
}

void main() {
  group('TanzilTextImporter', () {
    test('preserves verse strings and combines two source editions', () {
      final importer = TanzilTextImporter();
      final prepared = importer.prepare(
        uthmaniBytes: utf8.encode(fixtureText('Uthmani fixture')),
        simpleBytes: utf8.encode(fixtureText('Simple fixture')),
        metadataBytes: utf8.encode(fixtureMetadata()),
        retrievedAt: DateTime.utc(2026, 1, 1),
      );

      expect(prepared.manifest.id, 'quran.arabic');
      expect(prepared.manifest.expectedSurahs, 114);
      expect(prepared.manifest.expectedVerses, 6236);
      expect(prepared.manifest.license.offlineAllowed, isTrue);
      expect(prepared.manifest.license.modificationAllowed, isFalse);
      expect(prepared.uthmaniSourceBytes, utf8.encode(fixtureText('Uthmani fixture')));
      expect(prepared.simpleSourceBytes, utf8.encode(fixtureText('Simple fixture')));

      final payload = jsonDecode(utf8.decode(prepared.payloadBytes))
          as Map<String, dynamic>;
      final pack = payload['chapters'] as List;
      final firstChapter = pack.first as Map<String, dynamic>;
      final firstVerse = (firstChapter['verses'] as List).first
          as Map<String, dynamic>;
      final variants = firstVerse['textVariants'] as Map<String, dynamic>;

      expect(variants['uthmani'], 'Uthmani fixture 1:1');
      expect(variants['simplified'], 'Simple fixture 1:1');
      expect(firstChapter['nameArabic'], 'سورة 1');
      expect(firstVerse['pageNumber'], 1);
      expect(firstVerse['juzNumber'], 1);
      expect(firstVerse['hizbNumber'], 1);
    });

    test('rejects a text file with missing verses', () {
      final importer = TanzilTextImporter();
      expect(
        () => importer.prepare(
          uthmaniBytes: utf8.encode('1|1|Only a fixture verse'),
          simpleBytes: utf8.encode(fixtureText('Simple fixture')),
          metadataBytes: utf8.encode(fixtureMetadata()),
        ),
        throwsA(isA<TanzilImportException>()),
      );
    });

    test('rejects duplicate verse records', () {
      final importer = TanzilTextImporter();
      final duplicate = '${fixtureText('Uthmani fixture')}\n1|1|duplicate';
      expect(
        () => importer.prepare(
          uthmaniBytes: utf8.encode(duplicate),
          simpleBytes: utf8.encode(fixtureText('Simple fixture')),
          metadataBytes: utf8.encode(fixtureMetadata()),
        ),
        throwsA(isA<TanzilImportException>()),
      );
    });
  });
}
