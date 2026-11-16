/// Parquet : réglages d'une pièce, quantités à acheter et découpage en rangées.
library;

import 'dart:math' as math;

import 'geometry.dart';
import 'room.dart';

/// Types de parquet, chacun avec ses valeurs de départ.
enum ParquetType { floating, glued, nailed, herringbone }

/// Valeurs de départ d'un type ; la notice du fabricant l'emporte, tout reste modifiable.
class ParquetDefaults {
  const ParquetDefaults({
    required this.expansionGapMm,
    required this.wastePercent,
    required this.needsUnderlay,
    this.needsGlue = false,
    this.needsNails = false,
  });

  final int expansionGapMm;
  final int wastePercent;
  final bool needsUnderlay;
  final bool needsGlue;
  final bool needsNails;
}

const parquetDefaults = {
  ParquetType.floating: ParquetDefaults(expansionGapMm: 8, wastePercent: 5, needsUnderlay: true),
  ParquetType.glued: ParquetDefaults(
    expansionGapMm: 5,
    wastePercent: 5,
    needsUnderlay: false,
    needsGlue: true,
  ),
  ParquetType.nailed: ParquetDefaults(
    expansionGapMm: 12,
    wastePercent: 7,
    needsUnderlay: false,
    needsNails: true,
  ),
  // Pose en motif : coupes en angle sur tout le pourtour, davantage de chutes.
  ParquetType.herringbone: ParquetDefaults(
    expansionGapMm: 8,
    wastePercent: 12,
    needsUnderlay: true,
  ),
};

/// Réglages du parquet d'une pièce.
class ParquetSettings {
  const ParquetSettings({
    this.type = ParquetType.floating,
    this.plankLengthMm = 1380,
    this.plankWidthMm = 193,
    this.packAreaM2 = 2.13,
    this.layingWallIndex = 0,
    this.expansionGapMm = 8,
    this.wastePercent = 5,
    this.minJointOffsetMm = 300,
    this.underlayRollAreaM2 = 15,
    this.glueCoverageM2 = 15,
    this.nailsPerM2 = 30,
    this.nailsPerBox = 500,
    this.thresholdBarLengthMm = 930,
  });

  /// Réglages d'un type, avec ses valeurs de départ.
  factory ParquetSettings.forType(
    ParquetType pType, {
    ParquetSettings pBase = const ParquetSettings(),
  }) {
    final vDefaults = parquetDefaults[pType]!;
    final rSettings = pBase.copyWith(
      type: pType,
      expansionGapMm: vDefaults.expansionGapMm,
      wastePercent: vDefaults.wastePercent,
    );

    return rSettings;
  }

  final ParquetType type;
  final int plankLengthMm;
  final int plankWidthMm;

  /// Surface couverte par un paquet, en m², indiquée sur l'emballage.
  final double packAreaM2;

  /// Les lames sont posées parallèlement à ce mur.
  final int layingWallIndex;
  final int expansionGapMm;
  final int wastePercent;

  /// Écart minimal entre les joints de deux rangées voisines.
  final int minJointOffsetMm;
  final double underlayRollAreaM2;

  /// Surface encollée par un seau de colle.
  final double glueCoverageM2;
  final int nailsPerM2;
  final int nailsPerBox;

  /// Longueur d'une barre de seuil vendue, recoupée à la largeur de la porte.
  final int thresholdBarLengthMm;

  ParquetDefaults get defaults => parquetDefaults[type]!;

  ParquetSettings copyWith({
    ParquetType? type,
    int? plankLengthMm,
    int? plankWidthMm,
    double? packAreaM2,
    int? layingWallIndex,
    int? expansionGapMm,
    int? wastePercent,
    int? minJointOffsetMm,
    double? underlayRollAreaM2,
    double? glueCoverageM2,
    int? nailsPerM2,
    int? nailsPerBox,
    int? thresholdBarLengthMm,
  }) => ParquetSettings(
    type: type ?? this.type,
    plankLengthMm: plankLengthMm ?? this.plankLengthMm,
    plankWidthMm: plankWidthMm ?? this.plankWidthMm,
    packAreaM2: packAreaM2 ?? this.packAreaM2,
    layingWallIndex: layingWallIndex ?? this.layingWallIndex,
    expansionGapMm: expansionGapMm ?? this.expansionGapMm,
    wastePercent: wastePercent ?? this.wastePercent,
    minJointOffsetMm: minJointOffsetMm ?? this.minJointOffsetMm,
    underlayRollAreaM2: underlayRollAreaM2 ?? this.underlayRollAreaM2,
    glueCoverageM2: glueCoverageM2 ?? this.glueCoverageM2,
    nailsPerM2: nailsPerM2 ?? this.nailsPerM2,
    nailsPerBox: nailsPerBox ?? this.nailsPerBox,
    thresholdBarLengthMm: thresholdBarLengthMm ?? this.thresholdBarLengthMm,
  );

