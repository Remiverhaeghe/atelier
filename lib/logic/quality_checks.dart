/// Contrôles qualité à chaque étape : ce qu'on vérifie, avec quel outil, et l'écart toléré.
///
/// Les tolérances sont des valeurs prudentes, indicatives : le DTU du matériau ou la notice du
/// fabricant passent avant.
library;

/// Étapes d'un chantier, dans l'ordre où on les franchit.
enum QualityStage { layout, framing, support, laying, finish }

/// Façon de mesurer.
enum QualityMethod {
  /// Deux diagonales mesurées : égales, l'ensemble est d'équerre.
  diagonals,

  /// Niveau à bulle ou laser posé à plat : l'écart se lit au bout de la longueur.
  level,

  /// Fil à plomb ou niveau tenu debout : l'écart se lit en bas.
  plumb,

  /// Règle de 2 m posée en tous sens : le plus grand creux sous la règle.
  straightedge,
}

/// Un contrôle : son étape, sa méthode, et l'écart toléré [toleranceMm] sur [overMm].
enum QualityCheck {
  layoutSquare(QualityStage.layout, QualityMethod.diagonals, 1, 1000),
  layoutLevel(QualityStage.layout, QualityMethod.level, 2, 2000),
  studsPlumb(QualityStage.framing, QualityMethod.plumb, 5, 2500),
  frameSquare(QualityStage.framing, QualityMethod.diagonals, 1, 1000),
  floorFlat(QualityStage.support, QualityMethod.straightedge, 5, 2000),
  wallFlat(QualityStage.support, QualityMethod.straightedge, 5, 2000),
  firstRowStraight(QualityStage.laying, QualityMethod.straightedge, 2, 2000),
  shelfLevel(QualityStage.laying, QualityMethod.level, 2, 1000),
  tileLippage(QualityStage.laying, QualityMethod.straightedge, 1, 200),
  doorPlumb(QualityStage.finish, QualityMethod.plumb, 2, 2000),
  finishedWallFlat(QualityStage.finish, QualityMethod.straightedge, 5, 2000);

  const QualityCheck(this.stage, this.method, this.toleranceMm, this.overMm);

  final QualityStage stage;
  final QualityMethod method;
  final int toleranceMm;
  final int overMm;
}

/// Écart toléré sur [pLengthMm], proportionnel à la longueur, jamais sous 1 mm : en dessous,
/// on ne lit plus rien au mètre ni à la règle. Une règle ne mesure que sur sa longueur : la
/// tolérance d'un contrôle à la règle ne grandit pas avec la surface.
int toleranceFor(QualityCheck pCheck, int pLengthMm) {
  final vLength = pCheck.method == QualityMethod.straightedge ? pCheck.overMm : pLengthMm;
  final vScaled = (pCheck.toleranceMm * vLength / pCheck.overMm).round();
  final rTolerance = vScaled < 1 ? 1 : vScaled;

  return rTolerance;
}

/// Résultat d'une mesure : l'écart lu, celui toléré, et si c'est bon.
typedef QualityVerdict = ({int gapMm, int toleranceMm, bool ok});

/// Contrôle d'un écart [pGapMm] lu sur [pLengthMm] (hauteur pour un aplomb, longueur pour un
/// niveau).
QualityVerdict checkGap(QualityCheck pCheck, int pGapMm, int pLengthMm) {
  final vTolerance = toleranceFor(pCheck, pLengthMm);
  final rVerdict = (gapMm: pGapMm.abs(), toleranceMm: vTolerance, ok: pGapMm.abs() <= vTolerance);

  return rVerdict;
}

/// Contrôle par les diagonales : l'écart entre les deux, toléré selon la plus longue.
QualityVerdict checkDiagonals(QualityCheck pCheck, int pFirstMm, int pSecondMm) {
  final vLongest = pFirstMm > pSecondMm ? pFirstMm : pSecondMm;
  final rVerdict = checkGap(pCheck, pFirstMm - pSecondMm, vLongest);

  return rVerdict;
}

/// Préfixe des contrôles cochés, rangés avec les étapes faites de la pièce.
const qualityPrefix = 'quality.';

/// Nom gardé dans les étapes faites de la pièce, et pour ses photos.
String qualityKey(QualityCheck pCheck) => '$qualityPrefix${pCheck.name}';

/// Contrôles cochés parmi les étapes faites [pDone] ; les noms inconnus sont ignorés.
Set<QualityCheck> doneChecks(List<String> pDone) {
  final vByKey = {for (final vCheck in QualityCheck.values) qualityKey(vCheck): vCheck};
  final rDone = <QualityCheck>{for (final vName in pDone) ?vByKey[vName]};

  return rDone;
}

/// Contrôles cochés et contrôles en tout, pour chaque étape.
Map<QualityStage, ({int done, int total})> stageProgress(Set<QualityCheck> pDone) => {
  for (final vStage in QualityStage.values)
    vStage: (
      done: pDone.where((pCheck) => pCheck.stage == vStage).length,
      total: QualityCheck.values.where((pCheck) => pCheck.stage == vStage).length,
    ),
};
