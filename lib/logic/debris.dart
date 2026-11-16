/// Gravats d'un chantier : volume foisonné, poids, big bags, voyages de remorque et tri en
/// déchetterie.
library;

/// Déchet de démolition, rangé par benne de déchetterie.
///
/// [densityKg] : masse d'un mètre cube en place ; [bulking] : un mètre cube démoli prend plus
/// de place en vrac qu'en place (foisonnement).
enum DebrisKind {
  rubble(2000, 1.5),
  plaster(900, 1.4),
  wood(600, 1.6),
  insulation(30, 1.2),
  metal(800, 2),
  mixed(300, 1.3);

  const DebrisKind(this.densityKg, this.bulking);

  final int densityKg;
  final double bulking;
}

/// Ce qu'on démolit : une surface et son épaisseur (carrelage et sa chape, cloison, parquet).
typedef DebrisLine = ({DebrisKind kind, double areaM2, int thicknessMm});

/// Big bag courant : un mètre cube, une tonne au plus.
const bigBagM3 = 1.0;
const bigBagKg = 1000;

/// Remorque de voiture sans permis spécial : environ 500 kg utiles et 1,2 m³ chargés.
const trailerKg = 500;
const trailerM3 = 1.2;

double inPlaceM3(DebrisLine pLine) => pLine.areaM2 * pLine.thicknessMm / 1000;

double bulkM3(DebrisLine pLine) => inPlaceM3(pLine) * pLine.kind.bulking;

double debrisKg(DebrisLine pLine) => inPlaceM3(pLine) * pLine.kind.densityKg;

/// Total d'une benne : volume en vrac et poids.
typedef DebrisBin = ({DebrisKind kind, double bulkM3, double kg});

/// Évacuation des gravats : une ligne par benne, big bags et voyages de remorque.
typedef DebrisPlan = ({List<DebrisBin> bins, double bulkM3, double kg, int bigBags, int trips});

int _atLeast(double pAmount, double pCapacity) => (pAmount / pCapacity - 1e-9).ceil();

/// Le tri se fait au chargement : les big bags et les voyages sont comptés benne par benne,
/// car on ne mélange pas le plâtre et les gravats.
DebrisPlan debrisPlan(List<DebrisLine> pLines) {
  final vBins = <DebrisKind, DebrisBin>{};
  for (final vLine in pLines) {
    final vOld = vBins[vLine.kind];
    vBins[vLine.kind] = (
      kind: vLine.kind,
      bulkM3: (vOld?.bulkM3 ?? 0) + bulkM3(vLine),
      kg: (vOld?.kg ?? 0) + debrisKg(vLine),
    );
  }
  final vList = [
    for (final vKind in DebrisKind.values)
      if (vBins[vKind] case final vBin? when vBin.bulkM3 > 0) vBin,
  ];
  var vBags = 0;
  var vTrips = 0;
  for (final vBin in vList) {
    vBags += [_atLeast(vBin.bulkM3, bigBagM3), _atLeast(vBin.kg, bigBagKg.toDouble())]
        .reduce((pA, pB) => pA > pB ? pA : pB);
    vTrips += [_atLeast(vBin.bulkM3, trailerM3), _atLeast(vBin.kg, trailerKg.toDouble())]
        .reduce((pA, pB) => pA > pB ? pA : pB);
  }
  final rPlan = (
    bins: vList,
    bulkM3: vList.fold(0.0, (pSum, pBin) => pSum + pBin.bulkM3),
    kg: vList.fold(0.0, (pSum, pBin) => pSum + pBin.kg),
    bigBags: vBags,
    trips: vTrips,
  );

  return rPlan;
}
