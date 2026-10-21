import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ai_tourist/main.dart';

Future<void> _launchApp(WidgetTester tester) async {
  await tester.pumpWidget(const AiTouristApp());
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 200));

  final guestBtn = find.text('Continue as Guest');
  if (guestBtn.evaluate().isNotEmpty) {
    await tester.tap(guestBtn);
    await tester.pump(const Duration(milliseconds: 300));
  }
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('AI Tourist app launches and shows 4 bottom navigation tabs', (WidgetTester tester) async {
    await _launchApp(tester);

    // Verify all 4 bottom tabs exist
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Plan'), findsWidgets);
    expect(find.text('Itinerary'), findsWidgets);
    expect(find.text('Assistant'), findsWidgets);

    // Verify home header
    expect(find.textContaining('Hello Mayank'), findsOneWidget);
    expect(find.text('Trending'), findsOneWidget);
    expect(find.text('Popular Destinations'), findsOneWidget);
  });

  testWidgets('Navigating to Plan tab displays the planning form', (WidgetTester tester) async {
    await _launchApp(tester);

    // Tap Plan tab
    await tester.tap(find.text('Plan').last);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Plan Your Trip'), findsOneWidget);
    expect(find.text('Generate My Trip ✨'), findsOneWidget);
    expect(find.text('Destination'), findsOneWidget);
  });

  testWidgets('Navigating to Itinerary tab displays day selector and stops', (WidgetTester tester) async {
    await _launchApp(tester);

    // Tap Itinerary tab
    await tester.tap(find.text('Itinerary').last);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Your Goa Trip'), findsOneWidget);
    expect(find.text('Day 1'), findsOneWidget);
    expect(find.text('Day 2'), findsOneWidget);
    expect(find.text('Budget'), findsOneWidget);
  });

  testWidgets('Navigating to Assistant tab shows conversation UI', (WidgetTester tester) async {
    await _launchApp(tester);

    // Tap Assistant tab
    await tester.tap(find.text('Assistant').last);
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('AI Travel Assistant'), findsOneWidget);
    expect(find.text('Ask anything about your trip...'), findsOneWidget);
  });
}
