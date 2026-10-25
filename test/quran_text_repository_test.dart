import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_reader/core/quran_text_repository.dart';
import 'package:quran_reader/core/resource_pack_installer.dart';
import 'package:quran_reader/core/resource_pack_manifest.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('quran-repository-test-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('returns null when no Quran text pack is active', () async {
    final repository = QuranTextRepository(
      installer: ResourcePackInstaller(rootDirectory: root),
    );

    expect(await repository.loadActivePack(), isNull);
  });

  test('loads a verified active pack and exposes verse text', () async {
    final payload = utf8.encode(jsonEncode({
      'schemaVersion': 1,
      'source': {
        'name': 'Fixture source',
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
                'uthmani': 'Fixture Arabic',
                'simplified': 'Fixture Arabic',
              },
              'translations': {'en.fixture': 'Fixture translation'},
              'transliteration': 'fixture',
            },
          ],
        },
      ],
    }));
    final manifest = ResourcePackManifest(
      schemaVersion: 1,
      id: 'quran.arabic',
      version: 'test-1',
      kind: QuranResourceKind.quranText,
      language: 'ar',
      sourceName: 'Fixture source',
      sourceUrl: Uri.parse('https://example.org/quran'),
      retrievedAt: DateTime.utc(2026, 1, 1),
      sha256: sha256.convert(payload).toString(),
      expectedSurahs: 1,
      expectedVerses: 1,
      license: ResourceLicense(
        name: 'Test license',
        url: Uri.parse('https://example.org/license'),
        attribution: 'Fixture attribution',
        reviewed: true,
        offlineAllowed: true,
        bundledAllowed: false,
        redistributionAllowed: false,
        modificationAllowed: false,
      ),
    );
    final installer = ResourcePackInstaller(rootDirectory: root);
    await installer.install(manifest: manifest, payloadBytes: payload);

    final repository = QuranTextRepository(installer: installer);
    final pack = await repository.loadActivePack();

    expect(pack, isNotNull);
    expect(pack!.chapters.single.nameTransliteration, 'Ikhtibar');
    expect(pack.verseAt(1, 1)?.textFor('uthmani'), 'Fixture Arabic');
    expect(
      pack.verseAt(1, 1)?.translations['en.fixture'],
      'Fixture translation',
    );
  });
}
