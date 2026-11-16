/// Guidage de la pose : étapes dans l'ordre et outils à préparer, selon le parquet et la fixation.
library;

import 'baseboard.dart';
import 'parquet.dart';

enum GuideStep {
  acclimatise,
  prepareFloor,
  unrollUnderlay,
  spreadGlue,
  fixJoists,
  traceAxis,
  firstRow,
  spacers,
  nailInTongue,
  lastRow,
  removeSpacers,
  cutBaseboards,
  dryFitCorners,
  fixBaseboards,
  sealJoints,
}

enum Tool {
  tapeMeasure,
  pencilSquare,
  miterSaw,
  jigsaw,
  spacers,
  tappingBlock,
  pullBar,
  notchedTrowel,
  nailer,
  chalkLine,
  caulkGun,
  level,
}

/// Étapes de pose du parquet, de la préparation à la dernière rangée.
List<GuideStep> parquetSteps(ParquetType pType) => [
  GuideStep.acclimatise,
  GuideStep.prepareFloor,
  if (parquetDefaults[pType]!.needsUnderlay) GuideStep.unrollUnderlay,
  if (pType == ParquetType.glued) GuideStep.spreadGlue,
  if (pType == ParquetType.nailed) GuideStep.fixJoists,
  // Le motif part d'un axe tracé au centre de la pièce, pas d'un mur.
  if (pType == ParquetType.herringbone) GuideStep.traceAxis else GuideStep.firstRow,
  GuideStep.spacers,
  if (pType == ParquetType.nailed) GuideStep.nailInTongue,
  GuideStep.lastRow,
  GuideStep.removeSpacers,
];

/// Étapes de pose des plinthes, après le parquet.
List<GuideStep> baseboardSteps(BaseboardFixing pFixing) => [
  GuideStep.cutBaseboards,
  GuideStep.dryFitCorners,
  GuideStep.fixBaseboards,
  if (pFixing != BaseboardFixing.clips) GuideStep.sealJoints,
];

/// Outils à préparer, sans doublon, dans l'ordre d'utilisation.
List<Tool> toolsFor(ParquetType pType, BaseboardFixing pFixing) {
  final rTools = <Tool>{
    Tool.tapeMeasure,
    Tool.pencilSquare,
    if (pType == ParquetType.herringbone) Tool.chalkLine,
    if (pType == ParquetType.glued) Tool.notchedTrowel,
    if (pType == ParquetType.nailed) Tool.nailer,
    Tool.spacers,
    if (pType == ParquetType.floating || pType == ParquetType.herringbone) ...[
      Tool.tappingBlock,
      Tool.pullBar,
    ],
    Tool.jigsaw,
    Tool.miterSaw,
    if (pFixing == BaseboardFixing.glued) Tool.caulkGun,
    if (pFixing == BaseboardFixing.nailed) Tool.nailer,
    Tool.level,
  }.toList();

  return rTools;
}
