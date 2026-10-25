class QuranTextPackValidationException implements Exception {
  const QuranTextPackValidationException(this.message);

  final String message;

  @override
  String toString() => 'QuranTextPackValidationException: $message';
}

class QuranVerse {
  const QuranVerse({
    required this.chapterNumber,
    required this.verseNumber,
    required this.textVariants,
    this.transliteration,
    this.translations = const {},
    this.tafsir = const {},
    this.pageNumber,
    this.juzNumber,
    this.hizbNumber,
  });

  final int chapterNumber;
  final int verseNumber;
  final Map<String, String> textVariants;
  final String? transliteration;
  final Map<String, String> translations;
  final Map<String, String> tafsir;
  final int? pageNumber;
  final int? juzNumber;
  final int? hizbNumber;

  String get id => '$chapterNumber:$verseNumber';

  String? textFor(String script) => textVariants[script];
}

class QuranChapter {
  const QuranChapter({
    required this.number,
    required this.nameArabic,
    required this.nameTransliteration,
    required this.verses,
    this.revelationPlace,
  });

  final int number;
  final String nameArabic;
  final String nameTransliteration;
  final String? revelationPlace;
  final List<QuranVerse> verses;

  int get verseCount => verses.length;
}

class QuranTextPack {
  const QuranTextPack({
    required this.schemaVersion,
    required this.sourceName,
    required this.sourceVersion,
    required this.sourceUrl,
    required this.chapters,
  });

  final int schemaVersion;
  final String sourceName;
  final String sourceVersion;
  final Uri sourceUrl;
  final List<QuranChapter> chapters;

  int get totalVerses =>
      chapters.fold<int>(0, (total, chapter) => total + chapter.verseCount);

  QuranVerse? verseAt(int chapterNumber, int verseNumber) {
    if (chapterNumber < 1 || chapterNumber > chapters.length) return null;
    final chapter = chapters[chapterNumber - 1];
    if (chapter.number != chapterNumber ||
        verseNumber < 1 ||
        verseNumber > chapter.verses.length) {
      return null;
    }
    final verse = chapter.verses[verseNumber - 1];
    return verse.verseNumber == verseNumber ? verse : null;
  }

  factory QuranTextPack.fromJson(
    Map<String, dynamic> json, {
    int expectedChapterCount = 114,
    int expectedVerseCount = 6236,
  }) {
    if (json['schemaVersion'] != 1) {
      throw const QuranTextPackValidationException(
        'Unsupported Quran text pack schema version.',
      );
    }

    final source = json['source'];
    if (source is! Map<String, dynamic>) {
      throw const QuranTextPackValidationException(
        'source must be a JSON object.',
      );
    }
    final sourceName = _requiredText(source, 'name');
    final sourceVersion = _requiredText(source, 'version');
    final sourceUrlText = _requiredText(source, 'url');
    final sourceUrl = Uri.tryParse(sourceUrlText);
    if (sourceUrl == null ||
        !sourceUrl.hasScheme ||
        !{'http', 'https'}.contains(sourceUrl.scheme)) {
      throw const QuranTextPackValidationException(
        'source.url must be an absolute HTTP(S) URL.',
      );
    }

    final rawChapters = json['chapters'];
    if (rawChapters is! List) {
      throw const QuranTextPackValidationException(
        'chapters must be a JSON array.',
      );
    }

    final chapters = <QuranChapter>[];
    for (final rawChapter in rawChapters) {
      if (rawChapter is! Map<String, dynamic>) {
        throw const QuranTextPackValidationException(
          'Each chapter must be a JSON object.',
        );
      }
      chapters.add(_chapterFromJson(rawChapter));
    }

    final pack = QuranTextPack(
      schemaVersion: 1,
      sourceName: sourceName,
      sourceVersion: sourceVersion,
      sourceUrl: sourceUrl,
      chapters: List.unmodifiable(chapters),
    );
    pack.validate(
      expectedChapterCount: expectedChapterCount,
      expectedVerseCount: expectedVerseCount,
    );
    return pack;
  }

