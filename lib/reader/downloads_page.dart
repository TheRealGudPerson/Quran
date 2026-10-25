import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../core/resource_pack_installer.dart';
import '../core/resource_pack_manifest.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  bool _busy = false;
  String? _status;
  bool _statusIsError = false;

  Future<void> _importQuranPack() async {
    setState(() {
      _busy = true;
      _status = null;
    });

    try {
      final selection = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        allowMultiple: true,
        withData: true,
      );
      if (selection == null) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      if (selection.files.length != 2 ||
          selection.files.any((file) => file.bytes == null)) {
        throw const FormatException(
          'Select exactly two JSON files: the resource manifest and its payload.',
        );
      }

      PlatformFile? manifestFile;
      PlatformFile? payloadFile;
      for (final file in selection.files) {
        final decoded = jsonDecode(utf8.decode(file.bytes!));
        if (decoded is Map<String, dynamic> &&
            decoded.containsKey('sha256') &&
            decoded.containsKey('license') &&
            decoded.containsKey('kind')) {
          if (manifestFile != null) {
            throw const FormatException(
              'More than one selected file looks like a resource manifest.',
            );
          }
          manifestFile = file;
        } else {
          if (payloadFile != null) {
            throw const FormatException(
              'More than one selected file looks like a resource payload.',
            );
          }
          payloadFile = file;
        }
      }
      if (manifestFile == null || payloadFile == null) {
        throw const FormatException(
          'Could not identify both the manifest and the payload JSON.',
        );
      }

      final manifest = ResourcePackManifest.decode(
        utf8.decode(manifestFile.bytes!),
      );
      if (manifest.kind != QuranResourceKind.quranText ||
          manifest.id != 'quran.arabic') {
        throw const FormatException(
          'The first import screen currently accepts the primary Quran text pack only. Its manifest id must be quran.arabic and kind must be quranText.',
        );
      }

      final supportDirectory = await getApplicationSupportDirectory();
      final installer = ResourcePackInstaller(rootDirectory: supportDirectory);
      final installed = await installer.install(
        manifest: manifest,
        payloadBytes: payloadFile.bytes!,
      );

      if (mounted) {
        setState(() {
          _status =
              'Installed ${installed.manifest.sourceName} ${installed.manifest.version}. Return to Reader to begin reading.';
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Offline library', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Import a resource manifest and its matching JSON payload. The app checks the declared license flags, SHA-256 checksum, Quran structure, source metadata, and expected verse counts before activating the pack.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.verified_user_outlined, size: 32),
                const SizedBox(height: 12),
                Text(
                  'Primary Quran text',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choose two .json files together: one manifest and one text payload. This import flow does not download content or make licensing decisions for you. Only import resources whose actual terms have been reviewed.',
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _importQuranPack,
                  icon: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_open_rounded),
                  label: Text(_busy ? 'Validating resource…' : 'Import Quran text pack'),
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
      ],
    );
  }
}
