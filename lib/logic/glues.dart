/// Colles à bois et serrage : laquelle prendre, combien de temps serrer, combien de
/// serre-joints.
///
/// Les temps sont ceux des fiches courantes à 20 °C ; par temps froid ou humide, ils
/// s'allongent. La notice du pot fait foi.
library;

/// Ce qu'on colle.
enum GlueUse { indoorFurniture, outdoorWood, laminate, repair, heavyFixing }

enum Glue {
  vinyl(openMinutes: 10, clampMinutes: 30, cureHours: 24, waterproof: false, gapFilling: false),
  vinylD3(openMinutes: 10, clampMinutes: 45, cureHours: 24, waterproof: true, gapFilling: false),
  polyurethane(
    openMinutes: 20,
    clampMinutes: 90,
    cureHours: 24,
    waterproof: true,
    gapFilling: true,
  ),
  contact(openMinutes: 15, clampMinutes: 0, cureHours: 24, waterproof: true, gapFilling: false),
  epoxy(openMinutes: 5, clampMinutes: 60, cureHours: 24, waterproof: true, gapFilling: true),
  construction(openMinutes: 15, clampMinutes: 0, cureHours: 48, waterproof: true, gapFilling: true);

  const Glue({
    required this.openMinutes,
    required this.clampMinutes,
    required this.cureHours,
    required this.waterproof,
    required this.gapFilling,
  });

  /// Temps pour assembler après l'encollage.
  final int openMinutes;

  /// Serrage minimal ; 0 : on presse fort une fois, sans serre-joint.
  final int clampMinutes;

  /// Avant de charger ou d'usiner l'assemblage.
  final int cureHours;
  final bool waterproof;

  /// Comble un joint pas tout à fait jointif.
  final bool gapFilling;
}

/// Colles conseillées pour [pUse], la plus courante d'abord.
List<Glue> gluesFor(GlueUse pUse) => switch (pUse) {
  GlueUse.indoorFurniture => const [Glue.vinyl, Glue.polyurethane],
  GlueUse.outdoorWood => const [Glue.vinylD3, Glue.polyurethane],
  GlueUse.laminate => const [Glue.contact],
  GlueUse.repair => const [Glue.epoxy, Glue.polyurethane],
  GlueUse.heavyFixing => const [Glue.construction],
};

/// Écart maximal entre deux serre-joints le long d'un collage.
const clampSpacingMm = 250;

/// Serre-joints pour un collage long de [pLengthMm] : un tous les 25 cm, deux au moins.
int clampsFor(int pLengthMm) {
  if (pLengthMm <= 0) {
    return 0;
  }
  // Un à chaque bout, et un tous les 25 cm entre les deux
  final rClamps = (pLengthMm / clampSpacingMm).ceil() + 1;

  return rClamps;
}