  void validate({
    int expectedChapterCount = 114,
    int expectedVerseCount = 6236,
  }) {
    if (chapters.length != expectedChapterCount) {
      throw QuranTextPackValidationException(
        'Expected $expectedChapterCount chapters, found ${chapters.length}.',
      );
    }

    for (var chapterIndex = 0; chapterIndex < chapters.length; chapterIndex++) {
      final chapter = chapters[chapterIndex];
      final expectedChapterNumber = chapterIndex + 1;
      if (chapter.number != expectedChapterNumber) {
        throw QuranTextPackValidationException(
          'Chapter at position $expectedChapterNumber has number ${chapter.number}.',
        );
      }
      if (chapter.nameArabic.trim().isEmpty ||
          chapter.nameTransliteration.trim().isEmpty) {
        throw QuranTextPackValidationException(
          'Chapter $expectedChapterNumber is missing a display name.',
        );
      }
      if (chapter.verses.isEmpty) {
        throw QuranTextPackValidationException(
          'Chapter $expectedChapterNumber has no verses.',
        );
      }

      for (var verseIndex = 0; verseIndex < chapter.verses.length; verseIndex++) {
        final verse = chapter.verses[verseIndex];
        final expectedVerseNumber = verseIndex + 1;
        if (verse.chapterNumber != chapter.number ||
            verse.verseNumber != expectedVerseNumber) {
          throw QuranTextPackValidationException(
            'Invalid verse ordering in chapter ${chapter.number} at position $expectedVerseNumber.',
          );
        }
        for (final script in const ['uthmani', 'simplified']) {
          if ((verse.textVariants[script] ?? '').trim().isEmpty) {
            throw QuranTextPackValidationException(
              'Verse ${verse.id} is missing the $script text variant.',
            );
          }
        }
      }
    }

    if (totalVerses != expectedVerseCount) {
      throw QuranTextPackValidationException(
        'Expected $expectedVerseCount verses, found $totalVerses.',
      );
    }
  }
}

QuranChapter _chapterFromJson(Map<String, dynamic> json) {
  final rawVerses = json['verses'];
  if (rawVerses is! List) {
    throw const QuranTextPackValidationException(
      'chapter.verses must be a JSON array.',
    );
  }

  final verses = <QuranVerse>[];
  for (final rawVerse in rawVerses) {
    if (rawVerse is! Map<String, dynamic>) {
      throw const QuranTextPackValidationException(
        'Each verse must be a JSON object.',
      );
    }
    final rawVariants = rawVerse['textVariants'];
    if (rawVariants is! Map<String, dynamic>) {
      throw const QuranTextPackValidationException(
        'verse.textVariants must be a JSON object.',
      );
    }
    final variants = <String, String>{};
    for (final entry in rawVariants.entries) {
      if (entry.value is! String || (entry.value as String).trim().isEmpty) {
        throw QuranTextPackValidationException(
          'Text variant ${entry.key} must be a non-empty string.',
        );
      }
      variants[entry.key] = entry.value as String;
    }

    verses.add(
      QuranVerse(
        chapterNumber: _requiredPositiveInt(rawVerse, 'chapterNumber'),
        verseNumber: _requiredPositiveInt(rawVerse, 'verseNumber'),
        textVariants: Map.unmodifiable(variants),
        transliteration: _optionalText(rawVerse, 'transliteration'),
        translations: _stringMap(rawVerse['translations'], 'translations'),
        tafsir: _stringMap(rawVerse['tafsir'], 'tafsir'),
        pageNumber: _optionalPositiveInt(rawVerse, 'pageNumber'),
        juzNumber: _optionalPositiveInt(rawVerse, 'juzNumber'),
        hizbNumber: _optionalPositiveInt(rawVerse, 'hizbNumber'),
      ),
    );
  }

  return QuranChapter(
    number: _requiredPositiveInt(json, 'number'),
    nameArabic: _requiredText(json, 'nameArabic'),
    nameTransliteration: _requiredText(json, 'nameTransliteration'),
    revelationPlace: _optionalText(json, 'revelationPlace'),
    verses: List.unmodifiable(verses),
  );
}

String _requiredText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.trim().isEmpty) {
    throw QuranTextPackValidationException('$key must be a non-empty string.');
  }
  return value;
}

String? _optionalText(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! String) {
    throw QuranTextPackValidationException('$key must be a string when provided.');
  }
  return value;
}

int _requiredPositiveInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int || value <= 0) {
    throw QuranTextPackValidationException('$key must be a positive integer.');
  }
  return value;
}

int? _optionalPositiveInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value == null) return null;
  if (value is! int || value <= 0) {
    throw QuranTextPackValidationException('$key must be a positive integer.');
  }
  return value;
}

Map<String, String> _stringMap(dynamic value, String fieldName) {
  if (value == null) return const {};
  if (value is! Map<String, dynamic>) {
    throw QuranTextPackValidationException('$fieldName must be a JSON object.');
  }
  final result = <String, String>{};
  for (final entry in value.entries) {
    if (entry.key.trim().isEmpty ||
        entry.value is! String ||
        (entry.value as String).trim().isEmpty) {
      throw QuranTextPackValidationException(
        '$fieldName keys and values must be non-empty strings.',
      );
    }
    result[entry.key] = entry.value as String;
  }
  return Map.unmodifiable(result);
}
