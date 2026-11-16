import 'dart:typed_data';

import 'package:atelier/logic/laser_frames.dart';
import 'package:flutter_test/flutter_test.dart';

/// Trame de mesure fictive : en-tête, compteur, erreur, puis la distance en mètres.
List<int> _frame(double pMetres) {
  final vValue = ByteData(4)..setFloat32(0, pMetres, Endian.little);

  return [0xC0, 0x55, 0x10, 0x06, 0x08, 0x02, 0x08, ...vValue.buffer.asUint8List(), 0x00, 0x3C];
}

void main() {
  test('trame relevée sur un appareil : 1,825 m', () {
    const vReal = [0xC0, 0x55, 0x10, 0x06, 0x08, 0x02, 0x08, 0xE0, 0x9C, 0xE9, 0x3F, 0x00];
    expect(laserDistanceMm(vReal), 1825);
  });

  test('distances lues au millimètre, trames étrangères ou impossibles écartées', () {
    expect(laserDistanceMm(_frame(3.214)), 3214);
    expect(laserDistanceMm(_frame(0)), isNull);
    expect(laserDistanceMm(_frame(300)), isNull);
    expect(laserDistanceMm(_frame(double.nan)), isNull);
    expect(laserDistanceMm([0xC0, 0x40, 0x00, 0xEE]), isNull);
    expect(laserDistanceMm([0x00, 0x55, 0, 0, 0, 0, 0, 0, 0, 0, 0]), isNull);
  });

  test('noms des télémètres proposés', () {
    expect(isLaserName('GLM 50 C'), isTrue);
    expect(isLaserName('plr 50 c'), isTrue);
    expect(isLaserName('Casque audio'), isFalse);
  });
}
