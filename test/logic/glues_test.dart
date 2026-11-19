import 'package:atelier/logic/glues.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('dehors, seules des colles qui tiennent l\'eau', () {
    for (final vGlue in gluesFor(GlueUse.outdoorWood)) {
      expect(vGlue.waterproof, isTrue, reason: vGlue.name);
    }
    expect(gluesFor(GlueUse.indoorFurniture).first, Glue.vinyl);
  });

  test('chaque usage a au moins une colle', () {
    for (final vUse in GlueUse.values) {
      expect(gluesFor(vUse), isNotEmpty, reason: vUse.name);
    }
  });

  test('un serre-joint tous les 25 cm, deux au moins', () {
    expect(clampsFor(0), 0);
    expect(clampsFor(100), 2);
    expect(clampsFor(250), 2);
    expect(clampsFor(800), 5);
  });

  test('la colle contact ne se serre pas : on presse fort une fois', () {
    expect(Glue.contact.clampMinutes, 0);
    expect(Glue.construction.clampMinutes, 0);
  });
}
