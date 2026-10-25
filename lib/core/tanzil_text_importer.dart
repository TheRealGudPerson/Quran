import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:xml/xml.dart';

import 'quran_text_pack.dart';
import 'resource_pack_manifest.dart';

/// Prepares the official Tanzil Uthmani and Simple editions without modifying
/// the verse strings. Original source bytes are returned for verbatim storage.
class TanzilPreparedPack {
  const TanzilPreparedPack({
    required this.manifest,
    required this.payloadBytes,
    required this.uthmaniSourceBytes,
    required this.simpleSourceBytes,
    required this.metadataSourceBytes,
    required this.licenseNoticeBytes,
  });

  final ResourcePackManifest manifest;
  final Uint8List payloadBytes;
  final Uint8List uthmaniSourceBytes;
  final Uint8List simpleSourceBytes;
  final Uint8List metadataSourceBytes;
  final Uint8List licenseNoticeBytes;
}

class TanzilImportException implements Exception {
  const TanzilImportException(this.message);

  final String message;

  @override
  String toString() => 'TanzilImportException: $message';
}

class TanzilTextImporter {
  static const sourceName = 'Tanzil Project';
  static const sourceVersion = '1.1';
  static final sourceUrl = Uri.parse('https://tanzil.net/download/');
  static final licenseUrl = Uri.parse('https://tanzil.net/docs/Text_License');
  static final metadataUrl =
      Uri.parse('https://tanzil.net/res/text/metadata/quran-data.xml');

  static const licenseName = 'Creative Commons Attribution 3.0 (CC BY 3.0)';
  static const attribution = '''
Tanzil Quran Text
Copyright (C) 2007-2021 Tanzil Project
License: Creative Commons Attribution 3.0

This copy of the Quran text is carefully produced, highly verified and continuously monitored by a group of specialists in Tanzil Project.

TERMS OF USE:
- Permission is granted to copy and distribute verbatim copies of this text, but CHANGING THE TEXT IS NOT ALLOWED.
- This Quran text can be used in any website or application, provided that its source (Tanzil Project) is clearly indicated, and a link is made to tanzil.net to enable users to keep track of changes.

Updates: https://tanzil.net/updates/
''';

  /// Per-surah verse counts for the Tanzil version 1.1 Hafs text.
  static const verseCounts = <int>[
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52,
    99, 128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69,
    60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35,
    38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11,
    18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42,
    29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8,
    8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6,
  ];

  static const _tanzilTextCopyright = attribution;

