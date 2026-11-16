import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/decisions.dart';
import 'theme.dart';

/// Question posée.
String decisionLabel(AppLocalizations pText, Decision pDecision) => switch (pDecision) {
  Decision.baseboardFixing => pText.decisionBaseboard,
  Decision.parquetLaying => pText.decisionParquet,
  Decision.damagedWall => pText.decisionWall,
};

/// Nom, points forts et points faibles d'une façon de faire.
(String, String, String) optionTexts(AppLocalizations pText, DecisionOption pOption) =>
    switch (pOption) {
      DecisionOption.glueBaseboard => (
        pText.optionGlueBaseboard,
        pText.optionGlueBaseboardPros,
        pText.optionGlueBaseboardCons,
      ),
      DecisionOption.nailBaseboard => (
        pText.optionNailBaseboard,
        pText.optionNailBaseboardPros,
        pText.optionNailBaseboardCons,
      ),
      DecisionOption.clipBaseboard => (
        pText.optionClipBaseboard,
        pText.optionClipBaseboardPros,
        pText.optionClipBaseboardCons,
      ),
      DecisionOption.floatingParquet => (
        pText.optionFloating,
        pText.optionFloatingPros,
        pText.optionFloatingCons,
      ),
      DecisionOption.gluedParquet => (
        pText.optionGlued,
        pText.optionGluedPros,
        pText.optionGluedCons,
      ),
      DecisionOption.nailedParquet => (
        pText.optionNailed,
        pText.optionNailedPros,
        pText.optionNailedCons,
      ),
      DecisionOption.fillWall => (
        pText.optionFillWall,
        pText.optionFillWallPros,
        pText.optionFillWallCons,
      ),
      DecisionOption.lineWall => (
        pText.optionLineWall,
        pText.optionLineWallPros,
        pText.optionLineWallCons,
      ),
    };

/// Comparaison des façons de faire, question par question.
class DecisionsScreen extends StatelessWidget {
  const DecisionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.decisionsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          ListTile(subtitle: Text(vText.decisionsHelp)),
          for (final vDecision in Decision.values) ...[
            ListTile(
              title: Text(decisionLabel(vText, vDecision), style: vTheme.textTheme.titleMedium),
            ),
            for (final vOption in optionsFor(vDecision))
              _OptionCard(option: vOption, simplest: simplestOption(vDecision) == vOption),
          ],
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  const _OptionCard({required this.option, required this.simplest});

  final DecisionOption option;
  final bool simplest;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final (vName, vPros, vCons) = optionTexts(vText, option);
    Widget vScore(String pLabel, int pValue) => Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Semantics(
        label: vText.scoreLabel(pLabel, pValue),
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('$pLabel '),
              for (var vDot = 1; vDot <= 3; vDot++)
                Icon(
                  vDot <= pValue ? Icons.circle : Icons.circle_outlined,
                  size: 10,
                  color: vTheme.colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(vName, style: vTheme.textTheme.titleMedium)),
                if (simplest)
                  Text(
                    vText.simplestOption,
                    style: vTheme.textTheme.labelMedium!.copyWith(
                      color: vTheme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Wrap(
              runSpacing: 4,
              children: [
                vScore(vText.scoreCost, option.cost),
                vScore(vText.scoreTime, option.time),
                vScore(vText.scoreDifficulty, option.difficulty),
              ],
            ),
            const SizedBox(height: 6),
            IconLine(Icons.add_circle_outline, vPros),
            IconLine(Icons.remove_circle_outline, vCons, color: vTheme.colorScheme.error),
            if (option.removable) IconLine(Icons.autorenew, vText.optionRemovable),
          ],
        ),
      ),
    );
  }
}