  Map<String, Object?> toJson() => {
    'type': type.name,
    'plankLengthMm': plankLengthMm,
    'plankWidthMm': plankWidthMm,
    'packAreaM2': packAreaM2,
    'layingWallIndex': layingWallIndex,
    'expansionGapMm': expansionGapMm,
    'wastePercent': wastePercent,
    'minJointOffsetMm': minJointOffsetMm,
    'underlayRollAreaM2': underlayRollAreaM2,
    'glueCoverageM2': glueCoverageM2,
    'nailsPerM2': nailsPerM2,
    'nailsPerBox': nailsPerBox,
    'thresholdBarLengthMm': thresholdBarLengthMm,
  };

  static ParquetSettings fromJson(Map<String, Object?> pJson) {
    const vBase = ParquetSettings();
    final rSettings = ParquetSettings(
      type: ParquetType.values.byName(pJson['type']! as String),
      plankLengthMm: (pJson['plankLengthMm'] as int?) ?? vBase.plankLengthMm,
      plankWidthMm: (pJson['plankWidthMm'] as int?) ?? vBase.plankWidthMm,
      packAreaM2: (pJson['packAreaM2'] as num?)?.toDouble() ?? vBase.packAreaM2,
      layingWallIndex: (pJson['layingWallIndex'] as int?) ?? 0,
      expansionGapMm: (pJson['expansionGapMm'] as int?) ?? vBase.expansionGapMm,
      wastePercent: (pJson['wastePercent'] as int?) ?? vBase.wastePercent,
      minJointOffsetMm: (pJson['minJointOffsetMm'] as int?) ?? vBase.minJointOffsetMm,
      underlayRollAreaM2:
          (pJson['underlayRollAreaM2'] as num?)?.toDouble() ?? vBase.underlayRollAreaM2,
      glueCoverageM2: (pJson['glueCoverageM2'] as num?)?.toDouble() ?? vBase.glueCoverageM2,
      nailsPerM2: (pJson['nailsPerM2'] as int?) ?? vBase.nailsPerM2,
      nailsPerBox: (pJson['nailsPerBox'] as int?) ?? vBase.nailsPerBox,
      thresholdBarLengthMm:
          (pJson['thresholdBarLengthMm'] as int?) ?? vBase.thresholdBarLengthMm,
    );

    return rSettings;
  }
}

/// Découpage de la largeur de la pièce en rangées de lames.
class RowSplit {
  const RowSplit({
    required this.rowCount,
    required this.firstRowWidthMm,
    required this.lastRowWidthMm,
    required this.balanced,
  });

  final int rowCount;
  final int firstRowWidthMm;
  final int lastRowWidthMm;

  /// La première rangée a été recoupée pour que la dernière ne soit pas trop étroite.
  final bool balanced;
}

/// Ce qu'il faut acheter et poser pour le parquet d'une pièce.
class ParquetEstimate {
  const ParquetEstimate({
    required this.floorAreaM2,
    required this.areaWithWasteM2,
    required this.packs,
    required this.planks,
    required this.leftPlanks,
    required this.rightPlanks,
    required this.rows,
    required this.underlayRolls,
    required this.glueBuckets,
    required this.nailBoxes,
  });

  final double floorAreaM2;
  final double areaWithWasteM2;
  final int packs;
  final int planks;

  /// Point de Hongrie et bâton rompu : lames gauches et droites, vendues à part.
  final int leftPlanks;
  final int rightPlanks;
  final RowSplit? rows;
  final int underlayRolls;
  final int glueBuckets;
  final int nailBoxes;
}

/// Une dernière rangée plus étroite que ce tiers de lame est difficile à poser.
const minLastRowFraction = 1 / 3;

/// Évite qu'un calcul flottant fasse passer 6,0000001 au paquet suivant.
int _ceil(double pValue) => (pValue - 1e-9).ceil();

