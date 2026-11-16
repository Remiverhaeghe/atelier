import 'package:atelier/logic/shelf.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('étagère de 80 × 180 × 30 cm : débit, panneau, vis, écart', () {
    final vPlan = planShelf(const ShelfDesign());

    expect(vPlan.parts, [
      (name: sidePart, count: 2, lengthMm: 1800, widthMm: 300),
      (name: shelfPart, count: 5, lengthMm: 764, widthMm: 300),
      (name: backPart, count: 1, lengthMm: 1800, widthMm: 800),
    ]);
    // Quatre bandes de 2,50 m, quatre bandes de 30 cm dans un panneau de 1,25 m
    expect(vPlan.boards, 1);
    expect(vPlan.screws, 20);
    expect(vPlan.gapMm, 427);
  });

  test('la portée dépend du panneau et de son épaisseur', () {
    expect(planShelf(const ShelfDesign()).tooWide, isTrue);
    expect(planShelf(const ShelfDesign(material: ShelfMaterial.plywood)).tooWide, isFalse);
    expect(planShelf(const ShelfDesign(thicknessMm: 22)).maxSpanMm, 855);
  });

  test('au moins un dessus et un dessous, sans fond si on n\'en veut pas', () {
    final vPlan = planShelf(const ShelfDesign(shelves: 1, back: false, depthMm: 0));

    expect(vPlan.parts.map((pPart) => pPart.name), [sidePart, shelfPart]);
    expect(vPlan.parts.last.count, 2);
    expect(const ShelfDesign().copyWith(widthMm: 600).widthMm, 600);
  });
}
