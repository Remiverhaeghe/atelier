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
    expect(
      [hingesPerDoor(800), hingesPerDoor(1500), hingesPerDoor(1900), hingesPerDoor(2300)],
      [2, 3, 4, 5],
    );
    expect(
      const WardrobeDesign().copyWith(material: ShelfMaterial.mdf).material,
      ShelfMaterial.mdf,
    );
    expect(
      planWardrobe(
        const WardrobeDesign(compartments: [Compartment(shelves: -2)]),
      ).parts.map((pP) => pP.name),
      isNot(contains(shelfPart)),
    );
  });

  test('commode à tiroirs : façades, caissons et coulisses', () {
    final vPlan = planWardrobe(
      const WardrobeDesign(
        widthMm: 800,
        heightMm: 900,
        depthMm: 500,
        doors: false,
        compartments: [Compartment(kind: CompartmentKind.drawers, shelves: 3)],
      ),
    );

    expect(vPlan.drawers, 3);
    expect(vPlan.doorCount, 0);
    expect(vPlan.parts.where((pPart) => pPart.name.startsWith('drawer') || pPart.name == slidePart), [
      (name: drawerFrontPart, count: 3, lengthMm: 779, widthMm: 296),
      (name: drawerSidePart, count: 6, lengthMm: 450, widthMm: 256),
      (name: drawerEndPart, count: 6, lengthMm: 702, widthMm: 256),
      (name: drawerBottomPart, count: 3, lengthMm: 738, widthMm: 450),
      (name: slidePart, count: 3, lengthMm: 450, widthMm: 0),
    ]);
  });

  test('penderie et tiroirs : une seule porte, sur la penderie', () {
    final vPlan = planWardrobe(
      const WardrobeDesign(
        compartments: [
          Compartment(kind: CompartmentKind.hanging),
          Compartment(kind: CompartmentKind.drawers, shelves: 4),
        ],
      ),
    );

    expect(vPlan.doorCount, 1);
    expect(vPlan.parts.firstWhere((pPart) => pPart.name == doorPart).widthMm, 588);
    expect(vPlan.drawers, 4);
  });

  test('charnières : à 10 cm des bords, les autres régulièrement entre', () {
    expect(hingePositions(2194), [100, 598, 1097, 1595, 2094]);
    expect(hingePositions(700), [100, 600]);
  });

  test('coulisse : la plus longue qui tient, la plus courte sinon', () {
    expect(slideLengthFor(580), 550);
    expect(slideLengthFor(200), 250);
  });
}
