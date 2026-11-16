/// Ventilation (VMC simple flux) d'un logement : débits extraits, entrées d'air, détalonnage.
///
/// Débits de pointe couramment repris de l'arrêté du 24 mars 1982, selon le nombre de pièces
/// principales (séjour et chambres).
library;

typedef Extraction = ({int kitchen, int bathroom, int toilet});

/// Débits extraits de pointe (m³/h) selon le nombre de pièces principales.
Extraction extractionFor(int pMainRooms) => switch (pMainRooms) {
  <= 1 => (kitchen: 75, bathroom: 15, toilet: 15),
  2 => (kitchen: 90, bathroom: 15, toilet: 15),
  3 => (kitchen: 105, bathroom: 30, toilet: 15),
  4 => (kitchen: 120, bathroom: 30, toilet: 30),
  _ => (kitchen: 135, bathroom: 30, toilet: 30),
};

/// Modules d'entrée d'air courants : 45 m³/h au séjour, 30 m³/h par chambre.
const livingAirInlet = 45;
const bedroomAirInlet = 30;

/// Détalonnage sous les portes pour que l'air passe : 1 cm, 2 cm pour la cuisine.
const undercutMm = 10;
const kitchenUndercutMm = 20;

typedef VentilationPlan = ({int extractedM3h, int inletsM3h, int extractVents, int airInlets});

/// VMC d'un logement de [pMainRooms] pièces principales (dont un séjour), [pBathrooms] salles
/// d'eau et [pToilets] WC séparés ; une salle de bain avec WC compte comme salle d'eau.
VentilationPlan planVentilation({
  required int pMainRooms,
  required int pBathrooms,
  required int pToilets,
}) {
  final vFlows = extractionFor(pMainRooms);
  final vExtracted = vFlows.kitchen + pBathrooms * vFlows.bathroom + pToilets * vFlows.toilet;
  final vBedrooms = pMainRooms > 1 ? pMainRooms - 1 : 0;
  final vInlets = livingAirInlet + vBedrooms * bedroomAirInlet;
  final rPlan = (
    extractedM3h: vExtracted,
    inletsM3h: vInlets,
    extractVents: 1 + pBathrooms + pToilets,
    airInlets: 1 + vBedrooms,
  );

  return rPlan;
}
