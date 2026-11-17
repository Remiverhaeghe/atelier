import 'package:atelier/logic/mezzanine.dart';
import 'package:atelier/logic/mezzanine_floor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('plancher', () {
    test('OSB/3 sur solives à 40 cm : 18 mm, panneaux, vis et colle', () {
      final vPlan = planFloor(const Mezzanine(), FloorPanel.osb3);

      // 6 m² et 8 % de chutes, panneaux de 1,6875 m²
      expect(vPlan.thicknessMm, 18);
      expect(vPlan.panels, 4);
      expect(vPlan.screws, 75);
      expect(vPlan.screwLengthMm, 50);
      expect(vPlan.glueCartridges, 2);
    });

    test('aggloméré P5 : plus de petits panneaux', () {
      final vPlan = planFloor(const Mezzanine(), FloorPanel.particleP5);

      expect(vPlan.thicknessMm, 19);
      expect(vPlan.panels, 6);
    });

    test('solives écartées : panneau plus épais, vis plus longues, moins de vis', () {
      final vPlan = planFloor(const Mezzanine(joistSpacingMm: 600), FloorPanel.particleP5);

      expect(vPlan.thicknessMm, 22);
      expect(vPlan.screwLengthMm, 60);
      expect(vPlan.screws, 50);
    });

    test('entraxe saisi à zéro : 40 cm', () {
      expect(planFloor(const Mezzanine(joistSpacingMm: 0), FloorPanel.osb3).thicknessMm, 18);
    });

    test('toute petite mezzanine : une cartouche quand même', () {
      expect(
        planFloor(const Mezzanine(lengthMm: 1000, depthMm: 1000), FloorPanel.osb3).glueCartridges,
        1,
      );
    });
  });

  group('garde-corps', () {
    test('bords dans le vide selon l\'appui, escalier déduit', () {
      expect(openEdgeMm(const Mezzanine(), 700), 6300);
      expect(openEdgeMm(const Mezzanine(support: MezzanineSupport.twoWalls), 700), 5300);
      expect(openEdgeMm(const Mezzanine(support: MezzanineSupport.freestanding), 700), 9300);
      expect(openEdgeMm(const Mezzanine(lengthMm: 500, depthMm: 0), 700), 0);
    });

    test('barreaux tous les 15 cm, poteaux tous les 1,20 m', () {
      final vPlan = planGuardrail(6300);

      expect(vPlan.balusters, 42);
      expect(vPlan.posts, 7);
      expect(vPlan.railLengthMm, 6300);
    });

    test('règles de la norme', () {
      expect(guardrailHeightMm, 1000);
      expect(guardrailMaxGapMm, 110);
      expect(guardrailClimbZoneMm, 450);
    });

    test('rien à protéger : ni poteau ni barreau', () {
      final vPlan = planGuardrail(0);

      expect(vPlan.posts, 0);
      expect(vPlan.balusters, 0);
    });
  });
}
