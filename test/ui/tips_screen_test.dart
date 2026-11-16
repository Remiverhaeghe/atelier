import 'package:atelier/l10n/gen/app_localizations.dart';
import 'package:atelier/logic/tips.dart';
import 'package:atelier/ui/tips_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('les fiches s\'ouvrent avec leurs étapes et leur mise en garde', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const TipsScreen()));

    expect(find.text('Plinthes'), findsOneWidget);
    await pTester.tap(find.text('Entretenir une climatisation'));
    await pTester.pumpAndSettle();

    expect(find.text('1'), findsOneWidget);
    expect(find.textContaining('Coupe l\'appareil'), findsOneWidget);
    expect(find.text('Attention'), findsOneWidget);
  });

  testWidgets('chaque fiche a un titre et des étapes', (pTester) async {
    await pTester.pumpWidget(localized(const SizedBox()));
    final vText = AppLocalizations.of(pTester.element(find.byType(SizedBox)));

    for (final vTip in Tip.values) {
      final vTexts = tipTexts(vText, vTip);
      expect(vTexts.title, isNotEmpty);
      expect(tipSteps(vTexts.steps).length, greaterThanOrEqualTo(4));
      expect(vTexts.warning != null, vTip.hasWarning);
    }
  });
}
