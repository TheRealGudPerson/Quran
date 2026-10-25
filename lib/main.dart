import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'reader/downloads_page.dart';
import 'reader/quran_reader_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const QuranReaderApp());
}

enum ReaderSection { reader, study, downloads, settings }

class QuranReaderApp extends StatefulWidget {
  const QuranReaderApp({super.key});

  @override
  State<QuranReaderApp> createState() => _QuranReaderAppState();
}

class _QuranReaderAppState extends State<QuranReaderApp> {
  ThemeMode _themeMode = ThemeMode.system;
  Color _seedColor = const Color(0xFF246B55);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quran Reader',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: _buildTheme(Brightness.light, _seedColor),
      darkTheme: _buildTheme(Brightness.dark, _seedColor),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('en'), Locale('ar')],
      home: QuranHomePage(
        themeMode: _themeMode,
        seedColor: _seedColor,
        onThemeModeChanged: (value) => setState(() => _themeMode = value),
        onSeedColorChanged: (value) => setState(() => _seedColor = value),
      ),
    );
  }
}

ThemeData _buildTheme(Brightness brightness, Color seedColor) {
  final scheme = ColorScheme.fromSeed(
    seedColor: seedColor,
    brightness: brightness,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    brightness: brightness,
    visualDensity: VisualDensity.adaptivePlatformDensity,
    scaffoldBackgroundColor: scheme.surface,
  );
}

class QuranHomePage extends StatefulWidget {
  const QuranHomePage({
    required this.themeMode,
    required this.seedColor,
    required this.onThemeModeChanged,
    required this.onSeedColorChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final Color seedColor;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Color> onSeedColorChanged;

  @override
  State<QuranHomePage> createState() => _QuranHomePageState();
}

class _QuranHomePageState extends State<QuranHomePage> {
  ReaderSection _section = ReaderSection.reader;

  static const List<NavigationRailDestination> _destinations = [
    NavigationRailDestination(
      icon: Icon(Icons.menu_book_outlined),
      selectedIcon: Icon(Icons.menu_book_rounded),
      label: Text('Reader'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.bookmark_border_rounded),
      selectedIcon: Icon(Icons.bookmark_rounded),
      label: Text('Study'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.download_outlined),
      selectedIcon: Icon(Icons.download_rounded),
      label: Text('Downloads'),
    ),
    NavigationRailDestination(
      icon: Icon(Icons.settings_outlined),
      selectedIcon: Icon(Icons.settings_rounded),
      label: Text('Settings'),
    ),
  ];

  void _selectSection(int index) {
    setState(() => _section = ReaderSection.values[index]);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 760;
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.menu_book_rounded),
            SizedBox(width: 10),
            Text('Quran Reader'),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => setState(() => _section = ReaderSection.settings),
            icon: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (wide)
            NavigationRail(
              selectedIndex: _section.index,
              onDestinationSelected: _selectSection,
              labelType: NavigationRailLabelType.all,
              destinations: _destinations,
              groupAlignment: -0.8,
              leading: const Padding(
                padding: EdgeInsets.only(bottom: 24, top: 12),
                child: Icon(Icons.auto_stories_rounded, size: 30),
              ),
            ),
          if (wide) const VerticalDivider(width: 1),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _buildSection(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _section.index,
              onDestinationSelected: _selectSection,
              destinations: _destinations
                  .map((item) => NavigationDestination(
                        icon: item.icon,
                        selectedIcon: item.selectedIcon,
                        label: (item.label as Text).data!,
                      ))
                  .toList(),
            ),
    );
  }

  Widget _buildSection() => switch (_section) {
        ReaderSection.reader => const QuranReaderPage(key: ValueKey('reader')),
        ReaderSection.study => const _FeatureLanding(
            key: ValueKey('study'),
            icon: Icons.bookmarks_rounded,
            title: 'Your study space',
            description:
                'Bookmarks, notes, highlights, reading plans, and memorization progress will live here.',
          ),
        ReaderSection.downloads => const DownloadsPage(key: ValueKey('downloads')),
        ReaderSection.settings => _SettingsPage(
            key: const ValueKey('settings'),
            themeMode: widget.themeMode,
            seedColor: widget.seedColor,
            onThemeModeChanged: widget.onThemeModeChanged,
            onSeedColorChanged: widget.onSeedColorChanged,
          ),
      };
}

class _FeatureLanding extends StatelessWidget {
  const _FeatureLanding({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 56, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 18),
              Text(title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center),
              const SizedBox(height: 10),
              Text(description,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsPage extends StatelessWidget {
  const _SettingsPage({
    required this.themeMode,
    required this.seedColor,
    required this.onThemeModeChanged,
    required this.onSeedColorChanged,
    super.key,
  });

  final ThemeMode themeMode;
  final Color seedColor;
  final ValueChanged<ThemeMode> onThemeModeChanged;
  final ValueChanged<Color> onSeedColorChanged;

  static const _colors = <Color>[
    Color(0xFF246B55),
    Color(0xFF3559A8),
    Color(0xFF8755A1),
    Color(0xFF9A5A27),
    Color(0xFF9A3D55),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Appearance', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Choose a theme and accent. Reader typography and detailed controls will be added with the reading engine.',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.settings_suggest_outlined)),
                    ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                    ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
                  ],
                  selected: {themeMode},
                  onSelectionChanged: (selection) => onThemeModeChanged(selection.first),
                ),
                const SizedBox(height: 24),
                Text('Accent color', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: _colors.map((color) {
                    final selected = color == seedColor;
                    return Semantics(
                      button: true,
                      selected: selected,
                      label: 'Accent color',
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => onSeedColorChanged(color),
                        child: CircleAvatar(
                          radius: 23,
                          backgroundColor: color,
                          child: selected
                              ? const Icon(Icons.check, color: Colors.white)
                              : null,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: const Icon(Icons.check_circle_outline, size: 18),
      label: Text(label),
    );
  }
}
