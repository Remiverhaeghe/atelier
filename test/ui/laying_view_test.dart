import 'package:atelier/logic/parquet.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/ui/laying_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('les rangées se cochent et la progression suit', (pTester) async {
    var vRoom = rectangleRoom();
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) => localized(
          LayingView(room: vRoom, onChanged: (pRoom) => pSetState(() => vRoom = pRoom)),
        ),
      ),
    );

    expect(find.textContaining('16 rangées, 54 lames'), findsOneWidget);
    expect(find.text('138 + 138 + 122,4 cm'), findsOneWidget);
    expect(find.text('Aucune rangée posée sur 16'), findsOneWidget);

    await pTester.tap(find.byType(Checkbox).first);
    await pTester.pump();

    expect(vRoom.laidRows, [1]);
    expect(find.text('1 rangée posée sur 16'), findsOneWidget);

    await pTester.tap(find.byType(Checkbox).first);
    await pTester.pump();
    expect(vRoom.laidRows, isEmpty);
  });

  testWidgets('rangées à vérifier signalées', (pTester) async {
    final vRoom = const Room(
      id: 'r',
      name: 'Couloir',
      walls: [Wall(lengthMm: 4000), Wall(lengthMm: 595), Wall(lengthMm: 4000), Wall(lengthMm: 595)],
    ).copyWith(parquet: const ParquetSettings(plankLengthMm: 600));
    await pTester.pumpWidget(localized(LayingView(room: vRoom, onChanged: (_) {})));

    expect(find.text('1 rangée à vérifier à la main'), findsOneWidget);
  });

  testWidgets('point de Hongrie : pas de plan', (pTester) async {
    final vRoom = rectangleRoom().copyWith(
      parquet: ParquetSettings.forType(ParquetType.herringbone),
    );
    await pTester.pumpWidget(localized(LayingView(room: vRoom, onChanged: (_) {})));

    expect(find.textContaining('lames droites'), findsOneWidget);
  });
}
