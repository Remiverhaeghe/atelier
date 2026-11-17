import 'package:atelier/logic/drill_template.dart';
import 'package:atelier/logic/shelf.dart';
import 'package:atelier/logic/shelf_joinery.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('tourillons : répartis entre les marges, au milieu de l\'épaisseur', () {
    const vDesign = ShelfDesign(material: ShelfMaterial.plywood);
    final vHoles = jointHoles(vDesign, adviseJoint(vDesign));

    // Profondeur 300, marges de 30 : trois trous à 30, 150 et 270 mm
    expect(vHoles.map((pHole) => pHole.alongMm), [30, 150, 270]);
    expect(vHoles.every((pHole) => pHole.acrossMm == 9 && pHole.diameterMm == 8), isTrue);
  });

  test('vis d\'assemblage : trou de 7 mm dans le montant', () {
    const vDesign = ShelfDesign();
    final vHoles = jointHoles(vDesign, adviseJoint(vDesign));

    expect(vHoles.first.diameterMm, 7);
  });

  test('taquets : deux colonnes, un trou tous les 32 mm', () {
    const vDesign = ShelfDesign();
    final vHoles = pinHoles(vDesign, adviseJoint(vDesign, pAdjustable: true));

    // 0 à 256 mm : neuf rangées de deux trous, à 37 mm des bords
    expect(vHoles, hasLength(18));
    expect(vHoles.map((pHole) => pHole.alongMm).toSet(), {37, 263});
    expect(vHoles.last.acrossMm, 256);
  });
}
