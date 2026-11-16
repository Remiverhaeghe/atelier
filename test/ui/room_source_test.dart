import 'package:atelier/logic/room.dart';
import 'package:atelier/ui/insulation_calculator.dart';
import 'package:atelier/ui/screed_calculator.dart';
import 'package:atelier/ui/wall_tiling_calculator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

Future<void> _pickRoom(WidgetTester pTester) async {
  await pTester.tap(find.byType(DropdownButtonFormField<String?>));
  await pTester.pumpAndSettle();
  await pTester.tap(find.text('Salon').last);
  await pTester.pumpAndSettle();
}

void main() {
  final vRooms = [rectangleRoom(), const Room(id: 'v', name: 'Vide')];

  testWidgets('ragréage : la surface vient du sol de la pièce', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(ScreedCalculator(rooms: vRooms)));
    await _pickRoom(pTester);

    expect(find.widgetWithText(TextField, '12'), findsOneWidget);
    expect(find.text('5 sacs de 25 kg'), findsOneWidget);
  });

  testWidgets('isolation : la surface suit la paroi choisie', (pTester) async {
    tallScreen(pTester);
    await pTester.pumpWidget(localized(InsulationCalculator(rooms: vRooms)));
    await _pickRoom(pTester);
    // Rampants d'une pièce sans pente : rien à isoler
    expect(find.widgetWithText(TextField, '0'), findsOneWidget);
  });

  testWidgets('faïence : largeur, hauteur et fenêtre reprises du mur', (pTester) async {
    tallScreen(pTester);
    final vRoom = rectangleRoom().copyWith(
      walls: [
        const Wall(
          lengthMm: 4000,
          openings: [Opening(kind: OpeningKind.window, offsetMm: 1000, widthMm: 1200)],
        ),
        ...rectangleRoom().walls.skip(1),
      ],
    );
    await pTester.pumpWidget(localized(WallTilingCalculator(rooms: [vRoom])));
    await _pickRoom(pTester);

    expect(find.widgetWithText(TextField, '400'), findsOneWidget);
    expect(find.widgetWithText(TextField, '120'), findsOneWidget);
    // Crédence par défaut : la hauteur reste celle de la crédence
    expect(find.widgetWithText(TextField, '60'), findsOneWidget);

    await pTester.tap(find.text('Posée sur un plan de travail'));
    await pTester.pumpAndSettle();
    await pTester.tap(find.byType(DropdownButtonFormField<int>));
    await pTester.pumpAndSettle();
    await pTester.tap(find.text('Mur 2').last);
    await pTester.pumpAndSettle();
    expect(find.widgetWithText(TextField, '300'), findsOneWidget);
    expect(find.widgetWithText(TextField, '250'), findsOneWidget);
  });
}
