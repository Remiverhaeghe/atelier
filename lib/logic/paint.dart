/// Peinture : surfaces des murs, du plafond et des boiseries, litres, pots et fournitures.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'room.dart';

/// Produits de peinture, chacun acheté à part.
enum PaintProduct { walls, ceiling, woodwork, primer }

/// Pots vendus pour chaque produit, du plus grand au plus petit, en litres.
const potSizes = {
  PaintProduct.walls: [10.0, 5.0, 2.5],
  PaintProduct.ceiling: [10.0, 5.0, 2.5],
  PaintProduct.primer: [10.0, 5.0, 2.5],
  PaintProduct.woodwork: [2.5, 1.0, 0.5],
};

/// Largeur d'un chambranle peint autour d'une porte ou d'un passage.
const casingWidthMm = 70;

/// Rien n'est peint tant que l'utilisateur ne choisit pas une surface : un chantier de parquet
/// seul n'a pas de peinture dans ses courses.
class PaintSettings {
  const PaintSettings({
    this.walls = false,
    this.ceiling = false,
    this.woodwork = false,
    this.primer = false,
    this.coats = 2,
    this.coverageM2PerL = 10,
    this.woodworkCoats = 2,
    this.woodworkCoverageM2PerL = 12,
    this.primerCoverageM2PerL = 10,
    this.extraPercent = 10,
    this.wallColor,
    this.ceilingColor,
    this.woodworkColor,
  });

  final bool walls;
  final bool ceiling;
  final bool woodwork;

  /// Sous-couche d'impression, une couche sur les murs et le plafond peints.
  final bool primer;

  /// Couches de finition sur les murs et le plafond.
  final int coats;
  final double coverageM2PerL;
  final int woodworkCoats;
  final double woodworkCoverageM2PerL;
  final double primerCoverageM2PerL;

  /// Marge pour les retouches et les surfaces qui boivent : toujours prévoir un peu plus.
  final int extraPercent;

  /// Couleurs choisies, en 0xRRGGBB ; absentes tant qu'on n'a rien choisi.
  final int? wallColor;
  final int? ceilingColor;
  final int? woodworkColor;

  PaintSettings copyWith({
    bool? walls,
    bool? ceiling,
    bool? woodwork,
    bool? primer,
    int? coats,
    double? coverageM2PerL,
    int? woodworkCoats,
    double? woodworkCoverageM2PerL,
    double? primerCoverageM2PerL,
    int? extraPercent,
    int? wallColor,
    int? ceilingColor,
    int? woodworkColor,
  }) => PaintSettings(
    walls: walls ?? this.walls,
    ceiling: ceiling ?? this.ceiling,
    woodwork: woodwork ?? this.woodwork,
    primer: primer ?? this.primer,
    coats: coats ?? this.coats,
    coverageM2PerL: coverageM2PerL ?? this.coverageM2PerL,
    woodworkCoats: woodworkCoats ?? this.woodworkCoats,
    woodworkCoverageM2PerL: woodworkCoverageM2PerL ?? this.woodworkCoverageM2PerL,
    primerCoverageM2PerL: primerCoverageM2PerL ?? this.primerCoverageM2PerL,
    extraPercent: extraPercent ?? this.extraPercent,
    wallColor: wallColor ?? this.wallColor,
    ceilingColor: ceilingColor ?? this.ceilingColor,
    woodworkColor: woodworkColor ?? this.woodworkColor,
  );

  Map<String, Object?> toJson() => {
    'walls': walls,
    'ceiling': ceiling,
    'woodwork': woodwork,
    'primer': primer,
    'coats': coats,
    'coverageM2PerL': coverageM2PerL,
    'woodworkCoats': woodworkCoats,
    'woodworkCoverageM2PerL': woodworkCoverageM2PerL,
    'primerCoverageM2PerL': primerCoverageM2PerL,
    'extraPercent': extraPercent,
    if (wallColor != null) 'wallColor': wallColor,
    if (ceilingColor != null) 'ceilingColor': ceilingColor,
    if (woodworkColor != null) 'woodworkColor': woodworkColor,
  };

