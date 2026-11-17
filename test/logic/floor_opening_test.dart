import 'package:atelier/logic/floor_opening.dart';
import 'package:atelier/logic/mezzanine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('trémie de 90 × 100 cm dans des solives de 2 m à 40 cm', () {
    final vPlan = planOpening(const Mezzanine(), 900, 1000);

    expect(vPlan.cutJoists, 2);
    expect(vPlan.tailLengthMm, 1000);
    expect(vPlan.header, (widthMm: 45, heightMm: 145));
    expect(vPlan.trimmer, (widthMm: 45, heightMm: 145));
    expect(vPlan.hangers, 4);
    expect(vPlan.tooLong, isFalse);
  });

  test('portée et charge plus fortes : enchevêtrure renforcée', () {
    final vPlan = planOpening(
      const Mezzanine(depthMm: 4000, use: MezzanineUse.storage),
      1000,
      1000,
    );

    expect(vPlan.tailLengthMm, 3000);
    expect(vPlan.trimmer, (widthMm: 63, heightMm: 175));
  });

  test('sans largeur : rien à couper', () {
    final vPlan = planOpening(const Mezzanine(), 0, 1000);

    expect(vPlan.cutJoists, 0);
    expect(vPlan.hangers, 0);
  });

  test('trémie aussi longue que la portée : signalée', () {
    final vPlan = planOpening(const Mezzanine(), 900, 2500);

    expect(vPlan.tooLong, isTrue);
    expect(vPlan.tailLengthMm, 0);
  });
}
