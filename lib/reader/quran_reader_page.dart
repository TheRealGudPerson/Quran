import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../core/quran_text_pack.dart';
import '../core/quran_text_repository.dart';
import '../core/resource_pack_installer.dart';

class QuranReaderPage extends StatefulWidget {
  const QuranReaderPage({super.key});

  @override
  State<QuranReaderPage> createState() => _QuranReaderPageState();
}

class _QuranReaderPageState extends State<QuranReaderPage> {
  late Future<QuranTextPack?> _packFuture;
  String _script = 'uthmani';
  String? _translationId;
  int _chapterNumber = 1;

  @override
  void initState() {
    super.initState();
    _packFuture = _loadPack();
  }

  Future<QuranTextPack?> _loadPack() async {
    final supportDirectory = await getApplicationSupportDirectory();
    final repository = QuranTextRepository(
      installer: ResourcePackInstaller(rootDirectory: supportDirectory),
    );
    return repository.loadActivePack();
  }

  void _reload() {
    setState(() => _packFuture = _loadPack());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuranTextPack?>(
      future: _packFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return _ReaderMessage(
            icon: Icons.error_outline_rounded,
            title: 'Could not load the Quran text pack',
            message: '${snapshot.error}',
            actionLabel: 'Try again',
            onAction: _reload,
          );
        }
        final pack = snapshot.data;
        if (pack == null) {
          return _ReaderMessage(
            icon: Icons.menu_book_rounded,
            title: 'Your reader is ready for its first text pack',
            message:
                'No verified Quran text is installed yet. Add a licensed resource pack from Downloads to begin reading offline.',
          );
        }
        if (pack.chapters.isEmpty) {
          return const _ReaderMessage(
            icon: Icons.warning_amber_rounded,
            title: 'The installed text pack is empty',
            message: 'Install a valid Quran text pack before reading.',
          );
        }

        final chapterIndex = _chapterNumber >= 1 &&
                _chapterNumber <= pack.chapters.length
            ? _chapterNumber - 1
            : 0;
        final chapter = pack.chapters[chapterIndex];
        final translationIds = <String>{
          for (final item in pack.chapters)
            for (final verse in item.verses) ...verse.translations.keys,
        }.toList()
          ..sort();
        final selectedTranslation = translationIds.contains(_translationId)
            ? _translationId
            : null;

        return Column(
          children: [
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 12,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: 250,
                      child: DropdownButtonFormField<int>(
                        value: chapter.number,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Surah',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: pack.chapters
                            .map((item) => DropdownMenuItem<int>(
                                  value: item.number,
                                  child: Text(
                                    '${item.number}. ${item.nameTransliteration}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _chapterNumber = value);
                          }
                        },
                      ),
                    ),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'uthmani',
                          label: Text('Uthmani'),
                        ),
                        ButtonSegment(
                          value: 'simplified',
                          label: Text('Simplified'),
                        ),
                      ],
                      selected: {_script},
                      onSelectionChanged: (selection) {
                        setState(() => _script = selection.first);
                      },
                    ),
                    if (translationIds.isNotEmpty)
                      SizedBox(
                        width: 230,
                        child: DropdownButtonFormField<String?>(
                          value: selectedTranslation,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Translation',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          items: [
                            const DropdownMenuItem<String?>(
                              value: null,
                              child: Text('Arabic only'),
                            ),
                            ...translationIds.map(
                              (id) => DropdownMenuItem<String?>(
                                value: id,
                                child: Text(id, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => _translationId = value);
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Column(
                children: [
                  Text(
                    chapter.nameArabic,
                    textDirection: TextDirection.rtl,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${chapter.nameTransliteration} · ${chapter.verseCount} verses',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                key: PageStorageKey<int>(chapter.number),
                padding: const EdgeInsets.all(20),
                itemCount: chapter.verses.length,
                separatorBuilder: (_, __) => const Divider(height: 28),
                itemBuilder: (context, index) {
                  final verse = chapter.verses[index];
                  final arabic = verse.textFor(_script);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            child: Text('${verse.verseNumber}'),
                          ),
                          const Spacer(),
                          if (verse.pageNumber != null)
                            Text('Page ${verse.pageNumber}'),
                          if (verse.juzNumber != null) ...[
                            const SizedBox(width: 12),
                            Text('Juz ${verse.juzNumber}'),
                          ],
                        ],
                      ),
                      const SizedBox(height: 14),
                      SelectableText(
                        arabic ?? 'This verse has no $_script text variant.',
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              height: 2.0,
                              fontSize: 28,
                            ),
                      ),
                      if (verse.transliteration?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 8),
                        Text(
                          verse.transliteration!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontStyle: FontStyle.italic,
                              ),
                        ),
                      ],
                      if (selectedTranslation != null &&
                          verse.translations[selectedTranslation] != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          verse.translations[selectedTranslation]!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ReaderMessage extends StatelessWidget {
  const _ReaderMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 18),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 10),
              Text(message, textAlign: TextAlign.center),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 18),
                FilledButton(onPressed: onAction, child: Text(actionLabel!)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
