/// Modèles de chantier : une liste d'étapes types à ajouter d'un coup aux reprises d'une pièce.
library;

/// Étapes courantes, dans l'ordre où on les fait.
enum TemplateStep {
  protect,
  fillHoles,
  sandWalls,
  undercoat,
  ceilingPaint,
  wallPaint,
  woodworkPaint,
  removeTiles,
  waterproof,
  tileFloor,
  tileWalls,
  grout,
  siliconeJoints,
  removeFloor,
  levelFloor,
  layFloor,
  baseboards,
  sealBaseboards,
}

/// Modèles proposés, avec leurs étapes et le nombre de passages de chacune.
enum WorkTemplate {
  refreshRoom([
    (TemplateStep.protect, 1),
    (TemplateStep.fillHoles, 2),
    (TemplateStep.sandWalls, 1),
    (TemplateStep.undercoat, 1),
    (TemplateStep.ceilingPaint, 2),
    (TemplateStep.wallPaint, 2),
    (TemplateStep.woodworkPaint, 2),
  ]),
  bathroom([
    (TemplateStep.protect, 1),
    (TemplateStep.removeTiles, 1),
    (TemplateStep.waterproof, 2),
    (TemplateStep.tileFloor, 1),
    (TemplateStep.tileWalls, 1),
    (TemplateStep.grout, 1),
    (TemplateStep.siliconeJoints, 1),
  ]),
  newFloor([
    (TemplateStep.removeFloor, 1),
    (TemplateStep.levelFloor, 1),
    (TemplateStep.layFloor, 1),
    (TemplateStep.baseboards, 1),
    (TemplateStep.sealBaseboards, 1),
  ]);

  const WorkTemplate(this.steps);

  final List<(TemplateStep, int)> steps;
}

/// Étapes du modèle qui ne sont pas déjà dans la pièce (même libellé), pour ne pas doubler.
List<(TemplateStep, int)> missingSteps(
  WorkTemplate pTemplate,
  Set<String> pExisting,
  String Function(TemplateStep) pLabel,
) => [
  for (final vStep in pTemplate.steps)
    if (!pExisting.contains(pLabel(vStep.$1))) vStep,
];