  static PaintSettings fromJson(Map<String, Object?> pJson) {
    const vBase = PaintSettings();
    double vDouble(String pKey, double pDefault) => (pJson[pKey] as num?)?.toDouble() ?? pDefault;
    final rSettings = PaintSettings(
      walls: (pJson['walls'] as bool?) ?? vBase.walls,
      ceiling: (pJson['ceiling'] as bool?) ?? vBase.ceiling,
      woodwork: (pJson['woodwork'] as bool?) ?? vBase.woodwork,
      primer: (pJson['primer'] as bool?) ?? vBase.primer,
      coats: (pJson['coats'] as int?) ?? vBase.coats,
      coverageM2PerL: vDouble('coverageM2PerL', vBase.coverageM2PerL),
      woodworkCoats: (pJson['woodworkCoats'] as int?) ?? vBase.woodworkCoats,
      woodworkCoverageM2PerL: vDouble('woodworkCoverageM2PerL', vBase.woodworkCoverageM2PerL),
      primerCoverageM2PerL: vDouble('primerCoverageM2PerL', vBase.primerCoverageM2PerL),
      extraPercent: (pJson['extraPercent'] as int?) ?? vBase.extraPercent,
      wallColor: pJson['wallColor'] as int?,
      ceilingColor: pJson['ceilingColor'] as int?,
      woodworkColor: pJson['woodworkColor'] as int?,
    );

    return rSettings;
  }
}

/// Surfaces à peindre, en mètres carrés.
class PaintAreas {
  const PaintAreas({required this.wallsM2, required this.ceilingM2, required this.woodworkM2});

  final double wallsM2;
  final double ceilingM2;
  final double woodworkM2;
}

/// Murs moins les ouvertures, plafond de la surface du contour, portes et chambranles.
PaintAreas paintAreas(Room pRoom) {
  var vWalls = 0.0;
  var vWoodwork = 0.0;
  for (final vWall in pRoom.walls) {
    vWalls += vWall.lengthMm * pRoom.ceilingHeightMm.toDouble();
    for (final vOpening in vWall.openings) {
      final vHeight = math.min(vOpening.height, pRoom.ceilingHeightMm - vOpening.sill);
      vWalls -= vOpening.widthMm * math.max(vHeight, 0).toDouble();
      if (vOpening.kind != OpeningKind.window) {
        // Chambranle sur les deux montants et le haut
        vWoodwork += (2 * vOpening.height + vOpening.widthMm) * casingWidthMm.toDouble();
        if (vOpening.kind == OpeningKind.door) {
          // Face du vantail côté pièce
          vWoodwork += vOpening.widthMm * vOpening.height.toDouble();
        }
      }
    }
  }
  final rAreas = PaintAreas(
    wallsM2: math.max(vWalls, 0) / 1e6,
    ceilingM2: outlineAreaMm2(pRoom) / 1e6,
    woodworkM2: vWoodwork / 1e6,
  );

  return rAreas;
}

/// Litres à prévoir pour chaque produit utilisé, marge comprise.
Map<PaintProduct, double> paintLitres(Room pRoom, PaintSettings pSettings) {
  final vAreas = paintAreas(pRoom);
  final vExtra = 1 + pSettings.extraPercent / 100;
  double vLitres(double pArea, int pCoats, double pCoverage) =>
      pCoverage <= 0 ? 0 : pArea * pCoats / pCoverage * vExtra;
  final vPrimed =
      (pSettings.walls ? vAreas.wallsM2 : 0.0) + (pSettings.ceiling ? vAreas.ceilingM2 : 0.0);
  final rLitres = {
    if (pSettings.walls)
      PaintProduct.walls: vLitres(vAreas.wallsM2, pSettings.coats, pSettings.coverageM2PerL),
    if (pSettings.ceiling)
      PaintProduct.ceiling: vLitres(vAreas.ceilingM2, pSettings.coats, pSettings.coverageM2PerL),
    if (pSettings.woodwork && vAreas.woodworkM2 > 0)
      PaintProduct.woodwork: vLitres(
        vAreas.woodworkM2,
        pSettings.woodworkCoats,
        pSettings.woodworkCoverageM2PerL,
      ),
    if (pSettings.primer && vPrimed > 0)
      PaintProduct.primer: vLitres(vPrimed, 1, pSettings.primerCoverageM2PerL),
  };
  rLitres.removeWhere((_, pLitres) => pLitres <= 0);

  return rLitres;
}

