import 'package:atelier/logic/search.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sans accent ni majuscule', () {
    expect(plainText('Plâtre à l\'Œil'), 'platre a l\'oeil');
  });

  test('tous les mots, le titre avant le détail', () {
    const vItems = [
      (title: 'Salon', detail: 'Peinture blanc mat', key: 1),
      (title: 'Peinture du salon', detail: '', key: 2),
      (title: 'Chambre', detail: 'Parquet chêne', key: 3),
    ];
    expect([for (final vHit in searchItems('peinture salon', vItems)) vHit.key], [2, 1]);
    expect([for (final vHit in searchItems('CHENE', vItems)) vHit.key], [3]);
    expect(searchItems('  ', vItems), isEmpty);
    expect(searchItems('cuisine', vItems), isEmpty);
  });
}
