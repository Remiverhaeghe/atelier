import 'package:atelier/logic/visit.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('résumé : seules les pièces avec des points à voir', () {
    final vSummary = visitSummary({
      'salon': {VisitCheck.cracks: 'Fissure au-dessus de la porte', VisitCheck.outlets: ''},
      'chambre': const {},
    });
    expect(vSummary, {'salon': 2});
    expect(VisitCheck.values.first, VisitCheck.floorLevel);
    expect(HouseCheck.values, hasLength(5));
  });
}
