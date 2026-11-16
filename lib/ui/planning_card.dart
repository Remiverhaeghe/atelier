import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/planning.dart';
import '../logic/worksite.dart';
import 'theme.dart';

/// Nom d'une phase de travaux.
String phaseLabel(AppLocalizations pText, WorkPhase pPhase) => switch (pPhase) {
  WorkPhase.touchUps => pText.phaseTouchUps,
  WorkPhase.ceiling => pText.phaseCeiling,
  WorkPhase.walls => pText.phaseWalls,
  WorkPhase.woodwork => pText.phaseWoodwork,
  WorkPhase.parquet => pText.phaseParquet,
  WorkPhase.baseboards => pText.phaseBaseboards,
  WorkPhase.sealing => pText.phaseSealing,
};

/// Prochaine étape de chaque pièce, avec le séchage à respecter avant de l'attaquer.
class PlanningCard extends StatelessWidget {
  const PlanningCard({super.key, required this.worksite});

  final Worksite worksite;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vNext = [
      for (final vRoom in worksite.rooms)
        if (nextPhase(vRoom) case final vPhase?) (room: vRoom.name, phase: vPhase),
    ];
    final vProblems = [
      for (final vRoom in worksite.rooms)
        for (final vProblem in orderProblems(vRoom)) (room: vRoom.name, problem: vProblem),
    ];
    if (vNext.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.planningTitle, style: vTheme.textTheme.titleMedium),
            const SizedBox(height: 4),
            for (final vEntry in vNext) ...[
              IconLine(
                Icons.arrow_forward,
                vText.planningNext(vEntry.room, phaseLabel(vText, vEntry.phase.next)),
              ),
              if (dryingHours[vEntry.phase.after] case final vHours?)
                Padding(
                  padding: const EdgeInsets.only(left: 30),
                  child: Text(
                    vText.planningDrying(phaseLabel(vText, vEntry.phase.after!), vHours),
                    style: vTheme.textTheme.bodySmall,
                  ),
                ),
            ],
            for (final vEntry in vProblems)
              IconLine(
                AtelierIcons.warning,
                vText.planningOrder(
                  vEntry.room,
                  phaseLabel(vText, vEntry.problem.done),
                  phaseLabel(vText, vEntry.problem.pending),
                ),
              ),
            const SizedBox(height: 4),
            Text(vText.planningHelp, style: vTheme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
