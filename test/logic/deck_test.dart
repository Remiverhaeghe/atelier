import 'package:atelier/logic/deck.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('terrasse de 4 × 3 m en lames de 145 × 27 mm', () {
    final vNeeds = deckNeeds(const DeckDesign());

    expect(vNeeds.areaM2, 12);
    expect(vNeeds.rows, 20);
    expect(vNeeds.boards, 35);
    expect(vNeeds.joistSpacingMm, 540);
    expect(vNeeds.joists, 9);
    expect(vNeeds.joistBars, 7);
    expect(vNeeds.plots, 54);
    expect(vNeeds.screws, 360);
  });

  test('une lame plus épaisse écarte les lambourdes ; rien sans surface', () {
    expect(deckNeeds(const DeckDesign(boardThicknessMm: 21)).joistSpacingMm, 420);
    expect(deckNeeds(const DeckDesign(widthMm: 0)).boards, 0);
    expect(deckNeeds(const DeckDesign(boardLengthMm: 0, joistLengthMm: 0)).boards, 0);
    expect(const DeckDesign().copyWith(gapMm: 7).gapMm, 7);
  });
}
