import 'package:atelier/logic/board_types.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plancher : OSB d\'abord, le moins cher qui tient', () {
    expect(boardsFor(BoardUse.floor).first, BoardType.osb);
    expect(boardsFor(BoardUse.floor), contains(BoardType.plywood));
    expect(boardsFor(BoardUse.floor), isNot(contains(BoardType.mdf)));
  });

  test('dehors : seul le contreplaqué extérieur', () {
    expect(boardsFor(BoardUse.outdoor), [BoardType.plywood]);
  });

  test('à prix égal, le panneau où la vis tient le mieux passe devant', () {
    final vFurniture = boardsFor(BoardUse.furniture);
    expect(vFurniture.first.price, 1);
    expect(vFurniture.indexOf(BoardType.blockboard), lessThan(vFurniture.indexOf(BoardType.plywood)));
  });

  test('une plaque de MDF de 19 mm se porte à deux', () {
    // 2,5 × 1,25 × 0,019 m³ × 750 kg/m³
    expect(sheetKg(BoardType.mdf, 19), closeTo(44.53, 0.01));
    expect(sheetKg(BoardType.mdf, 19), greaterThan(carryAloneKg));
    expect(sheetKg(BoardType.plywood, 5), lessThan(carryAloneKg));
  });
}
