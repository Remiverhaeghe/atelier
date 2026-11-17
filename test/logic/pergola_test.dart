import 'package:atelier/logic/pergola.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pergola adossée en polycarbonate, région A', () {
    const vPergola = Pergola();
    final vPlan = planPergola(vPergola);

    // 0,25 kN/m² de poids propre et 0,8 × 0,45 de neige
    expect(vPergola.serviceKnPerM2, closeTo(0.61, 1e-9));
    expect(vPergola.ultimateKnPerM2, closeTo(0.8775, 1e-9));
    expect(vPlan.rafters, 8);
    expect(vPlan.rafter, (widthMm: 45, heightMm: 145));
    expect(vPlan.beams, 1);
    expect(vPlan.beam, (widthMm: 90, heightMm: 225));
    expect(vPlan.postsPerBeam, 2);
    expect(vPlan.postSideMm, 100);
    expect(vPlan.concreteLitres, 160);
  });

  test('tuiles en montagne : chevrons plus forts', () {
    final vPlan = planPergola(
      const Pergola(depthMm: 5000, lengthMm: 5000, cover: PergolaCover.tiles, region: SnowRegion.e),
    );

    expect(vPlan.rafter, (widthMm: 75, heightMm: 200));
    expect(vPlan.postsPerBeam, 3);
    expect(vPlan.postSpacingMm, 2500);
  });

  test('pergola ouverte : la neige passe au travers', () {
    const vOpen = Pergola(cover: PergolaCover.open);

    expect(vOpen.snowKnPerM2, 0);
    expect(vOpen.serviceKnPerM2, closeTo(0.15, 1e-9));
  });

  test('indépendante : deux poutres, deux fois plus de plots', () {
    final vPlan = planPergola(const Pergola(lengthMm: 6000, againstWall: false));

    expect(vPlan.beams, 2);
    expect(vPlan.postsPerBeam, 3);
    expect(vPlan.concreteLitres, 480);
  });
}