/// Contour tourné pour que le mur de référence soit horizontal : les rangées suivent l'axe x.
List<PlanPoint> alignedOutline(Room pRoom, int pWallIndex) {
  final vPoints = outline(pRoom);
  if (pRoom.walls.isEmpty) {
    return vPoints;
  }
  final vIndex = pWallIndex.clamp(0, pRoom.walls.length - 1);
  final vStart = vPoints[vIndex];
  final vEnd = vPoints[vIndex + 1];
  final vAngle = math.atan2(vEnd.y - vStart.y, vEnd.x - vStart.x);
  final vCos = math.cos(-vAngle);
  final vSin = math.sin(-vAngle);
  final rPoints = [
    for (final vPoint in vPoints)
      PlanPoint(vPoint.x * vCos - vPoint.y * vSin, vPoint.x * vSin + vPoint.y * vCos),
  ];

  return rPoints;
}

/// Rangées sur la largeur de la pièce, perpendiculaire au sens de pose, jeu de dilatation compris.
RowSplit? splitRows(Room pRoom, ParquetSettings pSettings) {
  if (pRoom.walls.length < 3 || pSettings.plankWidthMm <= 0) {
    return null;
  }
  final vPoints = alignedOutline(pRoom, pSettings.layingWallIndex);
  final vYs = vPoints.map((pPoint) => pPoint.y);
  final vDepth =
      (vYs.reduce(math.max) - vYs.reduce(math.min)).round() - 2 * pSettings.expansionGapMm;
  if (vDepth <= 0) {
    return null;
  }
  final vWidth = pSettings.plankWidthMm;
  final vCount = _ceil(vDepth / vWidth);
  final vLast = vDepth - (vCount - 1) * vWidth;
  if (vCount >= 2 && vLast < vWidth * minLastRowFraction) {
    // On recoupe la première rangée pour que les deux rangées de bord aient la même largeur.
    final vEdge = (vDepth - (vCount - 2) * vWidth) ~/ 2;
    final rSplit = RowSplit(
      rowCount: vCount,
      firstRowWidthMm: vEdge,
      lastRowWidthMm: vDepth - (vCount - 2) * vWidth - vEdge,
      balanced: true,
    );

    return rSplit;
  }
  final rSplit = RowSplit(
    rowCount: vCount,
    firstRowWidthMm: vCount == 1 ? vDepth : vWidth,
    lastRowWidthMm: vLast,
    balanced: false,
  );

  return rSplit;
}

/// Quantités de parquet et de fournitures pour une pièce.
ParquetEstimate estimateParquet(Room pRoom, ParquetSettings pSettings) {
  final vArea = floorAreaM2(pRoom);
  final vWithWaste = vArea * (1 + pSettings.wastePercent / 100);
  final vPlankArea = pSettings.plankLengthMm * pSettings.plankWidthMm / 1e6;
  final vPlanks = vPlankArea <= 0 || vArea == 0 ? 0 : _ceil(vWithWaste / vPlankArea);
  final vHerringbone = pSettings.type == ParquetType.herringbone;
  final vDefaults = pSettings.defaults;
  final rEstimate = ParquetEstimate(
    floorAreaM2: vArea,
    areaWithWasteM2: vWithWaste,
    packs: pSettings.packAreaM2 <= 0 || vArea == 0 ? 0 : _ceil(vWithWaste / pSettings.packAreaM2),
    planks: vPlanks,
    leftPlanks: vHerringbone ? (vPlanks + 1) ~/ 2 : 0,
    rightPlanks: vHerringbone ? (vPlanks + 1) ~/ 2 : 0,
    rows: vHerringbone ? null : splitRows(pRoom, pSettings),
    underlayRolls: vDefaults.needsUnderlay && pSettings.underlayRollAreaM2 > 0
        ? _ceil(vArea / pSettings.underlayRollAreaM2)
        : 0,
    glueBuckets: vDefaults.needsGlue && pSettings.glueCoverageM2 > 0
        ? _ceil(vArea / pSettings.glueCoverageM2)
        : 0,
    nailBoxes: vDefaults.needsNails && pSettings.nailsPerBox > 0
        ? _ceil(vArea * pSettings.nailsPerM2 / pSettings.nailsPerBox)
        : 0,
  );

  return rEstimate;
}

/// Barres de seuil à acheter : une ou plusieurs par ouverture cochée, selon sa largeur.
int thresholdBars(Room pRoom, ParquetSettings pSettings) {
  if (pSettings.thresholdBarLengthMm <= 0) {
    return 0;
  }
  var rBars = 0;
  for (final vWall in pRoom.walls) {
    for (final vOpening in vWall.openings.where((pOpening) => pOpening.threshold)) {
      rBars += _ceil(vOpening.widthMm / pSettings.thresholdBarLengthMm);
    }
  }

  return rBars;
}
