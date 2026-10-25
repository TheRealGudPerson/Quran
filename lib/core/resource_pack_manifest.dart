import 'dart:convert';

enum QuranResourceKind {
  quranText,
  translation,
  transliteration,
  tafsir,
  recitation,
  tajweed,
  font,
}

class ResourcePackValidationException implements Exception {
  const ResourcePackValidationException(this.message);

  final String message;

  @override
  String toString() => 'ResourcePackValidationException: $message';
}

class ResourceLicense {
  const ResourceLicense({
    required this.name,
    required this.url,
    required this.attribution,
    required this.reviewed,
    required this.offlineAllowed,
    required this.bundledAllowed,
    required this.redistributionAllowed,
    required this.modificationAllowed,
  });

  final String name;
  final Uri url;
  final String attribution;
  final bool reviewed;
  final bool offlineAllowed;
  final bool bundledAllowed;
  final bool redistributionAllowed;
  final bool modificationAllowed;

  factory ResourceLicense.fromJson(Map<String, dynamic> json) {
    final rawUrl = json['url'];
    final uri = rawUrl is String ? Uri.tryParse(rawUrl) : null;
    if (uri == null || !uri.hasScheme || !{'https', 'http'}.contains(uri.scheme)) {
      throw const ResourcePackValidationException(
        'License URL must be an absolute HTTP(S) URL.',
      );
    }

    return ResourceLicense(
      name: _requiredString(json, 'name'),
      url: uri,
      attribution: _requiredString(json, 'attribution'),
      reviewed: _requiredBool(json, 'reviewed'),
      offlineAllowed: _requiredBool(json, 'offlineAllowed'),
      bundledAllowed: _requiredBool(json, 'bundledAllowed'),
      redistributionAllowed: _requiredBool(json, 'redistributionAllowed'),
      modificationAllowed: _requiredBool(json, 'modificationAllowed'),
    );
  }
}

class ResourcePackManifest {
  const ResourcePackManifest({
    required this.schemaVersion,
    required this.id,
    required this.version,
    required this.kind,
    required this.language,
    required this.sourceName,
    required this.sourceUrl,
    required this.retrievedAt,
    required this.sha256,
    required this.license,
    this.expectedSurahs,
    this.expectedVerses,
  });

  final int schemaVersion;
  final String id;
  final String version;
  final QuranResourceKind kind;
  final String language;
  final String sourceName;
  final Uri sourceUrl;
  final DateTime retrievedAt;
  final String sha256;
  final ResourceLicense license;
  final int? expectedSurahs;
  final int? expectedVerses;

  factory ResourcePackManifest.fromJson(Map<String, dynamic> json) {
    final rawSourceUrl = json['sourceUrl'];
    final sourceUri =
        rawSourceUrl is String ? Uri.tryParse(rawSourceUrl) : null;
    if (sourceUri == null ||
        !sourceUri.hasScheme ||
        !{'https', 'http'}.contains(sourceUri.scheme)) {
      throw const ResourcePackValidationException(
        'sourceUrl must be an absolute HTTP(S) URL.',
      );
    }

    final rawKind = _requiredString(json, 'kind');
    final kind = QuranResourceKind.values.where(
      (value) => value.name == rawKind,
    );
    if (kind.isEmpty) {
      throw ResourcePackValidationException('Unsupported resource kind: $rawKind.');
    }

    final rawDate = _requiredString(json, 'retrievedAt');
    final date = DateTime.tryParse(rawDate);
    if (date == null) {
      throw const ResourcePackValidationException(
        'retrievedAt must be an ISO-8601 date or timestamp.',
      );
    }

    final rawLicense = json['license'];
    if (rawLicense is! Map<String, dynamic>) {
      throw const ResourcePackValidationException(
        'license must be a JSON object.',
      );
    }

    return ResourcePackManifest(
      schemaVersion: _requiredInt(json, 'schemaVersion'),
      id: _requiredString(json, 'id'),
      version: _requiredString(json, 'version'),
      kind: kind.first,
      language: _requiredString(json, 'language'),
      sourceName: _requiredString(json, 'sourceName'),
      sourceUrl: sourceUri,
      retrievedAt: date,
      sha256: _requiredString(json, 'sha256').toLowerCase(),
      license: ResourceLicense.fromJson(rawLicense),
      expectedSurahs: _optionalInt(json, 'expectedSurahs'),
      expectedVerses: _optionalInt(json, 'expectedVerses'),
    );
  }

  factory ResourcePackManifest.decode(String source) {
    final decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const ResourcePackValidationException(
        'Manifest root must be a JSON object.',
      );
    }
    return ResourcePackManifest.fromJson(decoded);
  }

  /// Checks metadata and declared rights before installation.
  ///
  /// This does not verify the file checksum itself; the installer must hash the
  /// downloaded bytes and compare the result to [sha256] before activation.
  void validateForInstall({required bool bundledInInstaller}) {
    if (schemaVersion != 1) {
      throw ResourcePackValidationException(
        'Unsupported manifest schema version: $schemaVersion.',
      );
    }
    if (id.trim().isEmpty || version.trim().isEmpty) {
      throw const ResourcePackValidationException(
        'Resource id and version must not be empty.',
      );
    }
    if (language.trim().isEmpty || sourceName.trim().isEmpty) {
      throw const ResourcePackValidationException(
        'Language and source name must not be empty.',
      );
    }
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(sha256)) {
      throw const ResourcePackValidationException(
        'sha256 must contain exactly 64 hexadecimal characters.',
      );
    }
    if (kind == QuranResourceKind.quranText &&
        (expectedSurahs == null || expectedVerses == null)) {
      throw const ResourcePackValidationException(
        'Quran text manifests must declare expectedSurahs and expectedVerses.',
      );
    }
    if ((expectedSurahs != null && expectedSurahs! <= 0) ||
        (expectedVerses != null && expectedVerses! <= 0)) {
      throw const ResourcePackValidationException(
        'Expected surah and verse counts must be positive.',
      );
    }
    if (!license.reviewed) {
      throw const ResourcePackValidationException(
        'Resource license has not been reviewed.',
      );
    }
    if (license.name.trim().isEmpty || license.attribution.trim().isEmpty) {
      throw const ResourcePackValidationException(
        'License name and attribution are required.',
      );
    }
    if (!license.offlineAllowed) {
      throw const ResourcePackValidationException(
        'This resource is not licensed for offline storage.',
      );
    }
    if (bundledInInstaller && !license.bundledAllowed) {
      throw const ResourcePackValidationException(
        'This resource is not licensed to be bundled in the installer.',
      );
    }
  }
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw ResourcePackValidationException('$key must be a non-empty string.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw ResourcePackValidationException('$key must be an integer.');
  }
  return value;
}

int? _optionalInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! int) {
    throw ResourcePackValidationException('$key must be an integer when provided.');
  }
  return value;
}

bool _requiredBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! bool) {
    throw ResourcePackValidationException('$key must be a boolean.');
  }
  return value;
}
