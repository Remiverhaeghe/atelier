import 'package:atelier/logic/baseboard.dart';
import 'package:atelier/ui/angle_dialog.dart';
import 'package:atelier/ui/cut_diagram.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';

void main() {
  testWidgets('trois mesures donnent l\'angle du coin, repris par le bouton', (pTester) async {
    double? vResult;
    await pTester.pumpWidget(
      localized(
        Builder(
          builder: (pContext) => TextButton(
            onPressed: () async => vResult = await measureCornerAngle(pContext),
            child: const Text('mesurer'),
          ),
        ),
      ),
    );
    await pTester.tap(find.text('mesurer'));
    await pTester.pumpAndSettle();

    await pTester.enterText(find.byType(TextField).at(2), '120');
    await pTester.pump();
    expect(find.textContaining('ne forment pas un triangle'), findsOneWidget);

    await pTester.enterText(find.byType(TextField).at(2), '69,5');
    await pTester.pump();
    expect(find.text('Angle du coin : 88°'), findsOneWidget);

    await pTester.tap(find.byType(Switch));
    await pTester.pump();
    expect(find.text('Angle du coin : 272°'), findsOneWidget);

    await pTester.tap(find.text('Utiliser cet angle'));
    await pTester.pumpAndSettle();
    expect(vResult, 272);
  });

  testWidgets('le schéma de coupe donne la longueur et l\'angle de chaque bout', (pTester) async {
    await pTester.pumpWidget(
      localized(
        const CutDiagram(
          piece: BaseboardPiece(
            wallNumber: 1,
            lengthMm: 4000,
            startCut: EndCut(EndCutKind.insideMiter, 45),
            endCut: EndCut(EndCutKind.outsideMiter, 46),
          ),
        ),
      ),
    );

    expect(find.text('Dos, contre le guide de la scie'), findsOneWidget);
    expect(find.text('Face, vers toi'), findsOneWidget);
  });
}
