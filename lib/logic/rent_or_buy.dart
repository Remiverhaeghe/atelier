/// Louer ou acheter un outil : coût de chaque choix et seuil de rentabilité de l'achat.
library;

class RentOrBuy {
  const RentOrBuy({
    this.purchasePrice = 0,
    this.dayRate = 0,
    this.days = 1,
    this.resalePercent = 0,
  });

  /// Prix d'achat neuf.
  final double purchasePrice;

  /// Prix de location pour une journée.
  final double dayRate;

  /// Jours d'utilisation prévus.
  final int days;

  /// Part du prix récupérée en revendant l'outil après le chantier.
  final double resalePercent;

  RentOrBuy copyWith({double? purchasePrice, double? dayRate, int? days, double? resalePercent}) =>
      RentOrBuy(
        purchasePrice: purchasePrice ?? this.purchasePrice,
        dayRate: dayRate ?? this.dayRate,
        days: days ?? this.days,
        resalePercent: resalePercent ?? this.resalePercent,
      );
}

typedef RentOrBuyResult = ({double rentCost, double buyCost, int? breakEvenDays, bool buy});

/// Coût réel de l'achat (revente déduite) face à la location, et nombre de jours à partir duquel
/// acheter revient moins cher ; null si la location ne coûte rien.
RentOrBuyResult rentOrBuy(RentOrBuy pChoice) {
  final vRent = pChoice.dayRate * pChoice.days;
  final vBuy = pChoice.purchasePrice * (1 - pChoice.resalePercent.clamp(0, 100) / 100);
  final vBreakEven = pChoice.dayRate <= 0
      ? null
      : (vBuy / pChoice.dayRate - 1e-9).ceil().clamp(1, 1 << 30);
  final rResult = (
    rentCost: vRent,
    buyCost: vBuy,
    breakEvenDays: vBreakEven,
    buy: pChoice.dayRate > 0 && vBuy < vRent,
  );

  return rResult;
}
