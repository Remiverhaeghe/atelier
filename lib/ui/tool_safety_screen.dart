import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/tool_safety.dart';
import '../logic/units.dart';
import 'height_work_screen.dart';
import 'parquet_view.dart';
import 'sketch3d.dart';
import 'theme.dart';
import 'tool_safety_scenes.dart';
import 'work_sheet_pdf.dart';

/// Sécurité par outil : une fiche par outil ou produit.
class ToolSafetyScreen extends StatelessWidget {
  const ToolSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.toolSafetyTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(vText.toolSafetyIntro, style: Theme.of(context).textTheme.bodyMedium),
          ),
          for (final vTool in SafetyTool.values)
            Card(
              child: ListTile(
                leading: const Icon(Icons.health_and_safety_outlined),
                title: Text(safetyToolName(vText, vTool)),
                subtitle: Text(safetyToolRisk(vText, vTool)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => ToolSafetySheet(tool: vTool)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Fiche d'un outil : schéma, protections, vérifications à cocher et gestes interdits.
class ToolSafetySheet extends StatefulWidget {
  const ToolSafetySheet({super.key, required this.tool});

  final SafetyTool tool;

  @override
  State<ToolSafetySheet> createState() => _ToolSafetySheetState();
}

class _ToolSafetySheetState extends State<ToolSafetySheet> {
  final _done = <int>{};
  var _heightMm = 3000;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vTool = widget.tool;
    final vScene = safetyScene(vText, vTool);
    final vChecks = safetyChecks(vText, vTool);
    final vForbidden = safetyForbidden(vText, vTool);
    final vChecksTitle = switch (vTool) {
      SafetyTool.ladder => vText.toolSafeChecksClimb,
      SafetyTool.finishes => vText.toolSafeChecksOpen,
      _ => vText.toolSafeChecksPower,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(safetyToolName(vText, vTool)),
        actions: [
          PrintSheetButton(
            sheet: () => (
              title: safetyToolName(vText, vTool),
              intro: safetyToolRisk(vText, vTool),
              measures: const [],
              results: [
                '${vText.toolSafeProtections} : '
                    '${vTool.protections.map((pItem) => protectionName(vText, pItem)).join(', ')}',
                for (final vNo in vForbidden) '${vText.toolSafeForbidden} : $vNo',
              ],
              buy: const [],
              steps: vChecks,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: Sketch3D(parts: vScene.parts, callouts: vScene.callouts),
          ),
          IconLine(
            Icons.warning_amber,
            safetyToolRisk(vText, vTool),
            color: vTheme.colorScheme.error,
          ),
          const SizedBox(height: 8),
          Text(vText.toolSafeProtections, style: vTheme.textTheme.titleMedium),
          Wrap(
            spacing: 8,
            children: [
              for (final vItem in vTool.protections)
                Chip(
                  avatar: const Icon(Icons.shield_outlined, size: 18),
                  label: Text(protectionName(vText, vItem)),
                ),
            ],
          ),
          if (vTool.noLooseGloves) IconLine(Icons.back_hand_outlined, vText.toolSafeNoGloves),
          if (vTool.noisy) IconLine(Icons.volume_up_outlined, vText.toolSafeNoisy),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Text(vChecksTitle, style: vTheme.textTheme.titleMedium),
                ),
                for (final (vIndex, vCheck) in vChecks.indexed)
                  CheckboxListTile(
                    value: _done.contains(vIndex),
                    onChanged: (pValue) =>
                        setState(() => pValue == true ? _done.add(vIndex) : _done.remove(vIndex)),
                    title: Text(vCheck),
                  ),
                if (readyToStart(vTool, _done))
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: IconLine(Icons.check_circle_outline, vText.toolSafeReady),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(vText.toolSafeForbidden, style: vTheme.textTheme.titleMedium),
          for (final vNo in vForbidden)
            IconLine(Icons.block, vNo, color: vTheme.colorScheme.error),
          if (vTool == SafetyTool.ladder) ...[
            NumberField(
              label: vText.toolSafeLadderHeight,
              initial: formatCentimetres(_heightMm),
              parse: parseCentimetres,
              onValue: (pValue) => setState(() => _heightMm = pValue),
            ),
            const SizedBox(height: 8),
            IconLine(
              Icons.straighten,
              vText.toolSafeLadderResult(
                formatCentimetres(ladderFootMm(_heightMm)),
                formatCentimetres(ladderLengthMm(_heightMm)),
                formatCentimetres(ladderLengthMm(_heightMm, pStepOff: true)),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const HeightWorkScreen()),
                ),
                icon: const Icon(Icons.stairs_outlined),
                label: Text(vText.toolSafeLadderLink),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String safetyToolName(AppLocalizations pText, SafetyTool pTool) => switch (pTool) {
  SafetyTool.circularSaw => pText.toolSafeCircularSaw,
  SafetyTool.router => pText.toolSafeRouter,
  SafetyTool.grinder => pText.toolSafeGrinder,
  SafetyTool.ladder => pText.toolSafeLadder,
  SafetyTool.finishes => pText.toolSafeFinishes,
};

String safetyToolRisk(AppLocalizations pText, SafetyTool pTool) => switch (pTool) {
  SafetyTool.circularSaw => pText.toolSafeCircularSawRisk,
  SafetyTool.router => pText.toolSafeRouterRisk,
  SafetyTool.grinder => pText.toolSafeGrinderRisk,
  SafetyTool.ladder => pText.toolSafeLadderRisk,
  SafetyTool.finishes => pText.toolSafeFinishesRisk,
};

/// Vérifications de la fiche, dans l'ordre ; leur nombre est celui de [SafetyTool.checks].
List<String> safetyChecks(AppLocalizations pText, SafetyTool pTool) => switch (pTool) {
  SafetyTool.circularSaw => [
    pText.toolSafeCircularSawCheck1,
    pText.toolSafeCircularSawCheck2,
    pText.toolSafeCircularSawCheck3,
    pText.toolSafeCircularSawCheck4,
  ],
  SafetyTool.router => [
    pText.toolSafeRouterCheck1,
    pText.toolSafeRouterCheck2,
    pText.toolSafeRouterCheck3,
    pText.toolSafeRouterCheck4,
  ],
  SafetyTool.grinder => [
    pText.toolSafeGrinderCheck1,
    pText.toolSafeGrinderCheck2,
    pText.toolSafeGrinderCheck3,
    pText.toolSafeGrinderCheck4,
  ],
  SafetyTool.ladder => [
    pText.toolSafeLadderCheck1,
    pText.toolSafeLadderCheck2,
    pText.toolSafeLadderCheck3,
    pText.toolSafeLadderCheck4,
  ],
  SafetyTool.finishes => [
    pText.toolSafeFinishesCheck1,
    pText.toolSafeFinishesCheck2,
    pText.toolSafeFinishesCheck3,
    pText.toolSafeFinishesCheck4,
  ],
};

/// Gestes interdits de la fiche ; leur nombre est celui de [SafetyTool.forbidden].
List<String> safetyForbidden(AppLocalizations pText, SafetyTool pTool) => switch (pTool) {
  SafetyTool.circularSaw => [
    pText.toolSafeCircularSawNo1,
    pText.toolSafeCircularSawNo2,
    pText.toolSafeCircularSawNo3,
    pText.toolSafeCircularSawNo4,
  ],
  SafetyTool.router => [
    pText.toolSafeRouterNo1,
    pText.toolSafeRouterNo2,
    pText.toolSafeRouterNo3,
  ],
  SafetyTool.grinder => [
    pText.toolSafeGrinderNo1,
    pText.toolSafeGrinderNo2,
    pText.toolSafeGrinderNo3,
    pText.toolSafeGrinderNo4,
  ],
  SafetyTool.ladder => [
    pText.toolSafeLadderNo1,
    pText.toolSafeLadderNo2,
    pText.toolSafeLadderNo3,
    pText.toolSafeLadderNo4,
  ],
  SafetyTool.finishes => [
    pText.toolSafeFinishesNo1,
    pText.toolSafeFinishesNo2,
    pText.toolSafeFinishesNo3,
  ],
};

String protectionName(AppLocalizations pText, Protection pItem) => switch (pItem) {
  Protection.glasses => pText.protectGlasses,
  Protection.faceShield => pText.protectFaceShield,
  Protection.earmuffs => pText.protectEarmuffs,
  Protection.dustMask => pText.protectDustMask,
  Protection.vapourMask => pText.protectVapourMask,
  Protection.cutGloves => pText.protectCutGloves,
  Protection.chemicalGloves => pText.protectChemicalGloves,
  Protection.safetyShoes => pText.protectSafetyShoes,
  Protection.fittedClothes => pText.protectFittedClothes,
};
