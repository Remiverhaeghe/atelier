import 'package:atelier/logic/glossary.dart';
import 'package:atelier/ui/glossary_scenes.dart';
import 'package:atelier/ui/glossary_view.dart';
import 'package:atelier/ui/gestures_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('chaque mot du lexique a son schéma, son usage et sa définition', (pTester) async {
    tallScreen(pTester);
    for (final vTerm in Term.values) {
      await pTester.pumpWidget(
        localized(SingleChildScrollView(child: TermCard(vTerm, key: ValueKey(vTerm)))),
      );
      expect(find.byType(TermSketch), findsOneWidget, reason: vTerm.name);
      expect(pTester.takeException(), isNull, reason: vTerm.name);
    }
  });

  testWidgets('le lexique mène aux gestes de base', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const GlossaryScreen()));
    await pTester.tap(find.byTooltip('Gestes de base'));
    await pTester.pumpAndSettle();
    expect(find.byType(GesturesScreen), findsOneWidget);
  });
}
