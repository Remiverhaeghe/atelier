import 'package:atelier/logic/insulation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('combles perdus en laine de verre : R 7 en deux couches croisées', () {
    final vPlan = planInsulation(
      pPart: InsulatedPart.lostAttic,
      pInsulant: Insulant.glassWool,
      pAreaM2: 40,
    );

    expect(vPlan.neededMm, 245);
    expect(vPlan.layersMm, [200, 45]);
    expect(vPlan.achievedR, closeTo(7, 1e-9));
    // 42 m² en paquets de 5 m², par couche
    expect(vPlan.packs, 18);
    expect(vPlan.hangers, 0);
  });

  test('rampants en laine de roche : la plus fine paire qui suffit, suspentes', () {
    final vPlan = planInsulation(
      pPart: InsulatedPart.rafters,
      pInsulant: Insulant.rockWool,
      pAreaM2: 20,
    );

    expect(vPlan.layersMm, [120, 100]);
    expect(vPlan.vaporBarrierM2, closeTo(22, 1e-9));
    expect(vPlan.hangers, 28);
  });

  test('murs en fibre de bois, plancher en polyuréthane, R choisi', () {
    expect(
      planInsulation(
        pPart: InsulatedPart.walls,
        pInsulant: Insulant.woodFibre,
        pAreaM2: 20,
      ).layersMm,
      [160],
    );
    final vFloor = planInsulation(
      pPart: InsulatedPart.floor,
      pInsulant: Insulant.polyurethane,
      pAreaM2: 30,
      pTargetR: 4,
    );
    expect(vFloor.layersMm, [100]);
    expect(vFloor.vaporBarrierM2, 0);
    expect(vFloor.targetR, 4);
  });

  test('ouate soufflée : épaisseur au centimètre et sacs', () {
    final vPlan = planInsulation(
      pPart: InsulatedPart.lostAttic,
      pInsulant: Insulant.cellulose,
      pAreaM2: 50,
    );

    expect(vPlan.layersMm, [280]);
    expect(vPlan.packs, 0);
    expect(celluloseBags(50, 280), 40);
  });

  test('épaisseur introuvable : deux couches les plus épaisses', () {
    final vPlan = planInsulation(
      pPart: InsulatedPart.rafters,
      pInsulant: Insulant.polyurethane,
      pAreaM2: 10,
      pTargetR: 20,
    );

    expect(vPlan.layersMm, [120, 120]);
  });
}