  TanzilPreparedPack prepare({
    required List<int> uthmaniBytes,
    required List<int> simpleBytes,
    required List<int> metadataBytes,
    DateTime? retrievedAt,
  }) {
    final uthmaniSource = Uint8List.fromList(uthmaniBytes);
    final simpleSource = Uint8List.fromList(simpleBytes);
    final metadataSource = Uint8List.fromList(metadataBytes);

    late final Map<String, dynamic> metadata;
    try {
      metadata = _parseMetadata(utf8.decode(metadataSource, allowMalformed: false));
    } on FormatException catch (error) {
      throw TanzilImportException('Metadata file is not valid UTF-8/XML: ${error.message}');
    }

    final uthmani = _parseText(
      utf8.decode(uthmaniSource, allowMalformed: false),
      'Uthmani',
    );
    final simple = _parseText(
      utf8.decode(simpleSource, allowMalformed: false),
      'Simple',
    );

    final chaptersMetadata = metadata['chapters'] as List<_ChapterMetadata>;
    final pages = metadata['pages'] as List<_Boundary>;
    final juzs = metadata['juzs'] as List<_Boundary>;
    final hizbs = metadata['hizbs'] as List<_Boundary>;

    final chapters = <Map<String, Object?>>[];
    for (var chapterIndex = 0; chapterIndex < verseCounts.length; chapterIndex++) {
      final chapterNumber = chapterIndex + 1;
      final chapterMetadata = chaptersMetadata[chapterIndex];
      final verses = <Map<String, Object?>>[];
      for (var verseNumber = 1;
          verseNumber <= verseCounts[chapterIndex];
          verseNumber++) {
        final key = '$chapterNumber:$verseNumber';
        final uthmaniText = uthmani[key];
        final simpleText = simple[key];
        if (uthmaniText == null || simpleText == null) {
          throw TanzilImportException(
            'Missing Uthmani or Simple text for verse $key.',
          );
        }
        verses.add({
          'chapterNumber': chapterNumber,
          'verseNumber': verseNumber,
          // Keep both source verse strings byte-decoded but otherwise untouched.
          'textVariants': {
            'uthmani': uthmaniText,
            'simplified': simpleText,
          },
          'pageNumber': _boundaryAt(pages, chapterNumber, verseNumber),
          'juzNumber': _boundaryAt(juzs, chapterNumber, verseNumber),
          'hizbNumber': _boundaryAt(hizbs, chapterNumber, verseNumber),
        });
      }
      chapters.add({
        'number': chapterNumber,
        'nameArabic': chapterMetadata.nameArabic,
        'nameTransliteration': chapterMetadata.transliteration,
        'revelationPlace': chapterMetadata.revelationPlace,
        'verses': verses,
      });
    }

    final payload = <String, Object?>{
      'schemaVersion': 1,
      'source': {
        'name': sourceName,
        'version': sourceVersion,
        'url': sourceUrl.toString(),
      },
      'chapters': chapters,
    };
    final payloadBytes = Uint8List.fromList(utf8.encode(jsonEncode(payload)));
    final manifest = ResourcePackManifest(
      schemaVersion: 1,
      id: 'quran.arabic',
      version: 'tanzil-1.1',
      kind: QuranResourceKind.quranText,
      language: 'ar',
      sourceName: sourceName,
      sourceUrl: sourceUrl,
      retrievedAt: (retrievedAt ?? DateTime.now()).toUtc(),
      sha256: sha256.convert(payloadBytes).toString(),
      expectedSurahs: 114,
      expectedVerses: 6236,
      license: ResourceLicense(
        name: licenseName,
        url: licenseUrl,
        attribution: attribution,
        reviewed: true,
        offlineAllowed: true,
        bundledAllowed: false,
        redistributionAllowed: true,
        modificationAllowed: false,
      ),
    );

    // Validate the generated internal representation before it can be installed.
    QuranTextPack.fromJson(
      payload,
      expectedChapterCount: 114,
      expectedVerseCount: 6236,
    );

    return TanzilPreparedPack(
      manifest: manifest,
      payloadBytes: payloadBytes,
      uthmaniSourceBytes: uthmaniSource,
      simpleSourceBytes: simpleSource,
      metadataSourceBytes: metadataSource,
      licenseNoticeBytes: Uint8List.fromList(utf8.encode(_tanzilTextCopyright)),
    );
  }

  Map<String, String> _parseText(String source, String label) {
    final result = <String, String>{};
    final lines = const LineSplitter().convert(source);
    for (var lineIndex = 0; lineIndex < lines.length; lineIndex++) {
      final line = lines[lineIndex];
      if (line.trim().isEmpty || line.startsWith('#')) continue;
      final firstSeparator = line.indexOf('|');
      final secondSeparator = firstSeparator < 0
          ? -1
          : line.indexOf('|', firstSeparator + 1);
      if (firstSeparator <= 0 || secondSeparator <= firstSeparator + 1) {
        throw TanzilImportException(
          '$label file line ${lineIndex + 1} is not in surah|ayah|text format. On Tanzil, choose Text (with aya numbers).',
        );
      }

      final chapterNumber = int.tryParse(line.substring(0, firstSeparator));
      final verseNumber = int.tryParse(
        line.substring(firstSeparator + 1, secondSeparator),
      );
      final verseText = line.substring(secondSeparator + 1);
      if (chapterNumber == null ||
          verseNumber == null ||
          chapterNumber < 1 ||
          chapterNumber > verseCounts.length ||
          verseNumber < 1 ||
          verseText.trim().isEmpty) {
        throw TanzilImportException(
          '$label file line ${lineIndex + 1} contains invalid verse data.',
        );
      }
      final key = '$chapterNumber:$verseNumber';
      if (result.containsKey(key)) {
        throw TanzilImportException('$label file contains duplicate verse $key.');
      }
      result[key] = verseText;
    }

    final expectedCount = verseCounts.fold<int>(0, (sum, count) => sum + count);
    if (result.length != expectedCount) {
      throw TanzilImportException(
        '$label file contains ${result.length} verses; expected $expectedCount for Tanzil 1.1.',
      );
    }
    for (var chapterIndex = 0; chapterIndex < verseCounts.length; chapterIndex++) {
      final chapterNumber = chapterIndex + 1;
      for (var verseNumber = 1;
          verseNumber <= verseCounts[chapterIndex];
          verseNumber++) {
        if (!result.containsKey('$chapterNumber:$verseNumber')) {
          throw TanzilImportException(
            '$label file is missing verse $chapterNumber:$verseNumber.',
          );
        }
      }
    }
    return result;
  }

