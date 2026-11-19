import 'package:atelier/logic/expenses.dart';
import 'package:atelier/logic/planning.dart';
import 'package:atelier/logic/time_tracking.dart';
import 'package:atelier/ui/debris_calculator.dart';
import 'package:atelier/ui/quote_compare_screen.dart';
import 'package:atelier/ui/real_cost_card.dart';
import 'package:atelier/ui/right_tool_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('le bon outil : à la main, puis louer, emprunter ou acheter', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const RightToolScreen()));
    expect(find.text('Faites-le à la main'), findsOneWidget);
    expect(find.textContaining('À la main : Scie égoïne, 12 à 30 €'), findsOneWidget);
    expect(find.textContaining('scie circulaire, environ 90 €'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Jours d\'utilisation'), '3');
    await pTester.pump();
    expect(find.text('Louez l\'outil électrique'), findsOneWidget);
    expect(find.text('Location pour ces jours : 75 €'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Jours d\'utilisation'), '5');
    await pTester.pump();
    expect(find.text('Achetez l\'outil électrique'), findsOneWidget);
    expect(find.text('Budget : 90 €'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Jours d\'utilisation'), '2');
    await pTester.tap(find.text('J\'ai déjà l\'outil à la main'));
    await pTester.pump();
    expect(find.text('Budget : 0 €'), findsOneWidget);
    expect(find.text('Gestes avec cet outil'), findsOneWidget);
  });

  testWidgets('emprunter le perforateur quand un proche le prête', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const RightToolScreen()));
    await pTester.tap(find.text('Scier des planches'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Percer du béton').last);
    await pTester.pumpAndSettle();
    expect(find.text('Pas d\'outil à la main raisonnable pour cette tâche.'), findsOneWidget);
    expect(find.text('J\'ai déjà l\'outil à la main'), findsNothing);
    expect(find.text('Louez l\'outil électrique'), findsOneWidget);
    await pTester.tap(find.text('Un proche peut me le prêter'));
    await pTester.pump();
    expect(find.text('Empruntez l\'outil électrique'), findsOneWidget);
    expect(find.text('Budget : 0 €'), findsOneWidget);
  });

  testWidgets('déchets : benne de chaque déchet, pots de peinture et kilomètres', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const DebrisCalculator()));
    expect(find.text('Benne : Gravats et inertes'), findsOneWidget);
    await pTester.enterText(
      find.widgetWithText(TextField, 'Pots de peinture, colle, solvant'),
      '4',
    );
    await pTester.enterText(
      find.widgetWithText(TextField, 'Distance jusqu\'à la déchetterie (km)'),
      '12,5',
    );
    await pTester.pump();
    expect(find.textContaining('4 pots aux déchets dangereux, environ 10 L'), findsOneWidget);
    expect(find.text('75 km à rouler pour ces voyages'), findsOneWidget);
    expect(find.textContaining('changent d\'une déchetterie à l\'autre'), findsOneWidget);
  });

  testWidgets('coût réel : rien sans taux, puis main-d\'œuvre évitée', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(
      localized(
        const Scaffold(
          body: SingleChildScrollView(
            child: RealCostCard(
              entries: [
                TimeEntry(roomId: 'a', phase: WorkPhase.parquet, minutes: 360, day: '2026-11-10'),
              ],
              expenses: [
                Expense(id: 'e', label: 'Parquet', amount: 420, date: '2026-11-09'),
              ],
            ),
          ),
        ),
      ),
    );
    expect(find.text('Saisissez un taux horaire pour comparer.'), findsOneWidget);
    expect(find.text('Matériel déjà payé : 420 €'), findsOneWidget);
    await pTester.enterText(find.widgetWithText(TextField, 'Taux horaire de l\'artisan (€ TTC)'), '45');
    await pTester.pump();
    expect(find.text('Main-d\'œuvre évitée : environ 135 €'), findsOneWidget);
    expect(find.text('Soit 23 € par heure passée'), findsOneWidget);
    expect(find.textContaining('6 h pour vous, environ 135 €'), findsOneWidget);
  });

  testWidgets('devis : écart sur un poste et oublis courants', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(const QuoteCompareScreen()));
    final vFirst = find.byKey(const ValueKey('devis-0'));
    await pTester.enterText(
      find.descendant(of: vFirst, matching: find.widgetWithText(TextField, 'Nom de l\'entreprise')),
      'Alpha',
    );
    await pTester.enterText(
      find.descendant(of: vFirst, matching: find.widgetWithText(TextField, 'Main-d\'œuvre')),
      '1500',
    );
    await pTester.enterText(
      find.descendant(
        of: vFirst,
        matching: find.widgetWithText(TextField, 'Évacuation des déchets'),
      ),
      '250',
    );
    await pTester.pump();
    await pTester.tap(find.text('Devis 2'));
    await pTester.pumpAndSettle();
    final vSecond = find.byKey(const ValueKey('devis-1'));
    await pTester.enterText(
      find.descendant(of: vSecond, matching: find.widgetWithText(TextField, 'Main-d\'œuvre')),
      '2400',
    );
    await pTester.pump();
    await scrollToFirst(pTester, find.textContaining('Gros écart'));
    expect(find.text('Gros écart : 900 €, demandez ce qui est compris'), findsOneWidget);
    expect(find.textContaining('Évacuation des déchets : Alpha 250 € · Devis 2 absent'), findsOneWidget);
    expect(find.textContaining('Devis 2 ne chiffre pas : Protection des lieux'), findsOneWidget);
    expect(find.text('Ajouter un devis'), findsOneWidget);
    await pTester.tap(find.text('Ajouter un devis'));
    await pTester.pump();
    expect(find.text('Ajouter un devis'), findsNothing);
  });
}
