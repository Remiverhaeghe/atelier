import 'package:atelier/logic/room_shopping.dart';
import 'package:atelier/logic/shopping.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  final vWorksite = Worksite(
    id: 'maison',
    name: 'Maison',
    rooms: [rectangleRoom(), lShapedRoom()],
    prices: const {'parquetPacks': 30.5, 'baseboardBars': 8},
  );

  test('une entrée par pièce, dans l\'ordre du chantier', () {
    final vRooms = shoppingByRoom(vWorksite);

    expect(vRooms.map((pItem) => pItem.room.name), ['Salon', vWorksite.rooms[1].name]);
  });

  test('chaque pièce garde ses propres quantités', () {
    final vRooms = shoppingByRoom(vWorksite);
    final vPacks = [
      for (final vRoom in vRooms)
        vRoom.lines.firstWhere((pLine) => pLine.item == ShoppingItem.parquetPacks).quantity,
    ];

    // La liste du chantier arrondit chaque pièce séparément : la somme est la même
    expect(vPacks.reduce((pA, pB) => pA + pB), 14);
  });

  test('le coût d\'une pièce additionne les prix connus et signale ceux qui manquent', () {
    final vSalon = shoppingByRoom(vWorksite).first;

    expect(vSalon.cost, greaterThan(0));
    expect(vSalon.incomplete, isTrue);
  });

  test('le coût par pièce retombe sur le budget du chantier', () {
    final vTotal = shoppingByRoom(vWorksite).fold<double>(0, (pSum, pItem) => pSum + pItem.cost);

    expect(vTotal, closeTo(budgetTotal(shoppingList(vWorksite)), 0.001));
  });

  test('une pièce sans article est omise', () {
    const vEmpty = Worksite(id: 'w', name: 'W');

    expect(shoppingByRoom(vEmpty), isEmpty);
  });
}
