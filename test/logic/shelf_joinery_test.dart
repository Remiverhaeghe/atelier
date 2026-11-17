import 'package:atelier/logic/fixings.dart';
import 'package:atelier/logic/shelf.dart';
import 'package:atelier/logic/shelf_joinery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('épaisseur conseillée', () {
    test('la portée baisse quand la charge monte', () {
      expect(shelfSpanMm(ShelfMaterial.plywood, 18, ShelfLoad.books), 900);
      expect(shelfSpanMm(ShelfMaterial.plywood, 18, ShelfLoad.heavy), 675);
      expect(shelfSpanMm(ShelfMaterial.plywood, 18, ShelfLoad.light), 1170);
    });

    test('la plus fine du commerce qui tient la portée', () {
      final vAdvice = adviseThickness(ShelfMaterial.particleBoard, 764, ShelfLoad.books);

      // 16 mm : 622 mm de portée ; 18 mm : 700 ; 19 mm : 738 ; 22 mm : 855
      expect(vAdvice.thicknessMm, 22);
      expect(vAdvice.middleUpright, isFalse);
    });

    test('trop large même en 30 mm : un montant au milieu', () {
      final vAdvice = adviseThickness(ShelfMaterial.particleBoard, 1600, ShelfLoad.heavy);

      expect(vAdvice.middleUpright, isTrue);
      expect(vAdvice.spanMm, 791);
      expect(
        shelfSpanMm(ShelfMaterial.particleBoard, vAdvice.thicknessMm, ShelfLoad.heavy),
        greaterThanOrEqualTo(791),
      );
    });

    test('rien ne suffit même coupé en deux : le panneau le plus épais', () {
      final vAdvice = adviseThickness(ShelfMaterial.particleBoard, 4000, ShelfLoad.heavy);

      expect(vAdvice.middleUpright, isTrue);
      expect(vAdvice.thicknessMm, 30);
    });
  });

  group('assemblage des tablettes', () {
    test('vis d\'assemblage dans l\'aggloméré et le MDF', () {
      for (final vMaterial in [ShelfMaterial.particleBoard, ShelfMaterial.mdf]) {
        final vAdvice = adviseJoint(ShelfDesign(material: vMaterial));

        expect(vAdvice.joint, ShelfJoint.confirmatScrews);
        expect(vAdvice.perEnd, 3);
        expect(vAdvice.holeInSideMm, 0);
      }
    });

    test('tourillons collés dans le bois, percés aux deux tiers du montant', () {
      final vAdvice = adviseJoint(const ShelfDesign(material: ShelfMaterial.plywood));

      expect(vAdvice.joint, ShelfJoint.dowels);
      expect(vAdvice.diameterMm, 8);
      expect(vAdvice.lengthMm, 35);
      expect(vAdvice.holeInSideMm, 12);
      expect(vAdvice.holeInShelfMm, 25);
    });

    test('le diamètre du tourillon suit l\'épaisseur', () {
      ShelfJoint vJoint(int pThickness) => adviseJoint(
        ShelfDesign(material: ShelfMaterial.solidWood, thicknessMm: pThickness),
      ).joint;
      int vDiameter(int pThickness) => adviseJoint(
        ShelfDesign(material: ShelfMaterial.solidWood, thicknessMm: pThickness),
      ).diameterMm;

      expect(vJoint(16), ShelfJoint.dowels);
      expect(vDiameter(16), 6);
      expect(vDiameter(25), 10);
    });

    test('une étagère peu profonde garde deux points par bout', () {
      final vAdvice = adviseJoint(const ShelfDesign(material: ShelfMaterial.plywood, depthMm: 120));

      expect(vAdvice.perEnd, 2);
    });

    test('tablettes réglables : quatre taquets', () {
      final vAdvice = adviseJoint(const ShelfDesign(), pAdjustable: true);

      expect(vAdvice.joint, ShelfJoint.shelfPins);
      expect(vAdvice.perEnd, 2);
    });
  });

  group('tenue au sol', () {
    test('haute ou étroite : fixée au mur', () {
      expect(adviseStability(const ShelfDesign()).fixToWall, isTrue);
      expect(adviseStability(const ShelfDesign(heightMm: 800, depthMm: 300)).fixToWall, isFalse);
      expect(adviseStability(const ShelfDesign(heightMm: 900, depthMm: 250)).fixToWall, isTrue);
    });

    test('sans fond : contreventer', () {
      expect(adviseStability(const ShelfDesign()).brace, isFalse);
      expect(adviseStability(const ShelfDesign(back: false)).brace, isTrue);
    });
  });

  group('tablette murale sur équerres', () {
    test('cas courant : deux équerres, bras des deux tiers, cheville lourde', () {
      final vPlan = planBrackets(const WallShelf());

      expect(vPlan.brackets, 2);
      expect(vPlan.spacingMm, 900);
      expect(vPlan.overhangMm, 150);
      expect(vPlan.armMm, 200);
      expect(vPlan.totalKg, closeTo(50.97, 0.01));
      expect(vPlan.pullKg, closeTo(19.9, 0.1));
      expect(vPlan.fixing, adviseFixing(WallSupport.concrete, FixingLoad.heavy));
    });

    test('dans une cloison en plaques, une équerre tous les 60 cm au plus', () {
      final vPlan = planBrackets(const WallShelf(lengthMm: 2000, wall: WallSupport.drywall));

      expect(vPlan.spacingMm, lessThanOrEqualTo(600));
      expect(vPlan.brackets, 4);
    });

    test('une tablette plus chargée demande plus d\'équerres', () {
      final vLight = planBrackets(const WallShelf(lengthMm: 2400, load: ShelfLoad.light));
      final vHeavy = planBrackets(const WallShelf(lengthMm: 2400, load: ShelfLoad.heavy));

      expect(vHeavy.brackets, greaterThan(vLight.brackets));
    });

    test('très profonde : le plus grand bras vendu', () {
      expect(planBrackets(const WallShelf(depthMm: 900)).armMm, 400);
    });

    test('épaisseur saisie à zéro : un calcul quand même', () {
      expect(planBrackets(const WallShelf(thicknessMm: 0)).brackets, greaterThanOrEqualTo(2));
    });

    test('tablette plus courte que deux débords : deux équerres quand même', () {
      final vPlan = planBrackets(const WallShelf(lengthMm: 250));

      expect(vPlan.brackets, 2);
      expect(vPlan.spacingMm, 0);
    });
  });
}
