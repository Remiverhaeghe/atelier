import 'package:atelier/logic/ventilation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('débits de pointe selon le nombre de pièces principales', () {
    expect(extractionFor(1), (kitchen: 75, bathroom: 15, toilet: 15));
    expect(extractionFor(2).kitchen, 90);
    expect(extractionFor(3).bathroom, 30);
    expect(extractionFor(4).toilet, 30);
    expect(extractionFor(7).kitchen, 135);
  });

  test('maison de 4 pièces, une salle d\'eau, un WC', () {
    final vPlan = planVentilation(pMainRooms: 4, pBathrooms: 1, pToilets: 1);

    expect(vPlan.extractedM3h, 180);
    expect(vPlan.extractVents, 3);
    expect(vPlan.airInlets, 4);
    expect(vPlan.inletsM3h, 135);
    expect(planVentilation(pMainRooms: 1, pBathrooms: 0, pToilets: 0).airInlets, 1);
  });
}
