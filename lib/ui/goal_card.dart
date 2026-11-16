import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/goals.dart';
import '../logic/worksite.dart';
import 'theme.dart';

/// Objectif du jour en haut du chantier : le proposer, le suivre, en changer.
class GoalCard extends StatelessWidget {
  const GoalCard({super.key, required this.worksite, required this.today, required this.onChanged});

  final Worksite worksite;
  final DateTime today;
  final ValueChanged<Worksite> onChanged;

  void _suggest(BuildContext pContext) {
    final vText = AppLocalizations.of(pContext);
    final vGoal = suggestGoal(worksite, today);
    if (vGoal.items.isEmpty) {
      ScaffoldMessenger.of(pContext).showSnackBar(SnackBar(content: Text(vText.goalNothing)));
      return;
    }
    // Un objectif atteint compte pour les badges au moment où on en fixe un nouveau
    final vPrevious = worksite.goal;
    final vReached = vPrevious != null && vPrevious.reached(worksite) ? 1 : 0;
    onChanged(worksite.copyWith(goal: vGoal, goalsReached: worksite.goalsReached + vReached));
  }

  String _itemLabel(AppLocalizations pText, GoalItem pItem) {
    final vRoom = worksite.rooms.where((pRoom) => pRoom.id == pItem.roomId).firstOrNull;
    final vRoomName = vRoom?.name ?? '';
    final rLabel = switch (pItem.kind) {
      GoalKind.touchUp => pText.goalTouchUp(
        vRoomName,
        vRoom?.touchUps.where((pTouchUp) => pTouchUp.id == pItem.touchUpId).firstOrNull?.label ??
            '',
        pItem.targetPasses,
      ),
      GoalKind.rows => pText.goalRows(vRoomName, pItem.numbers.first, pItem.numbers.last),
      GoalKind.pieces => pText.goalPieces(vRoomName, pItem.numbers.length),
    };

    return rLabel;
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vGoal = worksite.goal;
    final vToday = vGoal != null && vGoal.date == goalDate(today);

    return Card(
      color: vTheme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.flag_outlined, color: vTheme.colorScheme.onPrimaryContainer),
                const SizedBox(width: 8),
                Expanded(child: Text(vText.goalTitle, style: vTheme.textTheme.titleMedium)),
                if (vToday)
                  Text(
                    vText.goalProgress(vGoal.doneCount(worksite), vGoal.items.length),
                    style: vTheme.textTheme.labelLarge,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (!vToday)
              Text(vText.goalHelp)
            else ...[
              for (final vItem in vGoal.items)
                IconLine(
                  vItem.isDone(
                        worksite.rooms.where((pRoom) => pRoom.id == vItem.roomId).firstOrNull,
                      )
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  _itemLabel(vText, vItem),
                ),
              if (vGoal.reached(worksite)) ...[
                const SizedBox(height: 4),
                Text(vText.goalReached, style: vTheme.textTheme.titleSmall),
              ],
            ],
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: () => _suggest(context),
              icon: const Icon(Icons.auto_awesome_outlined),
              label: Text(vToday ? vText.goalChange : vText.goalSuggest),
            ),
          ],
        ),
      ),
    );
  }
}
