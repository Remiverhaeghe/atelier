import 'package:atelier/logic/extra_items.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un article déjà là voit sa quantité augmenter, les quantités nulles sont ignorées', () {
    final vMerged = mergeExtras(
      const [ExtraItem(name: 'Sabots de solive', quantity: 18)],
      const [
        ExtraItem(name: 'Sabots de solive', quantity: 4),
        ExtraItem(name: 'Pieds de poteau', quantity: 2),
        ExtraItem(name: 'Goujons', quantity: 0),
      ],
    );

    expect([for (final vItem in vMerged) (vItem.name, vItem.quantity)], [
      ('Sabots de solive', 22),
      ('Pieds de poteau', 2),
    ]);
  });

  test('les articles ajoutés suivent le chantier dans le fichier', () {
    const vWorksite = Worksite(
      id: 'w',
      name: 'Maison démo',
      extras: [ExtraItem(name: 'Équerres, bras de 20 cm', quantity: 3)],
    );

    final vBack = Worksite.fromJson(vWorksite.toJson());

    expect(vBack.extras.single.name, 'Équerres, bras de 20 cm');
    expect(vBack.extras.single.quantity, 3);
    expect(const Worksite(id: 'v', name: 'Vide').toJson().containsKey('extras'), isFalse);
  });
}
