import 'package:atelier/logic/wall_tiling.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('crédence de 2,40 m × 60 cm en 20 × 10', () {
    final vNeeds = wallTilingNeeds(const WallTiling());

    expect(vNeeds.netAreaM2, closeTo(1.44, 1e-9));
    expect(vNeeds.tiles, 80);
    expect(vNeeds.boxes, 2);
    expect(vNeeds.glueKg, 6);
    expect(vNeeds.bottomFullRows, 5);
    expect(vNeeds.siliconeMm, 2400);
    expect(vNeeds.profileMm, 0);
    expect(vNeeds.holes, 0);
  });

  test('fenêtre retirée, prises découpées, bords et haut visibles', () {
    final vNeeds = wallTilingNeeds(
      const WallTiling().copyWith(
        cutOutWidthMm: 1000,
        cutOutHeightMm: 500,
        sockets: 2,
        exposedSides: 2,
        topExposed: true,
        onWorktop: false,
      ),
    );

    expect(vNeeds.netAreaM2, closeTo(0.94, 1e-9));
    expect(vNeeds.tiles, 54);
    expect(vNeeds.holes, 2);
    expect(vNeeds.profileMm, 2 * 600 + 2400);
    expect(vNeeds.siliconeMm, 0);
    expect(vNeeds.jointKg, lessThan(wallTilingNeeds(const WallTiling()).jointKg + 1e-9));
  });

  test('ouverture plus grande que le pan : surface nulle', () {
    final vNeeds = wallTilingNeeds(
      const WallTiling().copyWith(cutOutWidthMm: 5000, cutOutHeightMm: 5000),
    );

    expect(vNeeds.netAreaM2, 0);
    expect(vNeeds.tiles, 0);
  });
}