/// Pots à acheter pour [pLitres] : la combinaison la moins chère d'après [pPrices] (prix par
/// taille, en euros). Sans prix connu, un grand pot est compté moins cher au litre, comme en
/// magasin. À coût égal, le moins de pots possible.
Map<double, int> cheapestPots(double pLitres, List<double> pSizes, Map<double, double> pPrices) {
  if (pLitres <= 0 || pSizes.isEmpty) {
    return const {};
  }
  // Calcul en demi-litres, de quoi couvrir le besoin avec au plus un grand pot en trop
  int vUnits(double pValue) => (pValue * 2).round();
  final vNeed = (pLitres * 2 - 1e-9).ceil();
  final vLimit = vNeed + vUnits(pSizes.reduce(math.max));
  double vCost(double pSize) => pPrices[pSize] ?? math.pow(pSize, 0.8).toDouble();
  final vBest = List<({double cost, int pots, Map<double, int> combo})?>.filled(vLimit + 1, null);
  vBest[0] = (cost: 0, pots: 0, combo: const {});
  for (var vAmount = 1; vAmount <= vLimit; vAmount++) {
    for (final vSize in pSizes) {
      final vFrom = vAmount - vUnits(vSize);
      final vPrevious = vFrom >= 0 ? vBest[vFrom] : null;
      if (vPrevious == null) {
        continue;
      }
      final vCandidate = (
        cost: vPrevious.cost + vCost(vSize),
        pots: vPrevious.pots + 1,
        combo: {...vPrevious.combo, vSize: (vPrevious.combo[vSize] ?? 0) + 1},
      );
      final vCurrent = vBest[vAmount];
      if (vCurrent == null ||
          vCandidate.cost < vCurrent.cost - 1e-9 ||
          ((vCandidate.cost - vCurrent.cost).abs() < 1e-9 && vCandidate.pots < vCurrent.pots)) {
        vBest[vAmount] = vCandidate;
      }
    }
  }
  ({double cost, int pots, Map<double, int> combo})? rBest;
  for (var vAmount = vNeed; vAmount <= vLimit; vAmount++) {
    final vOption = vBest[vAmount];
    if (vOption != null &&
        (rBest == null ||
            vOption.cost < rBest.cost - 1e-9 ||
            ((vOption.cost - rBest.cost).abs() < 1e-9 && vOption.pots < rBest.pots))) {
      rBest = vOption;
    }
  }

  return rBest?.combo ?? const {};
}

/// Fournitures de peinture.
class PaintSupplies {
  const PaintSupplies({required this.rollers, required this.dropCloths, required this.tapeRolls});

  /// Un rouleau par produit : on ne lave pas un rouleau entre deux peintures.
  final int rollers;

  /// Bâches de 20 m² pour protéger le sol.
  final int dropCloths;

  /// Rouleaux de ruban de masquage de 50 m.
  final int tapeRolls;
}

const dropClothM2 = 20.0;
const tapeRollMm = 50000;

/// Fournitures pour les produits utilisés : rouleaux, bâches, ruban le long des plinthes, des
/// ouvertures et du plafond s'il n'est pas peint de la même couleur.
PaintSupplies paintSupplies(Room pRoom, PaintSettings pSettings) {
  final vProducts = paintLitres(pRoom, pSettings);
  if (vProducts.isEmpty) {
    return const PaintSupplies(rollers: 0, dropCloths: 0, tapeRolls: 0);
  }
  var vTape = pSettings.walls ? perimeterMm(pRoom) : 0;
  if (pSettings.walls && !pSettings.ceiling) {
    vTape += perimeterMm(pRoom);
  }
  if (pSettings.walls) {
    for (final vWall in pRoom.walls) {
      for (final vOpening in vWall.openings) {
        vTape +=
            2 * vOpening.height + vOpening.widthMm * (vOpening.kind == OpeningKind.window ? 2 : 1);
      }
    }
  }
  final rSupplies = PaintSupplies(
    rollers: vProducts.length,
    dropCloths: (outlineAreaMm2(pRoom) / 1e6 / dropClothM2 - 1e-9).ceil().clamp(1, 1 << 30),
    tapeRolls: (vTape / tapeRollMm - 1e-9).ceil(),
  );

  return rSupplies;
}
