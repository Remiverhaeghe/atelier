/// Livraison vérifiée à la réception, contre ce qui était commandé.
library;

import 'shopping.dart';

enum DeliveryState { complete, missing, extra, unchecked }

typedef DeliveryLine = ({ShoppingItem item, int ordered, int? received, DeliveryState state});

/// Pour chaque ligne commandée, ce qui est arrivé : rien de noté, manque, en trop ou complet.
List<DeliveryLine> checkDelivery(List<ShoppingLine> pLines, Map<String, int> pReceived) => [
  for (final vLine in pLines)
    if (vLine.quantity > 0)
      (
        item: vLine.item,
        ordered: vLine.quantity,
        received: pReceived[vLine.item.name],
        state: switch (pReceived[vLine.item.name]) {
          null => DeliveryState.unchecked,
          final vCount when vCount < vLine.quantity => DeliveryState.missing,
          final vCount when vCount > vLine.quantity => DeliveryState.extra,
          _ => DeliveryState.complete,
        },
      ),
];

/// Livraison entièrement reçue : chaque ligne notée et complète.
bool deliveryDone(List<DeliveryLine> pLines) =>
    pLines.isNotEmpty && pLines.every((pLine) => pLine.state == DeliveryState.complete);
