import 'package:atelier/logic/diagonal.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('diagonale du plan et écart avec la mesure', () {
    expect(planDiagonalMm(rectangleRoom()), closeTo(5000, 1e-6));
    expect(diagonalGapMm(rectangleRoom(), 5030), closeTo(30, 1e-6));
    expect(planDiagonalMm(const Room(id: 'v', name: 'Vide')), isNull);
    expect(diagonalGapMm(const Room(id: 'v', name: 'Vide'), 5000), isNull);
  });

  test('vrais angles d\'une pièce pas d\'équerre, retrouvés par la diagonale', () {
    expect(anglesFromDiagonal(rectangleRoom(), 5000), [90, 90, 90, 90]);
    // 5,10 m au lieu de 5 m : les coins B et D s'ouvrent, A et C se ferment
    expect(anglesFromDiagonal(rectangleRoom(), 5100), [92.5, 87.5, 92.5, 87.5]);
  });

  test('diagonale impossible ou pièce qui n\'a pas quatre murs', () {
    expect(anglesFromDiagonal(rectangleRoom(), 8000), isNull);
    expect(anglesFromDiagonal(rectangleRoom(), 900), isNull);
    expect(anglesFromDiagonal(lShapedRoom(), 5000), isNull);
    expect(anglesFromDiagonal(rectangleRoom().copyWith(closed: false), 5000), isNull);
  });

  test('murs opposés différents dans une pièce saisie d\'équerre', () {
    expect(oppositeMismatches(rectangleRoom()), isEmpty);
    final vWalls = [...rectangleRoom().walls]..[2] = const Wall(lengthMm: 4030);
    expect(oppositeMismatches(rectangleRoom().copyWith(walls: vWalls)), [
      (first: 1, second: 3, gapMm: 30),
    ]);
    expect(oppositeMismatches(lShapedRoom()), isEmpty);
    final vSkewed = [...vWalls]..[0] = const Wall(lengthMm: 4000, angleToNextDeg: 92);
    expect(oppositeMismatches(rectangleRoom().copyWith(walls: vSkewed)), isEmpty);
  });
}
