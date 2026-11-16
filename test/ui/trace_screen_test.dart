import 'package:atelier/logic/room.dart';
import 'package:atelier/ui/trace_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('décalque : une cote pour l\'échelle, quatre coins, quatre murs', (pTester) async {
    tallScreen(pTester);
    List<Wall>? vResult;
    await pTester.pumpWidget(
      localized(
        Builder(
          builder: (pContext) => TextButton(
            onPressed: () async => vResult = await Navigator.push<List<Wall>>(
              pContext,
              MaterialPageRoute(
                builder: (_) => const TraceScreen(picture: ColoredBox(color: Colors.white)),
              ),
            ),
            child: const Text('ouvrir'),
          ),
        ),
      ),
    );
    await pTester.tap(find.text('ouvrir'));
    await pTester.pumpAndSettle();
    expect(find.textContaining('deux bouts d\'une cote'), findsOneWidget);

    final vOrigin = pTester.getTopLeft(find.byKey(const ValueKey('trace-area')));
    Future<void> vTap(double pX, double pY) async {
      await pTester.tapAt(vOrigin + Offset(pX, pY));
      await pTester.pump();
    }

    await pTester.enterText(find.byType(TextField), '4000');
    await vTap(20, 20);
    await vTap(220, 20);
    expect(find.textContaining('coins de la pièce'), findsOneWidget);

    // Un coin de trop, retiré avec « Annuler »
    for (final (vX, vY) in [
      (20.0, 20.0),
      (220.0, 20.0),
      (220.0, 170.0),
      (20.0, 170.0),
      (5.0, 5.0),
    ]) {
      await vTap(vX, vY);
    }
    await pTester.tap(find.byTooltip('Annuler le dernier point'));
    await pTester.pump();
    expect(find.text('4 murs : 400 · 300 · 400 · 300 cm'), findsOneWidget);

    await pTester.tap(find.text('Créer les murs'));
    await pTester.pumpAndSettle();
    expect([for (final vWall in vResult!) vWall.angleToNextDeg], [90, 90, 90, 90]);
  });
}
