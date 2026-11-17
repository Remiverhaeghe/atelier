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
}