  Map<String, dynamic> _parseMetadata(String source) {
    final document = XmlDocument.parse(source);
    final chapterElements = document.findAllElements('sura').toList()
      ..sort((a, b) => _intAttribute(a, 'index').compareTo(_intAttribute(b, 'index')));
    if (chapterElements.length != 114) {
      throw TanzilImportException(
        'Tanzil metadata must contain 114 surah entries; found ${chapterElements.length}.',
      );
    }
    final chapters = <_ChapterMetadata>[];
    for (var index = 0; index < chapterElements.length; index++) {
      final element = chapterElements[index];
      final number = _intAttribute(element, 'index');
      if (number != index + 1) {
        throw TanzilImportException('Tanzil metadata has an invalid surah sequence.');
      }
      chapters.add(
        _ChapterMetadata(
          nameArabic: _requiredAttribute(element, 'name'),
          transliteration: _firstAttribute(element, const ['tname', 'ename']),
          revelationPlace: _optionalAttribute(element, 'type')?.toLowerCase(),
        ),
      );
    }

    List<_Boundary> readBoundaries(String tag) {
      final boundaries = document.findAllElements(tag).map((element) {
        return _Boundary(
          number: _intAttribute(element, 'index'),
          chapterNumber: _intAttribute(element, 'sura'),
          verseNumber: _intAttribute(element, 'aya'),
        );
      }).toList()
        ..sort((a, b) {
          final chapterComparison = a.chapterNumber.compareTo(b.chapterNumber);
          if (chapterComparison != 0) return chapterComparison;
          return a.verseNumber.compareTo(b.verseNumber);
        });
      return boundaries;
    }

    final pages = readBoundaries('page');
    final juzs = readBoundaries('juz');
    final hizbs = readBoundaries('hizb');
    return {
      'chapters': chapters,
      'pages': pages,
      'juzs': juzs,
      'hizbs': hizbs,
    };
  }

  int? _boundaryAt(List<_Boundary> boundaries, int chapterNumber, int verseNumber) {
    int? found;
    for (final boundary in boundaries) {
      if (boundary.chapterNumber > chapterNumber ||
          (boundary.chapterNumber == chapterNumber &&
              boundary.verseNumber > verseNumber)) {
        break;
      }
      found = boundary.number;
    }
    return found;
  }

  int _intAttribute(XmlElement element, String name) {
    final value = int.tryParse(element.getAttribute(name) ?? '');
    if (value == null || value <= 0) {
      throw TanzilImportException(
        'Tanzil metadata element <${element.name.local}> has invalid $name.',
      );
    }
    return value;
  }

  String _requiredAttribute(XmlElement element, String name) {
    final value = element.getAttribute(name);
    if (value == null || value.trim().isEmpty) {
      throw TanzilImportException(
        'Tanzil metadata element <${element.name.local}> is missing $name.',
      );
    }
    return value;
  }

  String _firstAttribute(XmlElement element, List<String> names) {
    for (final name in names) {
      final value = _optionalAttribute(element, name);
      if (value != null) return value;
    }
    throw TanzilImportException(
      'Tanzil metadata element <${element.name.local}> is missing ${names.join(' or ')}.',
    );
  }

  String? _optionalAttribute(XmlElement element, String name) {
    final value = element.getAttribute(name);
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }
}

class _ChapterMetadata {
  const _ChapterMetadata({
    required this.nameArabic,
    required this.transliteration,
    required this.revelationPlace,
  });

  final String nameArabic;
  final String transliteration;
  final String? revelationPlace;
}

class _Boundary {
  const _Boundary({
    required this.number,
    required this.chapterNumber,
    required this.verseNumber,
  });

  final int number;
  final int chapterNumber;
  final int verseNumber;
}
