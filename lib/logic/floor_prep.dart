/// Préparer un sol avant le revêtement : chape sèche ou liquide, sous-couche, joints de
/// dilatation et séchage avant la pose. Valeurs courantes des fiches et des règles de l'art,
/// indicatives : la notice du produit l'emporte.
library;

import 'screed.dart';

/// Chape à couler ou à poser.
enum ScreedKind {
  /// Chape sèche : granulats égalisés et plaques posées dessus, légère, pour un plancher bois
  /// ou un étage ; pas d'attente.
  dry(10, 0),

  /// Chape fluide anhydrite, coulée par un chapiste : bonne avec un plancher chauffant.
  liquidAnhydrite(30, 0.5),

  /// Chape ciment tirée à la règle.
  cement(40, 2);

  const ScreedKind(this.minThicknessMm, this.maxMoisturePercent);

  /// Épaisseur minimale courante (granulats pour la chape sèche).
  final int minThicknessMm;

  /// Humidité résiduelle à atteindre avant la pose, en % mesuré à la bombe à carbure ; 0 pour
  /// une chape sèche.
  final double maxMoisturePercent;
}

/// Jours d'attente avant de poser : une semaine par centimètre pour le ciment, et pour
/// l'anhydrite une semaine par centimètre jusqu'à 4 cm puis deux semaines par centimètre en plus.
/// À confirmer par une mesure d'humidité.
int screedKindDryingDays(ScreedKind pKind, int pThicknessMm) {
  final vCm = (pThicknessMm / 10).ceil();
  final rDays = switch (pKind) {
    ScreedKind.dry => 0,
    ScreedKind.cement => 7 * vCm,
    ScreedKind.liquidAnhydrite => vCm <= 4 ? 7 * vCm : 28 + 14 * (vCm - 4),
  };

  return rDays;
}

/// Plaque de chape sèche courante : 1200 × 600 mm.
const dryBoardM2 = 0.72;

/// Sac de granulats d'égalisation : 50 litres.
const dryGrainBagL = 50;

/// Sac de mortier de chape prêt à gâcher : 35 kg, environ 2 kg par m² et par mm.
const cementBagKg = 35;
const cementKgPerM2Mm = 2.0;

typedef ScreedOrder = ({int boards, int grainBags, int cementBags, double volumeM3});

int _ceil(double pValue) => (pValue - 1e-9).ceil();

/// Ce qu'il faut commander pour [pAreaM2] à [pThicknessMm], 5 % de perte compris.
ScreedOrder screedOrder(ScreedKind pKind, double pAreaM2, int pThicknessMm) {
  final vVolume = pAreaM2 * pThicknessMm / 1000;
  final rOrder = switch (pKind) {
    ScreedKind.dry => (
      boards: _ceil(pAreaM2 * 1.05 / dryBoardM2),
      // Un m² sur un mm d'épaisseur fait un litre de granulats
      grainBags: _ceil(pAreaM2 * pThicknessMm * 1.05 / dryGrainBagL),
      cementBags: 0,
      volumeM3: vVolume,
    ),
    ScreedKind.cement => (
      boards: 0,
      grainBags: 0,
      cementBags: _ceil(pAreaM2 * pThicknessMm * cementKgPerM2Mm * 1.05 / cementBagKg),
      volumeM3: vVolume,
    ),
    ScreedKind.liquidAnhydrite => (
      boards: 0,
      grainBags: 0,
      cementBags: 0,
      volumeM3: vVolume * 1.05,
    ),
  };

  return rOrder;
}

/// Sous-couche à poser sous le revêtement.
enum Underlay {
  /// Aucune : le revêtement est collé ou scellé.
  none,

  /// Sous-couche mousse ou fibre de bois de 2 à 5 mm, avec un film pare-vapeur sur un sol
  /// minéral.
  foamWithFilm,

  /// Sous-couche fine et dense, 1 à 1,5 mm, pour un sol vinyle clipsé.
  thinDense,
}

Underlay underlayFor(Covering pCovering) => switch (pCovering) {
  Covering.floating => Underlay.foamWithFilm,
  Covering.vinyl => Underlay.thinDense,
  Covering.tiles || Covering.gluedParquet => Underlay.none,
};

/// Rouleau de sous-couche courant : 15 m².
const underlayRollM2 = 15.0;

/// Rouleaux de sous-couche, 5 % de recouvrement et de chutes compris ; 0 sans sous-couche.
int underlayRolls(Covering pCovering, double pAreaM2) =>
    underlayFor(pCovering) == Underlay.none ? 0 : _ceil(pAreaM2 * 1.05 / underlayRollM2);

/// Jeu à laisser le long des murs, en mm.
int perimeterGapMm(Covering pCovering) => switch (pCovering) {
  Covering.floating => 8,
  Covering.vinyl || Covering.tiles || Covering.gluedParquet => 5,
};

/// Longueur au-delà de laquelle un revêtement flottant demande un joint de dilatation, et
/// côté au-delà duquel une chape ou un carrelage se fractionne.
const floatingSplitMm = 10000;
const screedSplitMm = 8000;

/// Surface au-delà de laquelle une chape ou un carrelage se fractionne.
const screedSplitM2 = 40.0;

/// Joints de dilatation dans une pièce de [pLengthMm] sur [pWidthMm] : un joint par seuil de
/// porte, et des joints intermédiaires quand la pièce dépasse les limites.
({int extraJoints, bool doorThresholds}) expansionJoints(
  Covering pCovering,
  int pLengthMm,
  int pWidthMm,
) {
  final vLongest = pLengthMm > pWidthMm ? pLengthMm : pWidthMm;
  final vArea = pLengthMm * pWidthMm / 1e6;
  final int vExtra;
  if (pCovering == Covering.floating || pCovering == Covering.vinyl) {
    vExtra = vLongest > floatingSplitMm ? _ceil(vLongest / floatingSplitMm) - 1 : 0;
  } else if (pCovering == Covering.tiles) {
    final vByLength = vLongest > screedSplitMm ? _ceil(vLongest / screedSplitMm) - 1 : 0;
    final vByArea = vArea > screedSplitM2 ? _ceil(vArea / screedSplitM2) - 1 : 0;
    vExtra = vByLength > vByArea ? vByLength : vByArea;
  } else {
    vExtra = 0;
  }
  final rJoints = (
    extraJoints: vExtra,
    doorThresholds: pCovering == Covering.floating || pCovering == Covering.vinyl,
  );

  return rJoints;
}

/// Le revêtement peut-il être posé : chape assez sèche à la mesure, ou attente écoulée pour une
/// chape sans mesure.
bool readyToLay(ScreedKind pKind, double pMeasuredPercent) =>
    pKind == ScreedKind.dry || pMeasuredPercent <= pKind.maxMoisturePercent;
