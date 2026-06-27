import 'package:abyss_relic/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app starts with five main tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AbyssRelicApp()));

    expect(find.text('深渊遗装'), findsOneWidget);
    expect(find.text('战斗'), findsWidgets);
    expect(find.text('装备'), findsWidgets);
    expect(find.text('构筑'), findsWidgets);
    expect(find.text('深渊'), findsWidgets);
    expect(find.text('角色'), findsWidgets);
  });

  testWidgets('main tabs can be selected without crashing',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AbyssRelicApp()));

    for (final label in ['装备', '构筑', '深渊', '角色', '战斗']) {
      await tester.tap(find.text(label).last);
      await tester.pumpAndSettle();
      expect(find.text(label), findsWidgets);
    }
  });

  testWidgets('debug panel is reachable in debug mode',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AbyssRelicApp()));

    await tester.tap(find.byIcon(Icons.bug_report_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Debug'), findsOneWidget);
    expect(find.text('Bootstrap'), findsOneWidget);
    expect(find.text('Config Database'), findsOneWidget);
  });
}
