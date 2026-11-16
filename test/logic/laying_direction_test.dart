import 'package:atelier/logic/laying_direction.dart';
import 'package:atelier/logic/parquet.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  const vSettings = ParquetSettings();

  test('pièce rectangulaire : deux sens, celui de la longueur conseillé', () {
    final vDirections = layingDirections(rectangleRoom(), vSettings);

    expect(vDirections, hasLength(2));
    expect(vDirections.first.wallIndex, 0);
    expect(vDirections.first.wallsLengthMm, 8000);
    expect(vDirections.first.recommended, isTrue);
    expect(vDirections.first.rowCount, 16);
    expect(vDirections.last.wallIndex, 1);
    expect(vDirections.last.recommended, isFalse);
    expect(vDirections.last.rowCount, greaterThan(16));
  });

  test('pièce en L : le mur de référence est le plus long de sa direction', () {
    final vDirections = layingDirections(lShapedRoom(), vSettings);

    expect(vDirections, hasLength(2));
    expect(vDirections.first.wallIndex, 0);
    expect(vDirections.last.wallIndex, 5);
  });

  test('le sens choisi suit le mur de pose réglé', () {
    final vRoom = rectangleRoom();
    final vDirections = layingDirections(vRoom, vSettings);

    expect(selectedDirection(vRoom, vDirections, 2), 0);
    expect(selectedDirection(vRoom, vDirections, 3), 1);
  });

  test('pas de sens de pose sans pièce fermée', () {
    expect(layingDirections(const Room(id: 'r', name: 'R'), vSettings), isEmpty);
  });
}
