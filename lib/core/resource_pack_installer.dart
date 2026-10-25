import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'quran_text_pack.dart';
import 'resource_pack_manifest.dart';

typedef ResourcePayloadValidator = void Function(
  ResourcePackManifest manifest,
  Uint8List payload,
);

class ResourcePackInstallException implements Exception {
  const ResourcePackInstallException(this.message);

  final String message;

  @override
  String toString() => 'ResourcePackInstallException: $message';
}

class InstalledResourcePack {
  const InstalledResourcePack({
    required this.manifest,
    required this.directory,
    required this.payloadFile,
  });

  final ResourcePackManifest manifest;
  final Directory directory;
  final File payloadFile;
}

/// Installs validated resources under [rootDirectory].
///
/// Each resource version is immutable once installed. A small active-pointer
/// file selects the current version, so a failed update does not delete the
/// previously active version.
class ResourcePackInstaller {
  ResourcePackInstaller({
    required this.rootDirectory,
    this.payloadValidator,
  });

  final Directory rootDirectory;
  final ResourcePayloadValidator? payloadValidator;

  Future<InstalledResourcePack> install({
    required ResourcePackManifest manifest,
    required List<int> payloadBytes,
    bool bundledInInstaller = false,
  }) async {
    manifest.validateForInstall(bundledInInstaller: bundledInInstaller);
    _validatePathSegment(manifest.id, 'resource id');
    _validatePathSegment(manifest.version, 'resource version');

    final bytes = Uint8List.fromList(payloadBytes);
    final actualHash = sha256.convert(bytes).toString();
    if (actualHash != manifest.sha256) {
      throw const ResourcePackInstallException(
        'Resource checksum does not match its manifest.',
      );
    }

    _validatePayload(manifest, bytes);

    final resourceDirectory =
        Directory('${rootDirectory.path}/packs/${manifest.id}');
    final versionDirectory =
        Directory('${resourceDirectory.path}/${manifest.version}');
    final payloadFile = File('${versionDirectory.path}/payload.json');
    final manifestFile = File('${versionDirectory.path}/manifest.json');

    await resourceDirectory.create(recursive: true);

    if (await versionDirectory.exists()) {
      if (!await payloadFile.exists() || !await manifestFile.exists()) {
        throw const ResourcePackInstallException(
          'An incomplete directory already exists for this resource version.',
        );
      }
      final installedManifest = ResourcePackManifest.decode(
        await manifestFile.readAsString(),
      );
      final existingBytes = await payloadFile.readAsBytes();
      if (sha256.convert(existingBytes).toString() != manifest.sha256 ||
          !_bytesEqual(existingBytes, bytes)) {
        throw const ResourcePackInstallException(
          'The existing resource version payload is corrupt or differs from the requested payload.',
        );
      }
      final installedMetadata = _manifestToJson(installedManifest)
        ..remove('retrievedAt');
      final requestedMetadata = _manifestToJson(manifest)..remove('retrievedAt');
      if (jsonEncode(installedMetadata) != jsonEncode(requestedMetadata)) {
        throw const ResourcePackInstallException(
          'A different payload or manifest is already installed with this version number.',
        );
      }
    } else {
      final stagingDirectory = Directory(
        '${resourceDirectory.path}/.staging-${DateTime.now().microsecondsSinceEpoch}',
      );
      try {
        await stagingDirectory.create();
        await File('${stagingDirectory.path}/payload.json').writeAsBytes(
          bytes,
          flush: true,
        );
        await File('${stagingDirectory.path}/manifest.json').writeAsString(
          jsonEncode(_manifestToJson(manifest)),
          flush: true,
        );
        await stagingDirectory.rename(versionDirectory.path);
      } on FileSystemException {
        if (await stagingDirectory.exists()) {
          await stagingDirectory.delete(recursive: true);
        }
        rethrow;
      } catch (_) {
        if (await stagingDirectory.exists()) {
          await stagingDirectory.delete(recursive: true);
        }
        rethrow;
      }
    }

    await _activate(resourceDirectory, manifest.version);
    return InstalledResourcePack(
      manifest: manifest,
      directory: versionDirectory,
      payloadFile: payloadFile,
    );
  }

