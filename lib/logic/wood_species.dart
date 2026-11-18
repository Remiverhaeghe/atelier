/// Essences de bois courantes en magasin et ce qu'elles supportent.
///
/// La classe d'emploi dit où le bois peut aller (norme NF EN 335) : 1 à l'intérieur au sec,
/// 2 à l'intérieur avec de l'humidité passagère, 3 dehors sans toucher le sol, 4 en contact
/// avec le sol ou l'eau. La classe donnée ici est celle du bois de cœur non traité ; un bois
/// traité en autoclave peut monter d'une ou deux classes, c'est écrit sur l'étiquette.
library;

/// Où va le bois.
enum UseClass {
  /// Meuble, étagère, mezzanine, plancher intérieur.
  indoorDry(1),

  /// Salle de bains, cuisine, combles mal ventilés.
  indoorDamp(2),

  /// Menuiserie extérieure, pergola, bardage : dehors, sans toucher le sol.
  outdoor(3),

  /// Poteau planté, terrasse au ras du sol, bord de bassin.
  groundContact(4);

  const UseClass(this.level);

  final int level;
}

enum WoodSpecies {
  spruce(useClass: 2, densityKgM3: 450, price: 1, ease: 1),
  pine(useClass: 2, densityKgM3: 520, price: 1, ease: 1),
  douglas(useClass: 3, densityKgM3: 530, price: 2, ease: 1),
  larch(useClass: 3, densityKgM3: 600, price: 2, ease: 2),
  oak(useClass: 3, densityKgM3: 700, price: 3, ease: 3),
  ash(useClass: 1, densityKgM3: 690, price: 2, ease: 2),
  beech(useClass: 1, densityKgM3: 710, price: 2, ease: 2),
  tropical(useClass: 4, densityKgM3: 850, price: 3, ease: 3);

  const WoodSpecies({
    required this.useClass,
    required this.densityKgM3,
    required this.price,
    required this.ease,
  });

  /// Classe d'emploi sans traitement.
  final int useClass;
  final int densityKgM3;

  /// 1 bon marché, 3 cher.
  final int price;

  /// 1 facile à scier et raboter, 3 dur et exigeant.
  final int ease;

  /// Tient l'usage demandé sans traitement.
  bool fits(UseClass pUse) => useClass >= pUse.level;
}

/// Essences qui conviennent, de la moins chère à la plus chère, puis de la plus facile.
List<WoodSpecies> speciesFor(UseClass pUse) {
  final rSpecies = WoodSpecies.values.where((pSpecies) => pSpecies.fits(pUse)).toList()
    ..sort((pA, pB) {
      final vPrice = pA.price.compareTo(pB.price);

      final vEase = pA.ease.compareTo(pB.ease);

      // Le tri de Dart n'est pas stable : l'ordre de l'énumération départage
      return vPrice != 0 ? vPrice : (vEase != 0 ? vEase : pA.index.compareTo(pB.index));
    });

  return rSpecies;
}

/// Poids d'une pièce de bois de [pWidthMm] × [pThicknessMm] × [pLengthMm], en kilos.
double woodKg(WoodSpecies pSpecies, int pWidthMm, int pThicknessMm, int pLengthMm) =>
    pWidthMm * pThicknessMm * pLengthMm / 1e9 * pSpecies.densityKgM3;
