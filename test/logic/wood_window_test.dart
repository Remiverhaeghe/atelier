import 'package:atelier/logic/wood_window.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('châssis de 80 × 100 cm en bois de 58 × 70 mm', () {
    final vWindow = planWoodWindow(pWidthMm: 800, pHeightMm: 1000);
    expect((vWindow.outerWidthMm, vWindow.outerHeightMm), (790, 990));
    expect(vWindow.stileLengthMm, 990);
    // 58 × 2/3 = 39 mm de tenon à chaque bout de la traverse
    expect(vWindow.tenonLengthMm, 39);
    expect(vWindow.railLengthMm, 674 + 78);
    expect(vWindow.tenonThicknessMm, 23);
    expect((vWindow.daylightWidthMm, vWindow.daylightHeightMm), (674, 874));
    expect((vWindow.glassWidthMm, vWindow.glassHeightMm), (702, 902));
    expect(vWindow.glassKg, closeTo(12.66, 0.01));
    expect(vWindow.rebateWidthMm, 45);
    expect(vWindow.beadLengthMm, 3208);
    expect(vWindow.frameTooThin, isFalse);
  });

  test('un bois trop mince pour garder du bois devant la feuillure', () {
    final vWindow = planWoodWindow(pWidthMm: 600, pHeightMm: 600, pFrameDepthMm: 58);
    expect(vWindow.frameTooThin, isTrue);
  });

  test('ouverture plus petite que le cadre : pas de dimension négative', () {
    final vWindow = planWoodWindow(pWidthMm: 100, pHeightMm: 100);
    expect(vWindow.daylightWidthMm, 0);
    expect(vWindow.glassKg, closeTo(28 * 28 / 1e6 * 20, 1e-9));
  });
}
