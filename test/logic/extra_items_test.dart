import 'package:atelier/logic/extra_items.dart';
import 'package:atelier/logic/touch_up.dart';
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

    expect(
      [for (final vItem in vMerged) (vItem.name, vItem.quantity)],
      [('Sabots de solive', 22), ('Pieds de poteau', 2)],
    );
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

  test('courses des reprises : quantités lues, mesures gardées, déjà listé ou fini ignoré', () {
    final vItems = touchUpPurchases(
      const [
        TouchUp(id: '1', label: 'Fissure', toBuy: "2 × bande à joint, enduit de rebouchage"),
        TouchUp(id: '2', label: 'Trous', toBuy: '3 x chevilles; Enduit de rebouchage + 10 mm de joint'),
        TouchUp(id: '3', label: 'Mur', toBuy: "2,5 kg d'enduit"),
        TouchUp(id: '4', label: 'Fini', passes: 1, donePasses: 1, toBuy: 'Rouleau'),
        TouchUp(id: '5', label: 'Rien'),
        TouchUp(id: '6', label: 'Peinture', toBuy: '2 pots, Mastic, 0 vis'),
      ],
      const [ExtraItem(name: 'mastic', quantity: 1)],
    );

    expect([for (final vItem in vItems) (vItem.name, vItem.quantity)], [
      ('bande à joint', 2),
      ('enduit de rebouchage', 1),
      ('chevilles', 3),
      ('10 mm de joint', 1),
      ("2,5 kg d'enduit", 1),
      ('pots', 2),
      ('0 vis', 1),
    ]);
  });
}
