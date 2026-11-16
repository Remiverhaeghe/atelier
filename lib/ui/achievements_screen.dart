import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/achievements.dart';
import '../logic/worksite.dart';
import 'theme.dart';

/// Icône d'un badge.
IconData achievementIcon(Achievement pAchievement) => switch (pAchievement) {
  Achievement.firstRow => AtelierIcons.parquet,
  Achievement.roomDone => Icons.meeting_room_outlined,
  Achievement.allBaseboardsCut => AtelierIcons.baseboard,
  Achievement.tenTouchUps => AtelierIcons.touchUps,
  Achievement.firstGoal => Icons.flag_outlined,
  Achievement.fiveGoals => Icons.emoji_events_outlined,
  Achievement.fullBudget => Icons.euro,
};

/// Nom et condition d'un badge.
(String, String) achievementTexts(AppLocalizations pText, Achievement pAchievement) =>
    switch (pAchievement) {
      Achievement.firstRow => (pText.badgeFirstRow, pText.badgeFirstRowHelp),
      Achievement.roomDone => (pText.badgeRoomDone, pText.badgeRoomDoneHelp),
      Achievement.allBaseboardsCut => (pText.badgeBaseboards, pText.badgeBaseboardsHelp),
      Achievement.tenTouchUps => (pText.badgeTouchUps, pText.badgeTouchUpsHelp),
      Achievement.firstGoal => (pText.badgeFirstGoal, pText.badgeFirstGoalHelp),
      Achievement.fiveGoals => (pText.badgeFiveGoals, pText.badgeFiveGoalsHelp),
      Achievement.fullBudget => (pText.badgeBudget, pText.badgeBudgetHelp),
    };

/// Badges du chantier : gagnés en couleur, à gagner en gris avec leur condition.
class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key, required this.worksite});

  final Worksite worksite;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vEarned = earnedAchievements(worksite);

    return Scaffold(
      appBar: AppBar(title: Text(vText.badgesTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          ListTile(
            title: Text(
              vText.badgesProgress(vEarned.length, Achievement.values.length),
              style: vTheme.textTheme.titleMedium,
            ),
          ),
          for (final vAchievement in Achievement.values)
            Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: vEarned.contains(vAchievement)
                      ? AtelierColors.of(context).tape
                      : vTheme.colorScheme.surfaceContainerHigh,
                  foregroundColor: vEarned.contains(vAchievement)
                      ? AtelierColors.of(context).onTape
                      : vTheme.colorScheme.outline,
                  child: Icon(achievementIcon(vAchievement)),
                ),
                title: Text(achievementTexts(vText, vAchievement).$1),
                subtitle: Text(achievementTexts(vText, vAchievement).$2),
                trailing: vEarned.contains(vAchievement)
                    ? Icon(Icons.check, color: vTheme.colorScheme.primary)
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
