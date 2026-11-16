import 'package:atelier/ui/slope_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('plafond rampant : activé, réglé, puis retiré', (pTester) async {
    tallScreen(pTester);
    var vRoom = rectangleRoom();
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) => localized(
          SingleChildScrollView(
            child: SlopeEditor(room: vRoom, onChanged: (pNew) => pSetState(() => vRoom = pNew)),
          ),
        ),
      ),
    );

    await pTester.tap(find.text('Plafond rampant'));
    await pTester.pumpAndSettle();
    expect(vRoom.slope!.lowMm, 1000);
    expect(find.textContaining('où l\'on tient debout'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, 'Hauteur du côté bas (cm)'), '300');
    await pTester.pumpAndSettle();
    expect(vRoom.slope!.lowMm, 3000);
    expect(find.textContaining('plus bas que le plafond'), findsOneWidget);

    await pTester.enterText(
      find.widgetWithText(TextField, 'Largeur de la pente au sol (cm)'),
      '150',
    );
    await pTester.pumpAndSettle();
    expect(vRoom.slope!.runMm, 1500);

    await pTester.tap(find.byType(DropdownButtonFormField<int>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Mur 3').last);
    await pTester.pumpAndSettle();
    expect(vRoom.slope!.wallIndex, 2);

    await pTester.tap(find.text('Plafond rampant'));
    await pTester.pumpAndSettle();
    expect(vRoom.slope, isNull);
  });
}
