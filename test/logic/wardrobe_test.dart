import 'package:atelier/logic/shelf.dart';
import 'package:atelier/logic/wardrobe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('armoire de 120 × 220 × 60 cm : penderie et étagères, deux portes', () {
    final vPlan = planWardrobe(const WardrobeDesign());

    expect(vPlan.compartmentWidthMm, 573);
    expect(vPlan.parts, [
      (name: sidePart, count: 2, lengthMm: 2200, widthMm: 600),
      (name: topBottomPart, count: 2, lengthMm: 1164, widthMm: 600),
      (name: dividerPart, count: 1, lengthMm: 2164, widthMm: 600),
      (name: shelfPart, count: 5, lengthMm: 573, widthMm: 580),
      (name: backPart, count: 1, lengthMm: 2200, widthMm: 1200),
      (name: doorPart, count: 2, lengthMm: 2194, widthMm: 595),
      (name: railPart, count: 1, lengthMm: 573, widthMm: 0),
    ]);
    // Porte de plus de 2 m : cinq charnières
    expect(vPlan.hinges, 10);
    expect(vPlan.tooWide, isFalse);
  });

  test('un compartiment large prend deux portes ; sans porte, tablettes pleine profondeur', () {
    final vWide = planWardrobe(const WardrobeDesign(compartments: [Compartment(shelves: 3)]));
    expect(vWide.doorCount, 2);
    expect(vWide.tooWide, isTrue);
    expect(vWide.parts.map((pPart) => pPart.name), isNot(contains(dividerPart)));

    final vOpen = planWardrobe(const WardrobeDesign(doors: false, compartments: []));
    expect(vOpen.doorCount, 0);
    expect(vOpen.hinges, 0);
    expect(vOpen.parts.map((pPart) => pPart.name), [sidePart, topBottomPart, backPart]);
  });

  test('charnières selon la hauteur de porte', () {
    expect([hingesPerDoor(800), hingesPerDoor(1500), hingesPerDoor(1900), hingesPerDoor(2300)], [
      2,
      3,
      4,
      5,
    ]);
    expect(
      const WardrobeDesign().copyWith(material: ShelfMaterial.mdf).material,
      ShelfMaterial.mdf,
    );
    expect(planWardrobe(const WardrobeDesign(compartments: [Compartment(shelves: -2)])).parts.map((pP) => pP.name), isNot(contains(shelfPart)));
  });
}
