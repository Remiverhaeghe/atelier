import 'package:atelier/logic/panel_cutting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('cinq pièces dans un panneau, en deux bandes', () {
    final vPlan = planPanels(
      const [(lengthMm: 800, widthMm: 400, count: 2), (lengthMm: 600, widthMm: 400, count: 3)],
      2500,
      1250,
    );

    expect(vPlan.panels, hasLength(1));
    final vParts = vPlan.panels.single.parts;
    expect(vParts, hasLength(5));
    expect(
      [for (final vPart in vParts) (vPart.xMm, vPart.yMm)],
      [(0, 0), (803, 0), (1606, 0), (0, 403), (603, 403)],
    );
    expect(vPlan.wasteShare, closeTo(1 - 1.36 / 3.125, 1e-9));
  });

  test('second panneau quand le premier est plein', () {
    final vPlan = planPanels(const [(lengthMm: 1250, widthMm: 600, count: 4)], 2500, 1250);

    expect(vPlan.panels, hasLength(2));
    expect(vPlan.panels.first.parts, hasLength(2));
    expect(vPlan.panels.last.parts, hasLength(2));
  });

  test('pièce trop grande, tournée si permis, pièce vide ignorée', () {
    const vParts = [
      (lengthMm: 1000, widthMm: 2000, count: 1),
      (lengthMm: 400, widthMm: 800, count: 1),
      (lengthMm: 0, widthMm: 100, count: 3),
      (lengthMm: 3000, widthMm: 3000, count: 1),
    ];

    final vFixed = planPanels(vParts, 2500, 1250);
    expect(vFixed.tooBig, [0, 3]);

    final vTurned = planPanels(vParts, 2500, 1250, pRotate: true);
    expect(vTurned.tooBig, [3]);
    final vPlaced = vTurned.panels.single.parts;
    expect((vPlaced.first.lengthMm, vPlaced.first.widthMm), (2000, 1000));
    expect((vPlaced.last.lengthMm, vPlaced.last.widthMm), (800, 400));
    expect(planPanels(const [], 2500, 1250).wasteShare, 0);
  });
}