  Future<InstalledResourcePack?> getActive(String resourceId) async {
    _validatePathSegment(resourceId, 'resource id');
    final resourceDirectory =
        Directory('${rootDirectory.path}/packs/$resourceId');
    final pointer = File('${resourceDirectory.path}/active.json');
    final backupPointer = File('${resourceDirectory.path}/.active-backup.tmp');
    if (!await pointer.exists() && await backupPointer.exists()) {
      // Recover if the process stopped between moving the old pointer aside
      // and activating the new one.
      await backupPointer.rename(pointer.path);
    } else if (await pointer.exists() && await backupPointer.exists()) {
      // A valid pointer already exists; discard a leftover backup from a
      // process that stopped after activating the new version.
      await backupPointer.delete();
    }
    if (!await pointer.exists()) return null;

    final decoded = jsonDecode(await pointer.readAsString());
    if (decoded is! Map<String, dynamic> || decoded['version'] is! String) {
      throw const ResourcePackInstallException(
        'Active resource pointer is malformed.',
      );
    }
    final version = decoded['version'] as String;
    _validatePathSegment(version, 'resource version');

    final versionDirectory = Directory('${resourceDirectory.path}/$version');
    final manifestFile = File('${versionDirectory.path}/manifest.json');
    final payloadFile = File('${versionDirectory.path}/payload.json');
    if (!await manifestFile.exists() || !await payloadFile.exists()) {
      throw const ResourcePackInstallException(
        'Active resource version is incomplete.',
      );
    }

    final manifest = ResourcePackManifest.decode(
      await manifestFile.readAsString(),
    );
    manifest.validateForInstall(bundledInInstaller: false);
    final bytes = await payloadFile.readAsBytes();
    if (sha256.convert(bytes).toString() != manifest.sha256) {
      throw const ResourcePackInstallException(
        'Installed resource checksum verification failed.',
      );
    }
    _validatePayload(manifest, bytes);
    return InstalledResourcePack(
      manifest: manifest,
      directory: versionDirectory,
      payloadFile: payloadFile,
    );
  }

  void _validatePayload(ResourcePackManifest manifest, Uint8List bytes) {
    payloadValidator?.call(manifest, bytes);
    if (manifest.kind != QuranResourceKind.quranText) return;
    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const QuranTextPackValidationException(
          'Quran text payload root must be a JSON object.',
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
          'Payload source metadata does not match its resource manifest.',
        );
      }
    } on FormatException catch (error) {
      throw ResourcePackInstallException(
        'Resource payload is not valid UTF-8 JSON: ${error.message}',
      );
    } on QuranTextPackValidationException catch (error) {
      throw ResourcePackInstallException(
        'Quran text payload validation failed: ${error.message}',
      );
    }
  }

  Future<void> _activate(Directory resourceDirectory, String version) async {
    final activeFile = File('${resourceDirectory.path}/active.json');
    final temporaryFile = File(
      '${resourceDirectory.path}/.active-${DateTime.now().microsecondsSinceEpoch}.tmp',
    );
    final backupFile = File('${resourceDirectory.path}/.active-backup.tmp');

    if (!await activeFile.exists() && await backupFile.exists()) {
      await backupFile.rename(activeFile.path);
    } else if (await activeFile.exists() && await backupFile.exists()) {
      await backupFile.delete();
    }

    await temporaryFile.writeAsString(
      jsonEncode({'version': version}),
      flush: true,
    );

    final hadActive = await activeFile.exists();
    if (await backupFile.exists()) await backupFile.delete();
    if (hadActive) await activeFile.rename(backupFile.path);

    try {
      await temporaryFile.rename(activeFile.path);
      if (await backupFile.exists()) await backupFile.delete();
    } catch (_) {
      if (await activeFile.exists()) await activeFile.delete();
      if (await backupFile.exists()) await backupFile.rename(activeFile.path);
      rethrow;
    } finally {
      if (await temporaryFile.exists()) await temporaryFile.delete();
    }
  }

  bool _bytesEqual(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  void _validatePathSegment(String value, String label) {
    if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9._-]{0,127}$').hasMatch(value) ||
        value == '.' ||
        value == '..') {
      throw ResourcePackInstallException(
        'Invalid $label: only letters, digits, dot, underscore, and hyphen are allowed.',
      );
    }
  }

  Map<String, Object?> _manifestToJson(ResourcePackManifest manifest) => {
        'schemaVersion': manifest.schemaVersion,
        'id': manifest.id,
        'version': manifest.version,
        'kind': manifest.kind.name,
        'language': manifest.language,
        'sourceName': manifest.sourceName,
        'sourceUrl': manifest.sourceUrl.toString(),
        'retrievedAt': manifest.retrievedAt.toUtc().toIso8601String(),
        'sha256': manifest.sha256,
        'expectedSurahs': manifest.expectedSurahs,
        'expectedVerses': manifest.expectedVerses,
        'license': {
          'name': manifest.license.name,
          'url': manifest.license.url.toString(),
          'attribution': manifest.license.attribution,
          'reviewed': manifest.license.reviewed,
          'offlineAllowed': manifest.license.offlineAllowed,
          'bundledAllowed': manifest.license.bundledAllowed,
          'redistributionAllowed': manifest.license.redistributionAllowed,
          'modificationAllowed': manifest.license.modificationAllowed,
        },
      };
}
