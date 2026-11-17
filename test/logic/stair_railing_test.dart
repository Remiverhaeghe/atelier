import 'package:atelier/logic/stair_design.dart';
import 'package:atelier/logic/stair_railing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final vDesign = designStair(2800);

  test('contre un mur : garde-corps côté vide, main courante des deux côtés', () {
    final vRailing = planStairRailing(vDesign, 2800);

    // Volée de 4,20 m pour 2,80 m de haut : 5,05 m en pente
    expect(vRailing.lengthMm, 5048);
    expect(vRailing.posts, 6);
    expect(vRailing.balusters, 34);
    expect(vRailing.handrailMm, 10096);
  });

  test('entre deux murs : une main courante, aucun garde-corps', () {
    final vRailing = planStairRailing(vDesign, 2800, pOpenSides: 0);

    expect(vRailing.posts, 0);
    expect(vRailing.balusters, 0);
    expect(vRailing.handrailMm, 5048);
  });

  test('au milieu de la pièce : un garde-corps de chaque côté', () {
    final vRailing = planStairRailing(vDesign, 2800, pOpenSides: 5);

    expect(vRailing.openSides, 2);
    expect(vRailing.posts, 12);
    expect(vRailing.handrailMm, 10096);
  });
}
