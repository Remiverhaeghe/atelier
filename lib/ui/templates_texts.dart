import '../l10n/gen/app_localizations.dart';
import '../logic/work_templates.dart';

String templateLabel(AppLocalizations pText, WorkTemplate pTemplate) => switch (pTemplate) {
  WorkTemplate.refreshRoom => pText.templateRefresh,
  WorkTemplate.bathroom => pText.templateBathroom,
  WorkTemplate.newFloor => pText.templateFloor,
};

String templateStepLabel(AppLocalizations pText, TemplateStep pStep) => switch (pStep) {
  TemplateStep.protect => pText.stepProtect,
  TemplateStep.fillHoles => pText.stepFillHoles,
  TemplateStep.sandWalls => pText.stepSandWalls,
  TemplateStep.undercoat => pText.stepUndercoat,
  TemplateStep.ceilingPaint => pText.stepCeilingPaint,
  TemplateStep.wallPaint => pText.stepWallPaint,
  TemplateStep.woodworkPaint => pText.stepWoodworkPaint,
  TemplateStep.removeTiles => pText.stepRemoveTiles,
  TemplateStep.waterproof => pText.stepWaterproof,
  TemplateStep.tileFloor => pText.stepTileFloor,
  TemplateStep.tileWalls => pText.stepTileWalls,
  TemplateStep.grout => pText.stepGrout,
  TemplateStep.siliconeJoints => pText.stepSilicone,
  TemplateStep.removeFloor => pText.stepRemoveFloor,
  TemplateStep.levelFloor => pText.stepLevelFloor,
  TemplateStep.layFloor => pText.stepLayFloor,
  TemplateStep.baseboards => pText.stepBaseboards,
  TemplateStep.sealBaseboards => pText.stepSealBaseboards,
};
