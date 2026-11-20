import 'package:atelier/logic/geometry.dart';
import 'package:atelier/logic/photo_measure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('la carte donne l\'échelle de la photo', () {
    // Carte de 100 points de large : l'objet de 350 points fait 3,5 fois 85,6 mm
    final vMm = photoMeasureMm(
      const PlanPoint(10, 10),
      const PlanPoint(110, 10),
      const PlanPoint(0, 50),
      const PlanPoint(0, 400),
    );
    expect(vMm, 300);
    const vSame = PlanPoint(5, 5);
    expect(photoMeasureMm(vSame, vSame, const PlanPoint(0, 0), const PlanPoint(1, 1)), isNull);
  });

  test('une feuille A4 sert d\'étalon par son grand ou son petit côté', () {
    expect(MeasureReference.card.sideMm, cardLongSideMm);
    expect(MeasureReference.a4Long.sideMm, 297);
    expect(MeasureReference.a4Short.sideMm, 210);
    // Grand côté de la feuille sur 297 points : un point vaut un millimètre
    final vMm = photoMeasureMm(
      const PlanPoint(0, 0),
      const PlanPoint(0, 297),
      const PlanPoint(0, 0),
      const PlanPoint(830, 0),
      pReferenceMm: MeasureReference.a4Long.sideMm,
    );
    expect(vMm, 830);
  });

  test('plus l\'étalon est grand sur l\'écran, plus la mesure est juste', () {
    // 3 points d'erreur à chaque bout de 100 points : 6 % de la mesure
    expect(photoMeasureSpreadMm(2000, 100), 120);
    expect(photoMeasureSpreadMm(2000, 300), 40);
    expect(photoMeasureSpreadMm(2000, 6), isNull);
  });
}
