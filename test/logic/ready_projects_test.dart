import 'package:atelier/logic/gestures.dart';
import 'package:atelier/logic/ready_projects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('chaque projet a un débit, des courses et des étapes liées à des gestes', () {
    for (final vProject in ReadyProject.values) {
      final vSize = defaultSize(vProject);
      expect(sizeIsValid(vProject, vSize), isTrue, reason: vProject.name);
      final vPlan = projectPlan(vProject, vSize);
      expect(vPlan.parts, isNotEmpty, reason: vProject.name);
      expect(vPlan.buy.every((pBuy) => pBuy.quantity > 0), isTrue, reason: vProject.name);
      expect(vPlan.steps.where((pStep) => pStep.gesture != null).length, greaterThan(3));
      expect(vPlan.parts.every((pPart) => pPart.lengthMm > 0 && pPart.count > 0), isTrue);
    }
  });

  test('étagère : planche à la largeur, tasseau plus court, fixations tous les 40 cm', () {
    final vPlan = projectPlan(ReadyProject.wallShelf, (widthMm: 800, heightMm: 0, depthMm: 250));
    expect(vPlan.parts.first.lengthMm, 800);
    expect(vPlan.parts.first.widthMm, 250);
    expect(vPlan.parts.last.lengthMm, 760);
    expect(vPlan.buy.firstWhere((pBuy) => pBuy.kind == BuyKind.wallScrews).quantity, 3);
    expect(vPlan.buy.firstWhere((pBuy) => pBuy.kind == BuyKind.woodScrews).quantity, 5);
    expect(vPlan.steps.first.gesture, Gesture.laser);
  });

  test('châssis fixe : traverses entre montants, vitrage pris dans la feuillure', () {
    const vSize = (widthMm: 600, heightMm: 900, depthMm: 0);
    final vPlan = projectPlan(ReadyProject.fixedFrame, vSize);
    final vRail = vPlan.parts.firstWhere((pPart) => pPart.kind == PartKind.rail);
    expect(vRail.lengthMm, 600 - 2 * 58);
    final vGlass = frameGlass(vSize);
    expect(vGlass.widthMm, 502);
    expect(vGlass.heightMm, 802);
    final vBeads = vPlan.parts.where((pPart) => pPart.kind == PartKind.glazingBead).toList();
    expect(vBeads.map((pPart) => pPart.lengthMm), [508, 808]);
    expect(vPlan.buy.firstWhere((pBuy) => pBuy.kind == BuyKind.pins).quantity, 18);
    expect(vPlan.steps.any((pStep) => pStep.gesture == Gesture.caulk), isTrue);
  });

  test('mezzanine : une solive tous les 40 cm et un plancher avec dix pour cent de chutes', () {
    final vPlan = projectPlan(ReadyProject.mezzanine, (
      widthMm: 2400,
      heightMm: 2200,
      depthMm: 2000,
    ));
    final vJoist = vPlan.parts.firstWhere((pPart) => pPart.kind == PartKind.joist);
    expect(vJoist.count, 7);
    expect(vJoist.lengthMm, 1885);
    final vPanels = vPlan.parts.firstWhere((pPart) => pPart.kind == PartKind.floorPanel);
    // 4,8 m² plus 10 % sur des panneaux de 1,6875 m²
    expect(vPanels.count, 4);
    expect(vPlan.buy.firstWhere((pBuy) => pBuy.kind == BuyKind.joistHangers).quantity, 14);
    expect(vPlan.buy.firstWhere((pBuy) => pBuy.kind == BuyKind.anchorBolts).quantity, 6);
  });

  test('embrasure : deux joues, un linteau, un appui, tasseaux et cornières', () {
    final vPlan = projectPlan(ReadyProject.roofReveal, (
      widthMm: 780,
      heightMm: 980,
      depthMm: 300,
    ));
    expect(vPlan.parts.first.count, 2);
    expect(vPlan.parts.first.lengthMm, 980);
    final vBattens = vPlan.parts.firstWhere((pPart) => pPart.kind == PartKind.batten);
    expect(vBattens.count, 3);
    expect(vPlan.buy.firstWhere((pBuy) => pBuy.kind == BuyKind.cornerBead).quantity, 2);
    expect(vPlan.buy.firstWhere((pBuy) => pBuy.kind == BuyKind.plasterScrews).quantity, 32);
  });

  test('cotes refusées : trop petites, trop grandes ; les cotes inutiles sont ignorées', () {
    expect(sizeIsValid(ReadyProject.wallShelf, (widthMm: 100, heightMm: 0, depthMm: 250)), isFalse);
    expect(sizeIsValid(ReadyProject.wallShelf, (widthMm: 900, heightMm: 0, depthMm: 50)), isFalse);
    expect(sizeIsValid(ReadyProject.fixedFrame, (widthMm: 600, heightMm: 900, depthMm: 0)), isTrue);
    expect(
      sizeIsValid(ReadyProject.mezzanine, (widthMm: 7000, heightMm: 2200, depthMm: 2000)),
      isFalse,
    );
    expect(sizeIsValid(ReadyProject.roofReveal, (widthMm: 780, heightMm: 50, depthMm: 300)), isFalse);
    expect(usedSizes(ReadyProject.wallShelf).height, isFalse);
  });
}
