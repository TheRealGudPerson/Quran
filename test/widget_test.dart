import 'package:flutter_test/flutter_test.dart';
import 'package:quran_reader/main.dart';

void main() {
  testWidgets('shows the reader shell before resources are installed',
      (tester) async {
    await tester.pumpWidget(const QuranReaderApp());

    expect(find.text('Quran Reader'), findsOneWidget);
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
