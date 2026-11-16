import 'package:atelier/logic/conditions.dart';
import 'package:atelier/logic/units.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('point de rosée : 20 °C et 50 % donnent environ 9,3 °C', () {
    expect(dewPointC(20, 50), closeTo(9.26, 0.05));
    expect(dewPointC(10, 100), closeTo(10, 0.01));
  });

  test('peinture acrylique : froid, humidité et condensation', () {
    expect(checkConditions(SiteProduct.acrylicPaint, pAirC: 18, pHumidity: 55), isEmpty);
    expect(
      checkConditions(SiteProduct.acrylicPaint, pAirC: 6, pHumidity: 60),
      [ConditionIssue.tooCold],
    );
    expect(
      checkConditions(SiteProduct.acrylicPaint, pAirC: 20, pHumidity: 85),
      [ConditionIssue.tooHumid, ConditionIssue.condensation],
    );
    // Mur froid : 11 °C quand le point de rosée est à 9,3 °C
    expect(
      checkConditions(SiteProduct.acrylicPaint, pAirC: 20, pHumidity: 50, pSurfaceC: 11),
      [ConditionIssue.condensation],
    );
  });

  test('parquet : air trop sec ou trop chaud, mastic peu exigeant', () {
    expect(
      checkConditions(SiteProduct.parquetGlue, pAirC: 28, pHumidity: 30),
      [ConditionIssue.tooHot, ConditionIssue.tooDry],
    );
    expect(checkConditions(SiteProduct.sealant, pAirC: 35, pHumidity: 95), isEmpty);
    expect(SiteProduct.sealant.dewSensitive, isFalse);
  });

  test('températures négatives saisies', () {
    expect(parseSignedDecimal('-2,5'), -2.5);
    expect(parseSignedDecimal('−4'), -4);
    expect(parseSignedDecimal('12'), 12);
    expect(parseSignedDecimal('-'), isNull);
  });
}
