import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:text_to_speech/main.dart';
import 'package:text_to_speech/providers/history_provider.dart';
import 'package:text_to_speech/providers/theme_provider.dart';
import 'package:text_to_speech/providers/tts_provider.dart';

void main() {
  testWidgets('app renders splash screen', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => TTSProvider()),
          ChangeNotifierProvider(create: (_) => HistoryProvider()),
          ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ],
        child: const MyApp(),
      ),
    );

    expect(find.text('Text to Speech'), findsOneWidget);
    expect(find.text('Natural Human Voice'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
  });
}
