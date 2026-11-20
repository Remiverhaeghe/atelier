import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/mistakes.dart';
import 'gestures_screen.dart';
import 'theme.dart';
import 'work_sheet_pdf.dart';

/// « Je me suis trompé » : les ratés courants, un par carte.
class MistakesScreen extends StatelessWidget {
  const MistakesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.oopsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Text(vText.oopsIntro, style: Theme.of(context).textTheme.bodyMedium),
          ),
          for (final vMistake in Mistake.values)
            Card(
              child: ListTile(
                leading: Icon(_outcomeIcon(vMistake.outcome)),
                title: Text(mistakeName(vText, vMistake)),
                subtitle: Text(mistakeCause(vText, vMistake)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => MistakeScreen(mistake: vMistake)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

IconData _outcomeIcon(MistakeOutcome pOutcome) => switch (pOutcome) {
  MistakeOutcome.repair => Icons.build_circle_outlined,
  MistakeOutcome.reuse => Icons.recycling,
};

/// Un raté : pourquoi, comment réparer, ce qu'on garde, et le geste à revoir.
class MistakeScreen extends StatelessWidget {
  const MistakeScreen({super.key, required this.mistake});

  final Mistake mistake;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vSteps = mistakeSteps(vText, mistake);

    return Scaffold(
      appBar: AppBar(
        title: Text(mistakeName(vText, mistake)),
        actions: [
          PrintSheetButton(
            sheet: () => (
              title: mistakeName(vText, mistake),
              intro: mistakeCause(vText, mistake),
              measures: const [],
              results: [
                if (mistake.waitHours > 0) vText.oopsWait(mistake.waitHours),
                mistakeReuse(vText, mistake),
              ],
              buy: const [],
              steps: vSteps,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Chip(
            avatar: Icon(_outcomeIcon(mistake.outcome), size: 18),
            label: Text(
              mistake.outcome == MistakeOutcome.repair ? vText.oopsRepairTag : vText.oopsReuseTag,
            ),
          ),
          Text(vText.oopsCauseTitle, style: vTheme.textTheme.titleSmall),
          Text(mistakeCause(vText, mistake), style: vTheme.textTheme.bodyLarge),
          const SizedBox(height: 12),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vText.oopsFixTitle, style: vTheme.textTheme.titleMedium),
                  if (mistake.waitHours > 0)
                    IconLine(Icons.hourglass_top, vText.oopsWait(mistake.waitHours)),
                  for (final (vIndex, vStep) in vSteps.indexed)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text('${vIndex + 1}. $vStep', style: vTheme.textTheme.bodyMedium),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(vText.oopsReuseTitle, style: vTheme.textTheme.titleSmall),
          IconLine(Icons.recycling, mistakeReuse(vText, mistake)),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => GestureScreen(gesture: mistake.gesture)),
              ),
              icon: const Icon(Icons.play_circle_outline),
              label: Text(vText.oopsGesture(gestureName(vText, mistake.gesture))),
            ),
          ),
        ],
      ),
    );
  }
}

String mistakeName(AppLocalizations pText, Mistake pMistake) => switch (pMistake) {
  Mistake.looseTenon => pText.oopsLooseTenon,
  Mistake.warpedBoard => pText.oopsWarpedBoard,
  Mistake.misplacedHole => pText.oopsMisplacedHole,
  Mistake.varnishRun => pText.oopsVarnishRun,
  Mistake.failedSealant => pText.oopsFailedSealant,
  Mistake.shortCut => pText.oopsShortCut,
};

String mistakeCause(AppLocalizations pText, Mistake pMistake) => switch (pMistake) {
  Mistake.looseTenon => pText.oopsLooseTenonCause,
  Mistake.warpedBoard => pText.oopsWarpedBoardCause,
  Mistake.misplacedHole => pText.oopsMisplacedHoleCause,
  Mistake.varnishRun => pText.oopsVarnishRunCause,
  Mistake.failedSealant => pText.oopsFailedSealantCause,
  Mistake.shortCut => pText.oopsShortCutCause,
};

/// Étapes de réparation ; leur nombre est celui de [Mistake.steps].
List<String> mistakeSteps(AppLocalizations pText, Mistake pMistake) => switch (pMistake) {
  Mistake.looseTenon => [pText.oopsLooseTenon1, pText.oopsLooseTenon2, pText.oopsLooseTenon3],
  Mistake.warpedBoard => [pText.oopsWarpedBoard1, pText.oopsWarpedBoard2, pText.oopsWarpedBoard3],
  Mistake.misplacedHole => [
    pText.oopsMisplacedHole1,
    pText.oopsMisplacedHole2,
    pText.oopsMisplacedHole3,
  ],
  Mistake.varnishRun => [pText.oopsVarnishRun1, pText.oopsVarnishRun2, pText.oopsVarnishRun3],
  Mistake.failedSealant => [
    pText.oopsFailedSealant1,
    pText.oopsFailedSealant2,
    pText.oopsFailedSealant3,
  ],
  Mistake.shortCut => [pText.oopsShortCut1, pText.oopsShortCut2, pText.oopsShortCut3],
};

String mistakeReuse(AppLocalizations pText, Mistake pMistake) => switch (pMistake) {
  Mistake.looseTenon => pText.oopsLooseTenonReuse,
  Mistake.warpedBoard => pText.oopsWarpedBoardReuse,
  Mistake.misplacedHole => pText.oopsMisplacedHoleReuse,
  Mistake.varnishRun => pText.oopsVarnishRunReuse,
  Mistake.failedSealant => pText.oopsFailedSealantReuse,
  Mistake.shortCut => pText.oopsShortCutReuse,
};
