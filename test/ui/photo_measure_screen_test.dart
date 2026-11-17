import 'package:atelier/ui/photo_measure_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('mesure par photo : carte puis objet, retour en arrière', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(
      localized(const PhotoMeasureScreen(picture: ColoredBox(color: Colors.white))),
    );
    final vOrigin = pTester.getTopLeft(find.byKey(const ValueKey('measure-area')));
    Future<void> vTap(double pX, double pY) async {
      await pTester.tapAt(vOrigin + Offset(pX, pY));
      await pTester.pump();
    }

    await vTap(10, 10);
    await vTap(110, 10);
    expect(find.textContaining('deux bouts de ce que vous mesurez'), findsOneWidget);
    await vTap(20, 50);
    await vTap(20, 400);
    expect(find.text('30 cm environ'), findsOneWidget);

    await pTester.tap(find.byTooltip('Annuler le dernier point'));
    await pTester.pump();
    expect(find.textContaining('deux bouts de ce que vous mesurez'), findsOneWidget);
  });
}
