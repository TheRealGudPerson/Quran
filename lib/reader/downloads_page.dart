import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/resource_pack_installer.dart';
import '../core/tanzil_text_importer.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  bool _busy = false;
  String? _status;
  bool _statusIsError = false;

  Future<void> _openSource(Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open $uri')),
      );
    }
  }

  Future<void> _importTanzilPack() async {
    setState(() {
      _busy = true;
      _status = null;
    });

    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['txt', 'xml'],
        allowMultiple: true,
        withData: true,
      );
      if (selection == null) return;
      if (selection.files.length != 3 ||
          selection.files.any((file) => file.bytes == null)) {
        throw const FormatException(
          'Select exactly three files: a Tanzil Uthmani text file, a Tanzil Simple text file, and quran-data.xml.',
        );
      }

      PlatformFile? uthmaniFile;
      PlatformFile? simpleFile;
      PlatformFile? metadataFile;
      for (final file in selection.files) {
        final name = file.name.toLowerCase();
        if (name.endsWith('.xml')) {
          if (metadataFile != null) {
            throw const FormatException('Select only one XML metadata file.');
          }
          metadataFile = file;
        } else if (name.contains('uthmani')) {
          if (uthmaniFile != null) {
            throw const FormatException('Select only one Uthmani text file.');
          }
          uthmaniFile = file;
        } else if (name.contains('simple')) {
          if (simpleFile != null) {
            throw const FormatException('Select only one Simple text file.');
          }
          simpleFile = file;
        } else {
          throw FormatException(
            'Could not identify "${file.name}". Name the text files so one contains "uthmani" and the other contains "simple".',
          );
        }
      }
      if (uthmaniFile == null || simpleFile == null || metadataFile == null) {
        throw const FormatException(
          'Could not identify all three files. Choose Uthmani text, Simple text, and quran-data.xml.',
        );
      }

      final prepared = TanzilTextImporter().prepare(
        uthmaniBytes: uthmaniFile.bytes!,
        simpleBytes: simpleFile.bytes!,
        metadataBytes: metadataFile.bytes!,
      );
      final supportDirectory = await getApplicationSupportDirectory();

      await _archiveVerbatimSources(supportDirectory, prepared);
      final installer = ResourcePackInstaller(rootDirectory: supportDirectory);
      final installed = await installer.install(
        manifest: prepared.manifest,
        payloadBytes: prepared.payloadBytes,
      );

      if (mounted) {
        setState(() {
          _status =
              'Installed ${installed.manifest.sourceName} ${installed.manifest.version}: 114 surahs and 6,236 ayahs. The original source files and required attribution notice were also saved unchanged.';
          _statusIsError = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _status = error.toString();
          _statusIsError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _archiveVerbatimSources(
    Directory supportDirectory,
    TanzilPreparedPack prepared,
  ) async {
    final parent = Directory('${supportDirectory.path}/sources/tanzil');
    await parent.create(recursive: true);
    final target = Directory('${parent.path}/1.1');
    final files = <String, Uint8List>{
      'uthmani.txt': prepared.uthmaniSourceBytes,
      'simple.txt': prepared.simpleSourceBytes,
      'quran-data.xml': prepared.metadataSourceBytes,
      'LICENSE.txt': prepared.licenseNoticeBytes,
    };

    if (await target.exists()) {
      for (final entry in files.entries) {
        final file = File('${target.path}/${entry.key}');
        if (!await file.exists() ||
            !_bytesEqual(await file.readAsBytes(), entry.value)) {
          throw const FileSystemException(
            'A different Tanzil 1.1 source archive already exists. The app will not overwrite source files for the same version.',
          );
        }
      }
      return;
    }

    final staging = Directory(
      '${parent.path}/.staging-${DateTime.now().microsecondsSinceEpoch}',
    );
    try {
      await staging.create();
      for (final entry in files.entries) {
        await File('${staging.path}/${entry.key}')
            .writeAsBytes(entry.value, flush: true);
      }
      await staging.rename(target.path);
    } catch (_) {
      if (await staging.exists()) await staging.delete(recursive: true);
      rethrow;
    }
  }

  bool _bytesEqual(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    for (var index = 0; index < left.length; index++) {
      if (left[index] != right[index]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Offline library', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Set up the first complete offline Quran text edition. The app imports the official source files, validates every surah and ayah, preserves the original source bytes, and keeps the Uthmani and Simple editions separate.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.menu_book_rounded, size: 34),
                const SizedBox(height: 12),
                Text(
                  'Tanzil Quran text · Version 1.1',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Download these three files from the official sources. On the Tanzil download page, choose Uthmani and Simple text types, select “Text (with aya numbers)” for both, and use the same options for pause marks, sajdah signs, and rub-el-hizb signs. Keep the downloaded files unchanged.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => _openSource(TanzilTextImporter.sourceUrl),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Tanzil text downloads'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _openSource(TanzilTextImporter.metadataUrl),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Quran metadata XML'),
                    ),
                    TextButton.icon(
                      onPressed: () => _openSource(TanzilTextImporter.licenseUrl),
                      icon: const Icon(Icons.policy_outlined),
                      label: const Text('Read license'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _RequiredFile(
                  filename: 'quran-uthmani.txt',
                  description: 'Uthmani edition, with surah and ayah numbers.',
                ),
                const _RequiredFile(
                  filename: 'quran-simple.txt',
                  description: 'Simple/Imla’ei edition, with the same download options.',
                ),
                const _RequiredFile(
                  filename: 'quran-data.xml',
                  description: 'Official surah names and page, juz, and hizb boundaries.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _importTanzilPack,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_open_rounded),
                  label: Text(_busy ? 'Validating all 6,236 ayahs…' : 'Import the three source files'),
                ),
                const SizedBox(height: 12),
                Text(
                  'The importer rejects missing or duplicate ayahs, checks all 114 surahs, and refuses to alter source text. It does not bundle the dataset into the installer.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (_status != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _statusIsError
                          ? scheme.errorContainer
                          : scheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _status!,
                      style: TextStyle(
                        color: _statusIsError
                            ? scheme.onErrorContainer
                            : scheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Text(
              'Attribution: Tanzil Quran Text, Copyright (C) 2007–2021 Tanzil Project, Creative Commons Attribution 3.0. The source and license notice are retained locally and will be shown in the reader. Source: https://tanzil.net/',
            ),
          ),
        ),
      ],
    );
  }
}

class _RequiredFile extends StatelessWidget {
  const _RequiredFile({required this.filename, required this.description});

  final String filename;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.insert_drive_file_outlined, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(filename, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
