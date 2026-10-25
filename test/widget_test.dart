import 'package:flutter_test/flutter_test.dart';
import 'package:quran_reader/main.dart';

void main() {
  testWidgets('shows reader setup state without unverified Quran data',
      (tester) async {
    await tester.pumpWidget(const QuranReaderApp());

    expect(find.text('Quran Reader'), findsOneWidget);
    expect(find.text('Reader setup is in progress'), findsOneWidget);
    expect(find.textContaining('No Quran dataset is bundled yet.'), findsOneWidget);
  });

  testWidgets('settings screen exposes theme choices', (tester) async {
    await tester.pumpWidget(const QuranReaderApp());

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });
}
