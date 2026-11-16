import 'package:atelier/l10n/gen/app_localizations_fr.dart';
import 'package:atelier/logic/baseboard.dart';
import 'package:atelier/logic/cut_list.dart';
import 'package:atelier/logic/laying_plan.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/ui/cut_list_pdf.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('plinthes : tous les morceaux, regroupés, du plus long au plus court', () {
    final vRoom = rectangleRoom();
    final vLines = baseboardCutList(vRoom);
    final vPieces = baseboardPieces(vRoom, vRoom.baseboard);

    expect(vLines.fold(0, (pSum, pLine) => pSum + pLine.count), vPieces.length);
    expect(vLines.length, lessThan(vPieces.length));
    for (var vIndex = 1; vIndex < vLines.length; vIndex++) {
      expect(vLines[vIndex - 1].lengthMm, greaterThanOrEqualTo(vLines[vIndex].lengthMm));
    }
    // Les deux murs de 3 m donnent le même morceau, aux mêmes coupes
    final vShort = vLines.firstWhere((pLine) => pLine.places.contains(2));
    expect(vShort.places, [2, 4]);
    expect(vShort.count, 2);
    expect(vShort.startCut!.kind, EndCutKind.insideMiter);
  });

  test('parquet : seules les lames recoupées, par rangée', () {
    final vRoom = rectangleRoom();
    final vLines = plankCutList(vRoom);
    final vPlan = planLaying(vRoom, vRoom.parquet)!;
    final vCut = [
      for (final vRow in vPlan.rows)
        for (final vRun in vRow.runs)
          for (final vPiece in vRun.pieces)
            if (vPiece != vRoom.parquet.plankLengthMm) vPiece,
    ];

    expect(vLines.fold(0, (pSum, pLine) => pSum + pLine.count), vCut.length);
    expect(vLines.every((pLine) => pLine.lengthMm != vRoom.parquet.plankLengthMm), isTrue);
    expect(vLines.first.startCut, isNull);
    expect(plankCutList(const Room(id: 'v', name: 'Vide')), isEmpty);
  });

  test('la liste de coupes se construit en PDF, pièce vide comprise', () async {
    final vText = AppLocalizationsFr();
    for (final vRoom in [rectangleRoom(), const Room(id: 'v', name: 'Vide')]) {
      final vBytes = await buildCutListPdf(vText, vRoom);
      expect(String.fromCharCodes(vBytes.take(5)), '%PDF-');
    }
  });
}
