import 'package:atelier/logic/baseboard.dart';
import 'package:atelier/logic/laying_plan.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/site_mode.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('coupe suivante : le premier morceau pas encore coupé', () {
    final vRoom = rectangleRoom();
    expect(nextBaseboardCut(vRoom)!.index, 0);
    expect(nextBaseboardCut(vRoom)!.piece.wallNumber, 1);

    final vAfter = markCut(markCut(vRoom, 0), 0);
    expect(vAfter.cutPieces, [0]);
    expect(nextBaseboardCut(vAfter)!.index, 1);

    final vCount = baseboardPieces(vRoom, vRoom.baseboard).length;
    expect(nextBaseboardCut(vRoom.copyWith(cutPieces: List.generate(vCount, (pI) => pI))), isNull);
  });

  test('rangée suivante : la première pas encore posée', () {
    final vRoom = rectangleRoom();
    expect(nextLayingRow(vRoom)!.number, 1);
    expect(nextLayingRow(markLaid(vRoom, 1))!.number, 2);

    final vRows = planLaying(vRoom, vRoom.parquet)!.rows.map((pRow) => pRow.number).toList();
    expect(nextLayingRow(vRoom.copyWith(laidRows: vRows)), isNull);
    expect(nextLayingRow(const Room(id: 'v', name: 'Vide')), isNull);
  });
}
