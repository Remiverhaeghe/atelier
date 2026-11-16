import 'package:atelier/logic/parquet.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/ui/parquet_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('les quantités suivent la saisie', (pTester) async {
    tallScreen(pTester);
    var vRoom = rectangleRoom();
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) => localized(
          ParquetView(room: vRoom, onChanged: (pRoom) => pSetState(() => vRoom = pRoom)),
        ),
      ),
    );

    expect(find.text('6 paquets'), findsOneWidget);
    expect(find.text('1 rouleau de sous-couche'), findsOneWidget);
    expect(find.textContaining('16 rangées'), findsWidgets);

    await pTester.enterText(find.widgetWithText(TextField, "Surface d'un paquet (m²)"), '1,5');
    await pTester.pump();

    expect(vRoom.parquet.packAreaM2, 1.5);
    expect(find.text('9 paquets'), findsOneWidget);

    await pTester.enterText(find.widgetWithText(TextField, "Surface d'un paquet (m²)"), 'abc');
    await pTester.pump();
    expect(find.text('Nombre invalide.'), findsOneWidget);
    expect(vRoom.parquet.packAreaM2, 1.5);
  });

  testWidgets('point de Hongrie : lames gauches et droites, pas de rangées', (pTester) async {
    final vRoom = rectangleRoom().copyWith(
      parquet: ParquetSettings.forType(ParquetType.herringbone),
    );
    await pTester.pumpWidget(localized(ParquetView(room: vRoom, onChanged: (_) {})));

    expect(find.textContaining('lames gauches'), findsOneWidget);
    expect(find.textContaining('le plan rangée par rangée ne s\'applique pas'), findsOneWidget);
  });

  testWidgets('sans murs, la vue demande de saisir la pièce', (pTester) async {
    await pTester.pumpWidget(
      localized(
        ParquetView(
          room: const Room(id: 'r', name: 'R'),
          onChanged: (_) {},
        ),
      ),
    );

    expect(find.textContaining('au moins trois murs'), findsOneWidget);
  });

  testWidgets('le sens de pose se choisit en touchant son image', (pTester) async {
    tallScreen(pTester);
    var vRoom = rectangleRoom();
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) => localized(
          ParquetView(room: vRoom, onChanged: (pRoom) => pSetState(() => vRoom = pRoom)),
        ),
      ),
    );

    expect(find.text('Le long du mur 1'), findsOneWidget);
    expect(find.text('Conseillé'), findsOneWidget);
    await pTester.tap(find.text('Le long du mur 2'));
    await pTester.pump();

    expect(vRoom.parquet.layingWallIndex, 1);
    expect(find.textContaining('21 rangées'), findsWidgets);
  });
}
