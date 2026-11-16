/// Plomberie : évacuation (diamètres, pente) et alimentation (eau froide, eau chaude) par appareil.
library;

enum Fixture { washbasin, shower, bathtub, sink, washingMachine, dishwasher, toilet }

/// Diamètre extérieur courant du tuyau PVC d'évacuation, en mm.
int drainDiameterMm(Fixture pFixture) => switch (pFixture) {
  Fixture.washbasin => 32,
  Fixture.toilet => 100,
  _ => 40,
};

/// Eau chaude en plus de l'eau froide ; lave-linge, lave-vaisselle et WC n'ont que l'eau froide.
bool needsHotWater(Fixture pFixture) => switch (pFixture) {
  Fixture.washingMachine || Fixture.dishwasher || Fixture.toilet => false,
  _ => true,
};

/// Pente d'évacuation : entre 1 et 3 cm par mètre.
const minSlopeMmPerM = 10;
const maxSlopeMmPerM = 30;
const plumbingMarginPercent = 10;

/// Un appareil et la longueur de tuyau jusqu'à la descente ou la nourrice.
typedef FixtureRun = ({Fixture fixture, double runMetres});

typedef PlumbingNeeds = ({
  Map<int, int> drainMetresByDiameter,
  int supplyMetres,
  int elbows,
  int fittings,
});

int _ceil(double pValue) => (pValue - 1e-9).ceil();

PlumbingNeeds plumbingNeeds(List<FixtureRun> pRuns) {
  final vDrains = <int, double>{};
  var vSupply = 0.0;
  for (final vRun in pRuns) {
    final vLength = vRun.runMetres < 0 ? 0.0 : vRun.runMetres;
    final vDiameter = drainDiameterMm(vRun.fixture);
    vDrains[vDiameter] = (vDrains[vDiameter] ?? 0) + vLength;
    vSupply += vLength * (needsHotWater(vRun.fixture) ? 2 : 1);
  }
  final vMargin = 1 + plumbingMarginPercent / 100;
  final rNeeds = (
    drainMetresByDiameter: {
      for (final vEntry in (vDrains.entries.toList()..sort((pA, pB) => pA.key.compareTo(pB.key))))
        vEntry.key: _ceil(vEntry.value * vMargin),
    },
    supplyMetres: _ceil(vSupply * vMargin),
    // Deux coudes par évacuation, un raccord par arrivée d'eau
    elbows: pRuns.length * 2,
    fittings: pRuns.fold(0, (pSum, pRun) => pSum + (needsHotWater(pRun.fixture) ? 2 : 1)),
  );

  return rNeeds;
}

/// Dénivelé à prévoir sur une longueur d'évacuation, en mm : du minimum au maximum.
({int minMm, int maxMm}) drainDrop(double pRunMetres) =>
    (minMm: (pRunMetres * minSlopeMmPerM).round(), maxMm: (pRunMetres * maxSlopeMmPerM).round());
