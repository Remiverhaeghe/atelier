import 'package:atelier/logic/heating.dart';
import 'package:atelier/logic/large_room_heating.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('séjour cathédrale de 8 × 6 m sous 5 m : pertes en hauteur, deux brasseurs, poêle', () {
    final vHeat = heatLargeRoom(
      pLengthMm: 8000,
      pWidthMm: 6000,
      pHeightMm: 5000,
      pLevel: InsulationLevel.good,
    );
    // 240 m³ × 1 × 26 K = 6240 W, plus 5 % par mètre au-delà de 2,50 m
    expect(vHeat.stratificationWatts, 780);
    expect(vHeat.watts, 7020);
    expect(vHeat.fans, 2);
    expect(vHeat.fanDiameterMm, 1320);
    expect(vHeat.stoveKw, 8);
    expect(vHeat.preferRadiant, isTrue);
    expect(vHeat.radiators, [2000, 2000, 2000, 2000]);
  });

  test('pièce ordinaire : ni brasseur ni pertes en hauteur', () {
    final vHeat = heatLargeRoom(
      pLengthMm: 5000,
      pWidthMm: 4000,
      pHeightMm: 2500,
      pLevel: InsulationLevel.average,
    );
    expect(vHeat.watts, 1820);
    expect(vHeat.stratificationWatts, 0);
    expect(vHeat.fans, 0);
    expect(vHeat.fanDiameterMm, 0);
    expect(vHeat.stoveKw, 4);
    expect(vHeat.preferRadiant, isFalse);
  });

  test('très grand volume : le plus gros poêle courant', () {
    final vHeat = heatLargeRoom(
      pLengthMm: 15000,
      pWidthMm: 10000,
      pHeightMm: 6000,
      pLevel: InsulationLevel.poor,
    );
    expect(vHeat.stoveKw, 14);
    expect(vHeat.fans, 4);
    expect(vHeat.fanDiameterMm, 1520);
  });

  test('diamètre du brasseur selon le sol couvert', () {
    expect(fanDiameterFor(12), 1070);
    expect(fanDiameterFor(20), 1320);
    expect(fanDiameterFor(30), 1520);
  });
}
