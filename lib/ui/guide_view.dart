import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/guidance.dart';
import '../logic/room.dart';

String stepLabel(AppLocalizations pText, GuideStep pStep) => switch (pStep) {
  GuideStep.acclimatise => pText.stepAcclimatise,
  GuideStep.prepareFloor => pText.stepPrepareFloor,
  GuideStep.unrollUnderlay => pText.stepUnrollUnderlay,
  GuideStep.spreadGlue => pText.stepSpreadGlue,
  GuideStep.fixJoists => pText.stepFixJoists,
  GuideStep.traceAxis => pText.stepTraceAxis,
  GuideStep.firstRow => pText.stepFirstRow,
  GuideStep.spacers => pText.stepSpacers,
  GuideStep.nailInTongue => pText.stepNailInTongue,
  GuideStep.lastRow => pText.stepLastRow,
  GuideStep.removeSpacers => pText.stepRemoveSpacers,
  GuideStep.cutBaseboards => pText.stepCutBaseboards,
  GuideStep.dryFitCorners => pText.stepDryFitCorners,
  GuideStep.fixBaseboards => pText.stepFixBaseboards,
  GuideStep.sealJoints => pText.stepSealJoints,
};

/// Icône de l'outil, pour le reconnaître d'un coup d'œil.
IconData toolIcon(Tool pTool) => switch (pTool) {
  Tool.tapeMeasure => Icons.straighten,
  Tool.pencilSquare => Icons.edit_outlined,
  Tool.miterSaw => Icons.carpenter,
  Tool.jigsaw => Icons.content_cut,
  Tool.spacers => Icons.space_bar,
  Tool.tappingBlock => Icons.gavel,
  Tool.pullBar => Icons.horizontal_rule,
  Tool.notchedTrowel => Icons.format_paint_outlined,
  Tool.nailer => Icons.hardware_outlined,
  Tool.chalkLine => Icons.timeline,
  Tool.caulkGun => Icons.colorize,
  Tool.level => Icons.water_drop_outlined,
};

String toolLabel(AppLocalizations pText, Tool pTool) => switch (pTool) {
  Tool.tapeMeasure => pText.toolTapeMeasure,
  Tool.pencilSquare => pText.toolPencilSquare,
  Tool.miterSaw => pText.toolMiterSaw,
  Tool.jigsaw => pText.toolJigsaw,
  Tool.spacers => pText.toolSpacers,
  Tool.tappingBlock => pText.toolTappingBlock,
  Tool.pullBar => pText.toolPullBar,
  Tool.notchedTrowel => pText.toolNotchedTrowel,
  Tool.nailer => pText.toolNailer,
  Tool.chalkLine => pText.toolChalkLine,
  Tool.caulkGun => pText.toolCaulkGun,
  Tool.level => pText.toolLevel,
};

/// Étapes de pose à cocher et outils à préparer pour la pièce.
class GuideView extends StatelessWidget {
  const GuideView({super.key, required this.room, required this.onChanged});

  final Room room;
  final ValueChanged<Room> onChanged;

  void _toggle(GuideStep pStep, bool pDone) {
    final vDone = {...room.doneSteps};
    pDone ? vDone.add(pStep.name) : vDone.remove(pStep.name);
    onChanged(room.copyWith(doneSteps: vDone.toList()..sort()));
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vParquet = parquetSteps(room.parquet.type);
    final vBaseboard = baseboardSteps(room.baseboard.fixing);
    final vAll = [...vParquet, ...vBaseboard];
    final vDone = vAll.where((pStep) => room.doneSteps.contains(pStep.name)).length;

    Widget vStep(GuideStep pStep) => CheckboxListTile(
      value: room.doneSteps.contains(pStep.name),
      onChanged: (pValue) => _toggle(pStep, pValue ?? false),
      title: Text(stepLabel(vText, pStep)),
    );

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        ListTile(title: Text(vText.guideProgress(vDone, vAll.length))),
        ListTile(title: Text(vText.guideTools, style: vTheme.textTheme.titleMedium)),
        for (final vTool in toolsFor(room.parquet.type, room.baseboard.fixing))
          ListTile(
            dense: true,
            leading: Icon(toolIcon(vTool), color: vTheme.colorScheme.primary),
            title: Text(toolLabel(vText, vTool)),
          ),
        ListTile(title: Text(vText.guideParquet, style: vTheme.textTheme.titleMedium)),
        for (final vItem in vParquet) vStep(vItem),
        ListTile(title: Text(vText.guideBaseboard, style: vTheme.textTheme.titleMedium)),
        for (final vItem in vBaseboard) vStep(vItem),
      ],
    );
  }
}
