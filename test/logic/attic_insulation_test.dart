import 'package:atelier/logic/attic_insulation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    '20 cm sous les rampants et 10 cm contre les jambettes : 17 % de surface debout en moins',
    () {
      final vResult = insulateAttic(
        pWidthMm: 6000,
        pLengthMm: 4200,
        pKneeWallMm: 800,
        pSlopeDeg: 40,
        pTwoPitches: true,
        pSlopeInsulationMm: 200,
        pKneeInsulationMm: 100,
      );
      expect(vResult.usableBeforeM2, closeTo(15.19, 0.01));
      expect(vResult.usableAfterM2, closeTo(12.58, 0.01));
      expect(vResult.lostM2, closeTo(2.61, 0.01));
      expect(vResult.lostPercent, 17);
      // 0,20 m ÷ 0,035 W/m·K
      expect(vResult.rValue, closeTo(5.71, 0.01));
      // La jambette paraît plus basse : 80 + 10 × tan 40° − 20 ÷ cos 40°
      expect(vResult.after.topMm, lessThan(3317));
    },
  );

  test('sans isolant ajouté, rien n\'est perdu', () {
    final vResult = insulateAttic(
      pWidthMm: 6000,
      pLengthMm: 4200,
      pKneeWallMm: 800,
      pSlopeDeg: 40,
      pTwoPitches: false,
      pSlopeInsulationMm: 0,
      pKneeInsulationMm: 0,
      pCeilingMm: 2500,
    );
    expect(vResult.lostM2, 0);
    expect(vResult.lostPercent, 0);
    expect(vResult.rValue, 0);
  });

  test('pièce trop basse pour se tenir debout : pas de pourcentage', () {
    final vResult = insulateAttic(
      pWidthMm: 2000,
      pLengthMm: 3000,
      pKneeWallMm: 300,
      pSlopeDeg: 30,
      pTwoPitches: true,
      pSlopeInsulationMm: 200,
      pKneeInsulationMm: 100,
    );
    expect(vResult.usableBeforeM2, 0);
    expect(vResult.lostPercent, 0);
  });
}
