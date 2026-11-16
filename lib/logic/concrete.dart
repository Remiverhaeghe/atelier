/// Béton de petite maçonnerie : volume, dosage à 350 kg de ciment par mètre cube, sacs prêts à
/// l'emploi ou toupie.
library;

/// Dosage courant pour une dalle ou des fondations légères, par mètre cube de béton.
const cementKgPerM3 = 350;
const sandKgPerM3 = 680;
const gravelKgPerM3 = 1175;
const waterLitresPerM3 = 175;

/// Sac de ciment courant, et sac de béton prêt à gâcher (35 kg, environ 17 litres).
const cementBagKg = 25;
const readyBagLitres = 17.0;

/// Au-delà, une toupie revient moins cher et fatigue moins que les gâchées.
const truckFromM3 = 1.0;

/// Gâchée d'une bétonnière courante de 160 litres : environ 110 litres de béton.
const mixerBatchLitres = 110.0;

/// Volume d'une dalle, en mètres cubes, avec 10 % de marge pour un fond pas tout à fait plat.
double slabM3(int pLengthMm, int pWidthMm, int pThicknessMm) =>
    pLengthMm * pWidthMm * pThicknessMm / 1e9 * 1.1;

/// Volume de plots ou de trous de poteaux carrés.
double footingsM3(int pCount, int pSideMm, int pDepthMm) =>
    pCount * pSideMm * pSideMm * pDepthMm / 1e9 * 1.1;

typedef ConcretePlan = ({
  int cementBags,
  int sandKg,
  int gravelKg,
  int waterLitres,
  int readyBags,
  int batches,
  bool truck,
});

int _ceil(double pValue) => pValue <= 0 ? 0 : (pValue - 1e-9).ceil();

ConcretePlan planConcrete(double pM3) {
  final rPlan = (
    cementBags: _ceil(pM3 * cementKgPerM3 / cementBagKg),
    sandKg: (pM3 * sandKgPerM3).round(),
    gravelKg: (pM3 * gravelKgPerM3).round(),
    waterLitres: (pM3 * waterLitresPerM3).round(),
    readyBags: _ceil(pM3 * 1000 / readyBagLitres),
    batches: _ceil(pM3 * 1000 / mixerBatchLitres),
    truck: pM3 >= truckFromM3,
  );

  return rPlan;
}
