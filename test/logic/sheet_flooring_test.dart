import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/sheet_flooring.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('rectangle qui contient la pièce', () {
    expect(roomBox(rectangleRoom()), (lengthMm: 4000, widthMm: 3000));
    expect(roomBox(lShapedRoom()), (lengthMm: 5000, widthMm: 4000));
    expect(roomBox(const Room(id: 'v', name: 'Vide')), (lengthMm: 0, widthMm: 0));
  });

  test('un seul lé de 4 m dans le sens qui convient', () {
    final vPlan = planSheet(4000, 3000, 4000);
    // Lé posé en travers : 3,10 m de long sur 4 m de large, sans joint
    expect((vPlan.strips, vPlan.stripMm, vPlan.alongLength, vPlan.seams), (1, 3100, false, 0));
    expect(vPlan.areaM2, closeTo(12.4, 1e-9));
  });

  test('plusieurs lés : raccord du motif arrondi, sens qui économise', () {
    final vPlan = planSheet(5000, 3500, 2000, pRepeatMm: 640);
    // Dans la longueur : 2 lés de 5,10 m arrondis à 8 motifs, soit 5,12 m
    expect((vPlan.strips, vPlan.stripMm, vPlan.alongLength), (2, 5120, true));
    expect(vPlan.totalMm, 10240);
    expect(vPlan.seams, 1);
    expect(sheetGlueKg(17.5), closeTo(5.25, 1e-9));
    expect(planSheet(0, 0, 4000).strips, 0);
  });
}
