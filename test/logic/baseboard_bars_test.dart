import 'package:atelier/logic/baseboard.dart';
import 'package:atelier/logic/baseboard_bars.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/site_mode.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('les coupes se suivent barre par barre, chaque morceau une seule fois', () {
    var vRoom = rectangleRoom();
    final vPieces = baseboardPieces(vRoom, vRoom.baseboard);
    final vBars = planBaseboardBars(vPieces, vRoom.baseboard);
    final vSeen = <int>[];
    final vBarsSeen = <int?>[];
    for (var vStep = 0; vStep < vPieces.length; vStep++) {
      final vCut = nextBaseboardCut(vRoom)!;
      vSeen.add(vCut.index);
      vBarsSeen.add(vCut.bar);
      vRoom = markCut(vRoom, vCut.index);
    }

    expect(vSeen.toSet(), {for (var vIndex = 0; vIndex < vPieces.length; vIndex++) vIndex});
    expect(nextBaseboardCut(vRoom), isNull);
    // Une barre n'est quittée qu'une fois ses morceaux tous coupés
    final vChanges = [
      for (var vIndex = 1; vIndex < vBarsSeen.length; vIndex++)
        if (vBarsSeen[vIndex] != vBarsSeen[vIndex - 1]) vBarsSeen[vIndex],
    ];
    expect(vChanges.toSet().length, vChanges.length);
    expect(vBarsSeen.whereType<int>().toSet(), {for (var v = 1; v <= vBars.bars.length; v++) v});
  });

  test('la coupe suivante dit ce qui reste dans la barre et sa chute', () {
    final vRoom = rectangleRoom();
    final vCut = nextBaseboardCut(vRoom)!;
    final vBars = planBaseboardBars(
      baseboardPieces(vRoom, vRoom.baseboard),
      vRoom.baseboard,
    );

    expect(vCut.bar, 1);
    expect(vCut.leftInBar, hasLength(vBars.bars.first.pieceIndexes.length));
    expect(vCut.leftInBar.first.lengthMm, vCut.piece.lengthMm);
    expect(vCut.offcutMm, vBars.bars.first.offcutMm(vBars.kerfMm));

    final vNext = nextBaseboardCut(markCut(vRoom, vCut.index))!;
    if (vCut.leftInBar.length > 1) {
      expect(vNext.bar, 1);
      expect(vNext.leftInBar, hasLength(vCut.leftInBar.length - 1));
    }
  });

  test('une pièce sans mur n\'a rien à couper', () {
    expect(nextBaseboardCut(const Room(id: 'r', name: 'R')), isNull);
  });
}
