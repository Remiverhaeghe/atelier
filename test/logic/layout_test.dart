import 'package:atelier/logic/layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('colonnes selon la largeur, bornées', () {
    expect(gridColumns(390, 180, pMin: 2), 2);
    expect(gridColumns(1280, 180, pMin: 2), 7);
    expect(gridColumns(3000, 90, pMin: 4, pMax: 8), 8);
    expect(gridColumns(300, 90, pMin: 4), 4);
    expect(gridColumns(500, 0, pMin: 3), 3);
  });

  test('plan et liste côte à côte sur tablette ou en paysage', () {
    expect(isWideWidth(390), isFalse);
    expect(isWideWidth(900), isTrue);
  });
}
