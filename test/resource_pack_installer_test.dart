import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:quran_reader/core/resource_pack_installer.dart';
import 'package:quran_reader/core/resource_pack_manifest.dart';

ResourcePackManifest manifestFor(
  List<int> bytes, {
  String version = '1.0.0',
  DateTime? retrievedAt,
}) {
  return ResourcePackManifest(
    schemaVersion: 1,
    id: 'example.translation.en',
    version: version,
    kind: QuranResourceKind.translation,
    language: 'en',
    sourceName: 'Example translation source',
    sourceUrl: Uri.parse('https://example.org/translation'),
    retrievedAt: retrievedAt ?? DateTime.utc(2026, 1, 1),
    sha256: sha256.convert(bytes).toString(),
    license: ResourceLicense(
      name: 'Test license',
      url: Uri.parse('https://example.org/license'),
      attribution: 'Test attribution',
      reviewed: true,
      offlineAllowed: true,
      bundledAllowed: false,
      redistributionAllowed: false,
      modificationAllowed: false,
    ),
  );
}

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('quran-pack-test-');
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('installs verified bytes and resolves active version', () async {
    final payload = utf8.encode('{"hello":"offline"}');
    final installer = ResourcePackInstaller(rootDirectory: root);
    final installed = await installer.install(
      manifest: manifestFor(payload),
      payloadBytes: payload,
    );

    expect(await installed.payloadFile.readAsString(), '{"hello":"offline"}');
    final active = await installer.getActive('example.translation.en');
    expect(active, isNotNull);
    expect(active!.manifest.version, '1.0.0');
    expect(await active.payloadFile.readAsBytes(), payload);
  });

  test('rejects checksum mismatch without activating the pack', () async {
    final payload = utf8.encode('{"hello":"offline"}');
    final manifest = manifestFor(payload);
    final installer = ResourcePackInstaller(rootDirectory: root);

    expect(
      () => installer.install(
        manifest: manifest,
        payloadBytes: utf8.encode('{"tampered":true}'),
      ),
      throwsA(isA<ResourcePackInstallException>()),
    );
    expect(await installer.getActive(manifest.id), isNull);
  });

  test('failed update leaves the prior version active', () async {
    final firstPayload = utf8.encode('{"version":1}');
    final secondPayload = utf8.encode('{"version":2}');
    final installer = ResourcePackInstaller(rootDirectory: root);

    await installer.install(
      manifest: manifestFor(firstPayload),
      payloadBytes: firstPayload,
    );
    await expectLater(
      installer.install(
        manifest: manifestFor(secondPayload, version: '2.0.0'),
        payloadBytes: utf8.encode('{"tampered":true}'),
      ),
      throwsA(isA<ResourcePackInstallException>()),
    );

    final active = await installer.getActive('example.translation.en');
    expect(active!.manifest.version, '1.0.0');
    expect(await active.payloadFile.readAsBytes(), firstPayload);
  });

  test('allows an identical pack to be imported again on a later date', () async {
    final payload = utf8.encode('{"hello":"offline"}');
    final installer = ResourcePackInstaller(rootDirectory: root);
    await installer.install(
      manifest: manifestFor(payload),
      payloadBytes: payload,
    );

    final repeated = await installer.install(
      manifest: manifestFor(
        payload,
        retrievedAt: DateTime.utc(2026, 10, 25),
      ),
      payloadBytes: payload,
    );
    expect(repeated.manifest.version, '1.0.0');
    final active = await installer.getActive('example.translation.en');
    expect(active!.manifest.retrievedAt, DateTime.utc(2026, 1, 1));
  });

  test('refuses to reactivate a corrupted existing version', () async {
    final payload = utf8.encode('{"hello":"offline"}');
    final installer = ResourcePackInstaller(rootDirectory: root);
    final installed = await installer.install(
      manifest: manifestFor(payload),
      payloadBytes: payload,
    );
    await installed.payloadFile.writeAsString('tampered');

    expect(
      () => installer.install(
        manifest: manifestFor(payload),
        payloadBytes: payload,
      ),
      throwsA(isA<ResourcePackInstallException>()),
    );
  });

  test('rejects path traversal in resource identifiers', () async {
    final payload = utf8.encode('{}');
    final manifest = ResourcePackManifest(
      schemaVersion: 1,
      id: '../escape',
      version: '1.0.0',
      kind: QuranResourceKind.translation,
      language: 'en',
      sourceName: 'Example',
      sourceUrl: Uri.parse('https://example.org'),
      retrievedAt: DateTime.utc(2026, 1, 1),
      sha256: sha256.convert(payload).toString(),
      license: ResourceLicense(
        name: 'Test',
        url: Uri.parse('https://example.org/license'),
        attribution: 'Test',
        reviewed: true,
        offlineAllowed: true,
        bundledAllowed: false,
        redistributionAllowed: false,
        modificationAllowed: false,
      ),
    );

    final installer = ResourcePackInstaller(rootDirectory: root);
    expect(
      () => installer.install(manifest: manifest, payloadBytes: payload),
      throwsA(isA<ResourcePackInstallException>()),
    );
  });
}
