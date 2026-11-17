import 'package:atelier/logic/mezzanine.dart';
import 'package:atelier/logic/mezzanine_cutting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('solives et lambourde : la longueur qui demande le moins de bois', () {
    // Neuf solives de 2 m et une lambourde de 3 m : deux solives par barre de 4,5 m,
    // alors qu'en 4 m le trait de scie empêche d'en mettre deux
    final vOrder = orderTimber((widthMm: 45, heightMm: 145), [
      for (var vIndex = 0; vIndex < 9; vIndex++) 2000,
      3000,
    ]);

    expect(vOrder.stockMm, 4500);
    expect(vOrder.bars, 6);
    expect(vOrder.pieces.first, 3000);
    expect(vOrder.tooLong, 0);
  });

  test('à quantité de bois égale, le moins de barres', () {
    // 2 × 3 m : deux barres de 3 m ou une de 6 m, toujours 6 m de bois
    final vOrder = orderTimber((widthMm: 45, heightMm: 145), [2900, 2900]);

    expect(vOrder.stockMm, 6000);
    expect(vOrder.bars, 1);
  });

  test('plus long que 6 m : signalé, à commander sur mesure', () {
    final vOrder = orderTimber((widthMm: 75, heightMm: 225), [7000, 2000]);

    expect(vOrder.stockMm, 6000);
    expect(vOrder.tooLong, 1);
  });

  test('mezzanine contre un mur : solives et lambourde, puis poteaux', () {
    const vMezzanine = Mezzanine();
    final vOrders = mezzanineTimber(vMezzanine, planMezzanine(vMezzanine));

    expect(vOrders, hasLength(2));
    expect(vOrders.first.section, (widthMm: 45, heightMm: 145));
    expect(vOrders.first.bars, 6);
    // Deux poteaux de 2,20 m dans une barre de 4,5 m
    expect(vOrders.last.section, (widthMm: 100, heightMm: 100));
    expect(vOrders.last.stockMm, 4500);
    expect(vOrders.last.bars, 1);
  });

  test('entre deux murs : aucun poteau ; portée trop grande : aucune solive', () {
    const vTwoWalls = Mezzanine(support: MezzanineSupport.twoWalls);
    const vTooDeep = Mezzanine(depthMm: 8000);

    expect(mezzanineTimber(vTwoWalls, planMezzanine(vTwoWalls)), hasLength(1));
    expect(
      mezzanineTimber(vTooDeep, planMezzanine(vTooDeep)).single.section,
      (widthMm: 100, heightMm: 100),
    );
  });
}
