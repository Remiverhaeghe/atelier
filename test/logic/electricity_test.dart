import 'package:atelier/logic/electricity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('minimums par pièce : séjour selon sa surface, chambre, cuisine, salle de bain', () {
    expect(minSockets(const ElecRoom(kind: ElecRoomKind.living, areaM2: 15)), 5);
    expect(minSockets(const ElecRoom(kind: ElecRoomKind.living, areaM2: 30)), 8);
    expect(minSockets(const ElecRoom(kind: ElecRoomKind.bedroom)), 3);
    expect(minSockets(const ElecRoom(kind: ElecRoomKind.kitchen)), 6);
    expect(minSockets(const ElecRoom(kind: ElecRoomKind.bathroom)), 1);
    expect(minSockets(const ElecRoom(kind: ElecRoomKind.hallway)), 1);
    expect(minSockets(const ElecRoom(kind: ElecRoomKind.toilet)), 0);
  });

  test('installation : prises, points, boîtes, gaine et fil', () {
    final vNeeds = elecNeeds(const [
      ElecRoom(kind: ElecRoomKind.living, areaM2: 24),
      ElecRoom(kind: ElecRoomKind.kitchen),
      ElecRoom(kind: ElecRoomKind.toilet),
    ]);

    expect(vNeeds.sockets, 12);
    expect(vNeeds.lights, 3);
    expect(vNeeds.switches, 3);
    expect(vNeeds.boxes, 18);
    expect(vNeeds.dedicated, 5);
    // 20 lignes de 10 m, 10 % de marge
    expect(vNeeds.conduitMetres, 220);
    expect(vNeeds.wireMetres, 660);
    expect(elecNeeds(const []).boxes, 0);
  });
}
