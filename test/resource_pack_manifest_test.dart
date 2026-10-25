import 'package:flutter_test/flutter_test.dart';
import 'package:quran_reader/core/resource_pack_manifest.dart';

Map<String, dynamic> validManifest({
  bool reviewed = true,
  bool offlineAllowed = true,
  bool bundledAllowed = false,
  String checksum = 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
}) =>
    {
      'schemaVersion': 1,
      'id': 'example.arabic.uthmani',
      'version': '1.0.0',
      'kind': 'quranText',
      'language': 'ar',
      'sourceName': 'Example source for tests',
      'sourceUrl': 'https://example.org/source',
      'retrievedAt': '2026-01-01T00:00:00Z',
      'sha256': checksum,
      'expectedSurahs': 114,
      'expectedVerses': 6236,
      'license': {
        'name': 'Test license',
        'url': 'https://example.org/license',
        'attribution': 'Example attribution',
        'reviewed': reviewed,
        'offlineAllowed': offlineAllowed,
        'bundledAllowed': bundledAllowed,
        'redistributionAllowed': false,
        'modificationAllowed': false,
      },
    };

void main() {
  group('ResourcePackManifest', () {
    test('parses and accepts reviewed offline resource metadata', () {
      final manifest = ResourcePackManifest.fromJson(validManifest());

      expect(manifest.kind, QuranResourceKind.quranText);
      expect(manifest.expectedSurahs, 114);
      expect(manifest.expectedVerses, 6236);
      expect(
        () => manifest.validateForInstall(bundledInInstaller: false),
        returnsNormally,
      );
    });

    test('rejects resources with unreviewed licenses', () {
      final manifest = ResourcePackManifest.fromJson(
        validManifest(reviewed: false),
      );

      expect(
        () => manifest.validateForInstall(bundledInInstaller: false),
        throwsA(isA<ResourcePackValidationException>()),
      );
    });

    test('rejects offline storage not permitted by the license', () {
      final manifest = ResourcePackManifest.fromJson(
        validManifest(offlineAllowed: false),
      );

      expect(
        () => manifest.validateForInstall(bundledInInstaller: false),
        throwsA(isA<ResourcePackValidationException>()),
      );
    });

    test('rejects bundling unless the license explicitly allows it', () {
      final manifest = ResourcePackManifest.fromJson(validManifest());

      expect(
        () => manifest.validateForInstall(bundledInInstaller: true),
        throwsA(isA<ResourcePackValidationException>()),
      );
    });

    test('rejects malformed checksums', () {
      final manifest = ResourcePackManifest.fromJson(
        validManifest(checksum: 'not-a-checksum'),
      );

      expect(
        () => manifest.validateForInstall(bundledInInstaller: false),
        throwsA(isA<ResourcePackValidationException>()),
      );
    });
  });
}
