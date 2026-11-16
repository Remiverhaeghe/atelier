import 'package:atelier/logic/rent_or_buy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ponceuse à 300 € ou 40 € par jour : louer 3 jours, acheter pour 10', () {
    const vSander = RentOrBuy(purchasePrice: 300, dayRate: 40, days: 3);
    final vShort = rentOrBuy(vSander);
    expect(vShort.rentCost, 120);
    expect(vShort.buyCost, 300);
    expect(vShort.breakEvenDays, 8);
    expect(vShort.buy, isFalse);

    expect(rentOrBuy(vSander.copyWith(days: 10)).buy, isTrue);
  });

  test('la revente fait baisser le seuil', () {
    final vResult = rentOrBuy(
      const RentOrBuy(purchasePrice: 300, dayRate: 40).copyWith(resalePercent: 50, days: 4),
    );
    expect(vResult.buyCost, 150);
    expect(vResult.breakEvenDays, 4);
    expect(vResult.buy, isTrue);
    expect(rentOrBuy(const RentOrBuy(purchasePrice: 300, resalePercent: 150)).buyCost, 0);
  });

  test('sans prix de location, pas de seuil ni de conseil', () {
    final vResult = rentOrBuy(const RentOrBuy(purchasePrice: 300));
    expect(vResult.breakEvenDays, isNull);
    expect(vResult.buy, isFalse);
  });
}
