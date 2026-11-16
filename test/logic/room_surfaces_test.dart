import 'package:atelier/logic/insulation.dart';
import 'package:atelier/logic/paint.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/room_surfaces.dart';
import 'package:atelier/logic/slope.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

final _attic = rectangleRoom().copyWith(slope: const Slope(wallIndex: 0, lowMm: 1000, runMm: 2000));

void main() {
  test('surfaces à isoler reprises du plan', () {
    // 8 m² au sol sous la pente, allongés de 1,25 par l'inclinaison
    expect(slopedCeilingM2(_attic), closeTo(10, 1e-6));
    expect(insulationAreaM2(_attic, InsulatedPart.rafters), closeTo(10, 1e-6));
    expect(insulationAreaM2(_attic, InsulatedPart.lostAttic), closeTo(12, 1e-9));
    expect(insulationAreaM2(_attic, InsulatedPart.floor), closeTo(12, 1e-9));
    expect(insulationAreaM2(_attic, InsulatedPart.walls), paintAreas(_attic).wallsM2);
    expect(slopedCeilingM2(rectangleRoom()), 0);
    expect(insulationAreaM2(const Room(id: 'v', name: 'Vide'), InsulatedPart.walls), 0);
  });

  test('pan de mur pour la faïence, hauteur prise sous la pente', () {
    expect(wallPanel(rectangleRoom(), 1), (widthMm: 3000, heightMm: 2500));
    expect(wallPanel(_attic, 1), (widthMm: 3000, heightMm: 2125));
    expect(wallPanel(_attic, 9), isNull);
  });
}
