import 'package:atelier/logic/mezzanine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('poutres et poteaux', () {
    test('une solive de 45 × 145 tient 2 m à 40 cm, pas 4 m', () {
      const vSection = (widthMm: 45, heightMm: 145);

      expect(beamHolds(vSection, c24, 2000, 0.8, 1.17), isTrue);
      expect(beamHolds(vSection, c24, 4000, 0.8, 1.17), isFalse);
    });

    test('la plus légère des sections qui tient', () {
      expect(lightestSection(joistSections, c24, 3500, 0.8, 1.17), (widthMm: 45, heightMm: 170));
      expect(lightestSection(joistSections, c24, 8000, 0.8, 1.17), isNull);
    });

    test('un poteau élancé flambe sous une charge que tient un poteau court', () {
      expect(postHolds(100, 2200, 40), isTrue);
      expect(postHolds(100, 4000, 40), isFalse);
      expect(postHolds(150, 4000, 40), isTrue);
    });
  });

  group('mezzanine', () {
    test('contre un mur : lambourde, poutre sur deux poteaux, sabots', () {
      final vPlan = planMezzanine(const Mezzanine());

      expect(vPlan.joists, 9);
      expect(vPlan.joist, (widthMm: 45, heightMm: 145));
      expect(vPlan.ledgers, 1);
      expect(vPlan.anchorsPerLedger, 9);
      expect(vPlan.beams, 1);
      expect(vPlan.beam, (widthMm: 90, heightMm: 225));
      expect(vPlan.postsPerBeam, 2);
      expect(vPlan.postSpacingMm, 3000);
      expect(vPlan.postLoadKn, closeTo(4.39, 0.01));
      expect(vPlan.postSideMm, 100);
      expect(vPlan.hangers, 18);
    });

    test('plus de portée ou plus de charge : des solives plus fortes', () {
      expect(planMezzanine(const Mezzanine(depthMm: 3500)).joist, (widthMm: 45, heightMm: 170));
      expect(
        planMezzanine(
          const Mezzanine(depthMm: 4000, joistSpacingMm: 600, use: MezzanineUse.storage),
        ).joist,
        (widthMm: 63, heightMm: 200),
      );
    });

    test('au-delà de 4 m entre poteaux, un poteau de plus au milieu', () {
      final vPlan = planMezzanine(const Mezzanine(lengthMm: 6000, depthMm: 2500));

      expect(vPlan.postsPerBeam, 3);
      expect(vPlan.postSpacingMm, 3000);
      // Poteau du milieu d'une poutre continue : 1,25 travée
      expect(vPlan.postLoadKn, closeTo(13.71, 0.01));
    });

    test('un poteau haut et chargé grossit pour ne pas flamber', () {
      const vStorage = Mezzanine(lengthMm: 8000, depthMm: 4000, use: MezzanineUse.storage);

      final vTall = planMezzanine(vStorage.copyWith(postHeightMm: 4000));
      final vShort = planMezzanine(vStorage.copyWith(postHeightMm: 2200));

      expect(vTall.beam, (widthMm: 115, heightMm: 270));
      expect(vTall.postLoadKn, closeTo(44.25, 0.01));
      expect(vTall.postSideMm, 140);
      expect(vShort.postSideMm, 100);
    });

    test('entre deux murs : deux lambourdes, aucun poteau', () {
      final vPlan = planMezzanine(const Mezzanine(support: MezzanineSupport.twoWalls));

      expect(vPlan.ledgers, 2);
      expect(vPlan.beams, 0);
      expect(vPlan.beam, isNull);
      expect(vPlan.postsPerBeam, 0);
      expect(vPlan.postSideMm, isNull);
    });

    test('indépendante : deux poutres sur poteaux, aucune cheville au mur', () {
      final vPlan = planMezzanine(
        const Mezzanine(lengthMm: 8000, depthMm: 3000, support: MezzanineSupport.freestanding),
      );

      expect(vPlan.beams, 2);
      expect(vPlan.anchorsPerLedger, 0);
      expect(vPlan.postsPerBeam, 3);
      expect(vPlan.postSpacingMm, 4000);
    });

    test('portée trop grande pour le commerce : pas de section proposée', () {
      expect(planMezzanine(const Mezzanine(depthMm: 8000)).joist, isNull);
    });

    test('entraxe saisi à zéro : 40 cm', () {
      expect(planMezzanine(const Mezzanine(joistSpacingMm: 0)).joists, 9);
    });

    test('les charges suivent l\'usage', () {
      expect(const Mezzanine().serviceKnPerM2, 2.0);
      expect(const Mezzanine().ultimateKnPerM2, closeTo(2.925, 1e-9));
      expect(const Mezzanine(use: MezzanineUse.storage).serviceKnPerM2, 3.0);
    });
  });
}
