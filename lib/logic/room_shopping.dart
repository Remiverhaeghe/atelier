/// Achats pièce par pièce : ce que chaque pièce demande et ce qu'elle coûte avec les prix saisis.
library;

import 'room.dart';
import 'shopping.dart';
import 'worksite.dart';

/// Achats d'une pièce, avant déduction du stock (le stock est celui du chantier entier).
typedef RoomShopping = ({Room room, List<ShoppingLine> lines, double cost, bool incomplete});

/// Une entrée par pièce qui demande au moins un article, dans l'ordre du chantier.
List<RoomShopping> shoppingByRoom(Worksite pWorksite) {
  final rRooms = <RoomShopping>[];

  for (final vRoom in pWorksite.rooms) {
    final vQuantities = roomQuantities(vRoom, pWorksite.prices);
    final vLines = [
      for (final vItem in ShoppingItem.values)
        if ((vQuantities[vItem] ?? 0) > 0)
          ShoppingLine(
            item: vItem,
            quantity: vQuantities[vItem]!,
            unitPrice: pWorksite.prices[vItem.name],
          ),
    ];

    if (vLines.isNotEmpty) {
      rRooms.add((
        room: vRoom,
        lines: vLines,
        cost: budgetTotal(vLines),
        incomplete: budgetIncomplete(vLines),
      ));
    }
  }

  return rRooms;
}
