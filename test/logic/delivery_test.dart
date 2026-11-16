import 'package:atelier/logic/delivery.dart';
import 'package:atelier/logic/shopping.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vLines = [
    ShoppingLine(item: ShoppingItem.parquetPacks, quantity: 12, unitPrice: 30),
    ShoppingLine(item: ShoppingItem.glueBuckets, quantity: 2, unitPrice: 40),
    ShoppingLine(item: ShoppingItem.nailBoxes, quantity: 1, unitPrice: 8),
    ShoppingLine(item: ShoppingItem.underlayRolls, quantity: 0, unitPrice: 20, inStock: 2),
  ];

  test('chaque ligne commandée : manque, en trop, complète ou pas encore notée', () {
    final vCheck = checkDelivery(vLines, {'parquetPacks': 11, 'glueBuckets': 3, 'nailBoxes': 1});
    expect([for (final vLine in vCheck) vLine.state], [
      DeliveryState.missing,
      DeliveryState.extra,
      DeliveryState.complete,
    ]);
    expect(deliveryDone(vCheck), isFalse);
    expect(checkDelivery(vLines, const {}).first.state, DeliveryState.unchecked);
  });

  test('livraison complète', () {
    final vCheck = checkDelivery(vLines, {'parquetPacks': 12, 'glueBuckets': 2, 'nailBoxes': 1});
    expect(deliveryDone(vCheck), isTrue);
    expect(deliveryDone(const []), isFalse);
  });
}
