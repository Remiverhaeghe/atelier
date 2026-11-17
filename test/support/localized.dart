import 'package:atelier/l10n/gen/app_localizations.dart';
import 'package:atelier/ui/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Écran isolé avec les textes français, pour les tests d'écran.
Widget localized(Widget pChild) => MaterialApp(
  theme: atelierTheme(Brightness.light),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: pChild),
);

/// Liste verticale de l'écran : les champs de saisie et les onglets défilent aussi.
Finder verticalList() => find
    .byWidgetPredicate(
      (pWidget) => pWidget is Scrollable && pWidget.axisDirection == AxisDirection.down,
    )
    .first;

/// Fait défiler la liste jusqu'au premier élément trouvé, même s'il n'est pas encore construit.
///
/// `scrollUntilVisible` avec `.first` échoue tant que la liste paresseuse n'a rien construit.
Future<void> scrollToFirst(WidgetTester pTester, Finder pFinder) async {
  for (var vStep = 0; pFinder.evaluate().isEmpty && vStep < 50; vStep++) {
    await pTester.drag(verticalList(), const Offset(0, -200));
    await pTester.pump();
  }
  await pTester.ensureVisible(pFinder.first);
  await pTester.pump();
}

/// Écran haut, pour qu'une vue longue tienne sans défilement.
void tallScreen(WidgetTester pTester) {
  pTester.view.physicalSize = const Size(800, 2400);
  pTester.view.devicePixelRatio = 1;
  addTearDown(pTester.view.reset);
}

/// Fait défiler la grille des calculs jusqu'à la tuile [pTitle] : la grille ne construit que les
/// tuiles proches de l'écran, et elle s'allonge à chaque nouveau calcul.
Future<void> scrollToTile(WidgetTester pTester, String pTitle) async {
  await pTester.scrollUntilVisible(
    find.text(pTitle),
    400,
    scrollable: find.descendant(of: find.byType(GridView), matching: find.byType(Scrollable)).first,
  );
  await pTester.pumpAndSettle();
}
