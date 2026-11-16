import 'package:atelier/logic/level.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inclinaison : à plat, debout, et rampant de 3 sur 4', () {
    expect(tiltDeg((x: 0, y: 0, z: 9.81)), closeTo(0, 1e-9));
    expect(tiltDeg((x: 0, y: 9.81, z: 0)), closeTo(90, 1e-9));
    expect(tiltDeg((x: 0, y: 5.886, z: 7.848)), closeTo(36.87, 0.01));
    // Écran vers le bas : même inclinaison
    expect(tiltDeg((x: 0, y: 5.886, z: -7.848)), closeTo(36.87, 0.01));
  });

  test('bulle : inclinaison sur chaque axe', () {
    final vBubble = bubble((x: 0.5, y: -0.2, z: 9.8));

    expect(vBubble.acrossDeg, closeTo(2.92, 0.01));
    expect(vBubble.alongDeg, closeTo(-1.17, 0.01));
  });

  test('pente en pour cent, moyenne des mesures', () {
    expect(slopePercent(45), closeTo(100, 1e-9));
    expect(slopePercent(0.573), closeTo(1, 0.001));
    final vAverage = averageGravity(const [(x: 1, y: 0, z: 9), (x: -1, y: 2, z: 11)]);
    expect((vAverage.x, vAverage.y, vAverage.z), (0.0, 1.0, 10.0));
    expect(averageGravity(const []).z, 9.81);
  });

  test('largeur au sol d\'un rampant d\'après son angle', () {
    expect(runFromAngle(pAngleDeg: 36.87, pLowMm: 1000, pHighMm: 2500), 2000);
    expect(runFromAngle(pAngleDeg: 0.2, pLowMm: 1000, pHighMm: 2500), isNull);
    expect(runFromAngle(pAngleDeg: 30, pLowMm: 2500, pHighMm: 2500), isNull);
  });
}
