import 'package:atelier/logic/touch_up.dart';
import 'package:atelier/ui/touch_ups_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('modèle « Rafraîchir une pièce » : étapes ajoutées sans doubler', (pTester) async {
    tallScreen(pTester);
    var vRoom = rectangleRoom().copyWith(
      touchUps: const [TouchUp(id: 'p', label: 'Peindre les murs', passes: 2)],
    );
    await pTester.pumpWidget(
      localized(
        Scaffold(
          body: TouchUpsView(room: vRoom, onChanged: (pRoom) => vRoom = pRoom),
        ),
      ),
    );
    await pTester.ensureVisible(find.text('Ajouter un modèle'));
    await pTester.tap(find.text('Ajouter un modèle'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Rafraîchir une pièce'));
    await pTester.pumpAndSettle();

    final vLabels = vRoom.touchUps.map((pTouchUp) => pTouchUp.label).toList();
    expect(vLabels.where((pLabel) => pLabel == 'Peindre les murs'), hasLength(1));
    expect(vLabels, containsAll(['Reboucher les trous', 'Sous-couche', 'Peindre le plafond']));
    final vFill = vRoom.touchUps.firstWhere((pTouchUp) => pTouchUp.label == 'Reboucher les trous');
    expect(vFill.passes, 2);
  });
}
