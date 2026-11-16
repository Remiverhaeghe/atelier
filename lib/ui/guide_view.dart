import 'dart:io';

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/guidance.dart';
import '../logic/inventory.dart';
import '../logic/room.dart';
import 'photos.dart';
import 'tips_screen.dart';

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
  GuideStep.undercutCasings => pText.stepUndercutCasings,
  GuideStep.fitThresholds => pText.stepFitThresholds,
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
  Tool.jigsaw => Icons.carpenter,
  Tool.spacers => Icons.space_bar,
  Tool.tappingBlock => Icons.hardware_outlined,
  Tool.pullBar => Icons.keyboard_tab,
  Tool.notchedTrowel => Icons.texture,
  Tool.nailer => Icons.push_pin_outlined,
  Tool.chalkLine => Icons.timeline,
  Tool.caulkGun => Icons.colorize,
  Tool.level => Icons.horizontal_rule,
  Tool.handSaw => Icons.carpenter,
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
  Tool.handSaw => pText.toolHandSaw,
};

/// Étapes de pose à cocher et outils à préparer pour la pièce.
class GuideView extends StatelessWidget {
  const GuideView({
    super.key,
    required this.room,
    required this.onChanged,
    this.ownedTools = const [],
    this.onToolOwned,
    this.photos,
  });

  final Room room;
  final ValueChanged<Room> onChanged;

  /// Outils déjà là, cochés dans la liste ; [onToolOwned] met l'inventaire à jour.
  final List<String> ownedTools;
  final void Function(Tool pTool, bool pOwned)? onToolOwned;

  /// Prise de photo ; remplaçable dans les tests.
  final PhotoTaker? photos;

  /// Photo de l'étape ajoutée à celles de la pièce.
  Future<void> _photo(GuideStep pStep) async {
    final vPath = await (photos ?? takePhoto)('${room.id}-${pStep.name}');
    if (vPath != null) {
      onChanged(
        room.copyWith(
          stepPhotos: {
            ...room.stepPhotos,
            pStep.name: [...?room.stepPhotos[pStep.name], vPath],
          },
        ),
      );
    }
  }

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
    final vMissing = missingTools(room, ownedTools);

    Widget vStep(GuideStep pStep) {
      final vPhotos = room.stepPhotos[pStep.name] ?? const <String>[];

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CheckboxListTile(
            value: room.doneSteps.contains(pStep.name),
            onChanged: (pValue) => _toggle(pStep, pValue ?? false),
            title: Text(stepLabel(vText, pStep)),
            secondary: IconButton(
              tooltip: vText.stepPhoto,
              icon: Icon(vPhotos.isEmpty ? Icons.add_a_photo_outlined : Icons.photo_library_outlined),
              onPressed: () => _photo(pStep),
            ),
          ),
          if (vPhotos.isNotEmpty)
            SizedBox(
              height: 64,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final vPath in vPhotos)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => showPhoto(context, vPath),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            File(vPath),
                            width: 64,
                            height: 64,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        ListTile(title: Text(vText.guideProgress(vDone, vAll.length))),
        ListTile(
          leading: Icon(Icons.tips_and_updates_outlined, color: vTheme.colorScheme.primary),
          title: Text(vText.tipsLink),
          trailing: const Icon(Icons.chevron_right),
          onTap: () =>
              Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const TipsScreen())),
        ),
        ListTile(title: Text(vText.guideTools, style: vTheme.textTheme.titleMedium)),
        ListTile(
          dense: true,
          leading: Icon(
            vMissing.isEmpty ? Icons.check_circle_outline : Icons.shopping_cart_outlined,
            color: vTheme.colorScheme.primary,
          ),
          title: Text(
            ownedTools.isEmpty
                ? vText.toolsCheckHelp
                : vMissing.isEmpty
                ? vText.toolsAllThere
                : vText.toolsMissing(vMissing.length),
          ),
        ),
        for (final vTool in toolsFor(room.parquet.type, room.baseboard.fixing))
          CheckboxListTile(
            dense: true,
            secondary: Icon(toolIcon(vTool), color: vTheme.colorScheme.primary),
            title: Text(toolLabel(vText, vTool)),
            value: ownedTools.contains(vTool.name),
            onChanged: onToolOwned == null
                ? null
                : (pValue) => onToolOwned!(vTool, pValue ?? false),
          ),
        ListTile(title: Text(vText.guideParquet, style: vTheme.textTheme.titleMedium)),
        for (final vItem in vParquet) vStep(vItem),
        ListTile(title: Text(vText.guideBaseboard, style: vTheme.textTheme.titleMedium)),
        for (final vItem in vBaseboard) vStep(vItem),
      ],
    );
  }
}
