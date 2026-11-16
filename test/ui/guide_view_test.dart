import 'dart:io';

import 'package:atelier/logic/parquet.dart';
import 'package:atelier/support/crash_log.dart';
import 'package:atelier/ui/about_screen.dart';
import 'package:atelier/ui/guide_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized.dart';
import '../support/rooms.dart';

void main() {
  testWidgets('les étapes se cochent, les outils suivent le type de parquet', (pTester) async {
    var vRoom = rectangleRoom().copyWith(parquet: ParquetSettings.forType(ParquetType.glued));
    await pTester.pumpWidget(
      StatefulBuilder(
        builder: (pContext, pSetState) =>
            localized(GuideView(room: vRoom, onChanged: (pRoom) => pSetState(() => vRoom = pRoom))),
      ),
    );

    expect(find.text('Spatule crantée'), findsOneWidget);
    expect(find.text('Aucune étape faite sur 13'), findsOneWidget);

    await scrollToFirst(pTester, find.byType(Checkbox));
    await pTester.tap(find.byType(Checkbox).first);
    await pTester.pump();

    expect(vRoom.doneSteps, ['acclimatise']);
  });

  testWidgets('À propos : journal vide, puis bouton de partage', (pTester) async {
    await pTester.pumpWidget(localized(const AboutScreen()));
    expect(find.text('Aucun plantage enregistré.'), findsOneWidget);

    final vFolder = Directory.systemTemp.createTempSync('atelier_');
    addTearDown(() => vFolder.deleteSync(recursive: true));
    final vLog = CrashLog(File('${vFolder.path}/plantages.txt'))..record('panne', null);
    await pTester.pumpWidget(localized(AboutScreen(crashLog: vLog)));

    expect(find.text('Partager le journal'), findsOneWidget);
  });
}
