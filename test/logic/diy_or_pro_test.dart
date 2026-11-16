import 'package:atelier/logic/diy_or_pro.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('économie par heure, débutant compté double', () {
    final vVerdict = compareDiy((
      quoteEuros: 2400,
      materialEuros: 900,
      toolsEuros: 100,
      hours: 14,
      beginner: true,
      aidsNeedPro: false,
      aidEuros: 0,
    ));
    expect(vVerdict.diyEuros, 1000);
    expect(vVerdict.savingEuros, 1400);
    expect(vVerdict.realHours, 28);
    expect(vVerdict.savingPerHour, 50);
  });

  test('les aides réservées aux artisans RGE baissent le devis, jamais sous zéro', () {
    final vVerdict = compareDiy((
      quoteEuros: 3000,
      materialEuros: 1200,
      toolsEuros: 0,
      hours: 0,
      beginner: false,
      aidsNeedPro: true,
      aidEuros: 2000,
    ));
    expect(vVerdict.proEuros, 1000);
    expect(vVerdict.savingEuros, -200);
    expect(vVerdict.savingPerHour, 0);

    final vFree = compareDiy((
      quoteEuros: 500,
      materialEuros: 100,
      toolsEuros: 0,
      hours: 4,
      beginner: false,
      aidsNeedPro: true,
      aidEuros: 900,
    ));
    expect(vFree.proEuros, 0);
  });
}
