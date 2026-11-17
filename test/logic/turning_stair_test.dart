import 'package:atelier/logic/turning_stair.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('escalier droit : une seule volée, aucune marche balancée', () {
    final vStair = designTurningStair(2800, StairShape.straight);

    expect(vStair.walkingLineMm, 4200);
    expect(vStair.footprintLengthMm, 4200);
    expect(vStair.footprintWidthMm, 800);
    expect(vStair.balancedTreads, 0);
  });

  test('quart tournant : deux marches dans le tournant, emprise en L', () {
    final vStair = designTurningStair(2800, StairShape.quarterTurn);

    expect(vStair.turningTreads, 2);
    expect(vStair.firstFlightMm, 1680);
    expect(vStair.secondFlightMm, 1960);
    expect(vStair.footprintLengthMm, 2480);
    expect(vStair.footprintWidthMm, 2760);
    expect(vStair.balancedTreads, 6);
  });

  test('demi-tournant : deux volées côte à côte', () {
    final vStair = designTurningStair(2800, StairShape.halfTurn);

    expect(vStair.turningTreads, 4);
    expect(vStair.footprintLengthMm, 2480);
    expect(vStair.footprintWidthMm, 1600);
    expect(vStair.balancedTreads, 8);
  });

  test('plus large : plus de marches dans le tournant', () {
    expect(designTurningStair(2443, StairShape.quarterTurn, pWidthMm: 900).turningTreads, 3);
  });
}
