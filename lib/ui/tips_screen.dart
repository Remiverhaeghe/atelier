import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/tips.dart';
import 'decisions_screen.dart';
import 'theme.dart';

/// Nom d'un sujet de fiches.
String tipTopicLabel(AppLocalizations pText, TipTopic pTopic) => switch (pTopic) {
  TipTopic.baseboard => pText.tipTopicBaseboard,
  TipTopic.parquet => pText.tipTopicParquet,
  TipTopic.door => pText.tipTopicDoor,
  TipTopic.airConditioning => pText.tipTopicAirConditioning,
};

IconData tipTopicIcon(TipTopic pTopic) => switch (pTopic) {
  TipTopic.baseboard => AtelierIcons.baseboard,
  TipTopic.parquet => AtelierIcons.parquet,
  TipTopic.door => Icons.door_front_door_outlined,
  TipTopic.airConditioning => Icons.ac_unit,
};

/// Titre, étapes et mise en garde d'une fiche.
({String title, String steps, String? warning}) tipTexts(AppLocalizations pText, Tip pTip) =>
    switch (pTip) {
      Tip.baseboardSealant => (
        title: pText.tipBaseboardSealantTitle,
        steps: pText.tipBaseboardSealantSteps,
        warning: null,
      ),
      Tip.baseboardGlue => (
        title: pText.tipBaseboardGlueTitle,
        steps: pText.tipBaseboardGlueSteps,
        warning: null,
      ),
      Tip.baseboardNails => (
        title: pText.tipBaseboardNailsTitle,
        steps: pText.tipBaseboardNailsSteps,
        warning: pText.tipBaseboardNailsWarning,
      ),
      Tip.crookedWalls => (
        title: pText.tipCrookedWallsTitle,
        steps: pText.tipCrookedWallsSteps,
        warning: null,
      ),
      Tip.parquetMargin => (
        title: pText.tipParquetMarginTitle,
        steps: pText.tipParquetMarginSteps,
        warning: null,
      ),
      Tip.doorSeal => (title: pText.tipDoorSealTitle, steps: pText.tipDoorSealSteps, warning: null),
      Tip.airConMaintenance => (
        title: pText.tipAirConMaintenanceTitle,
        steps: pText.tipAirConMaintenanceSteps,
        warning: pText.tipAirConMaintenanceWarning,
      ),
    };

/// Toutes les fiches, par sujet.
class TipsScreen extends StatelessWidget {
  const TipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.tipsTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.balance, color: vTheme.colorScheme.primary),
              title: Text(vText.decisionsTitle),
              subtitle: Text(vText.decisionsHelp, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => const DecisionsScreen()),
              ),
            ),
          ),
          for (final vTopic in TipTopic.values) ...[
            ListTile(
              leading: Icon(tipTopicIcon(vTopic), color: vTheme.colorScheme.primary),
              title: Text(tipTopicLabel(vText, vTopic), style: vTheme.textTheme.titleMedium),
            ),
            for (final vTip in tipsAbout(vTopic))
              Card(
                child: ListTile(
                  title: Text(tipTexts(vText, vTip).title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (_) => TipScreen(tip: vTip)),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

/// Une fiche : étapes numérotées et mise en garde éventuelle.
class TipScreen extends StatelessWidget {
  const TipScreen({super.key, required this.tip});

  final Tip tip;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vTexts = tipTexts(vText, tip);
    final vSteps = tipSteps(vTexts.steps);
    final vWarning = vTexts.warning;

    return Scaffold(
      appBar: AppBar(title: Text(vTexts.title)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          for (var vIndex = 0; vIndex < vSteps.length; vIndex++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: vTheme.colorScheme.primary,
                    foregroundColor: vTheme.colorScheme.onPrimary,
                    child: Text('${vIndex + 1}', style: const TextStyle(fontFamily: titleFont)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(vSteps[vIndex], style: vTheme.textTheme.bodyLarge)),
                ],
              ),
            ),
          if (vWarning != null)
            Card(
              margin: const EdgeInsets.only(top: 12),
              color: vTheme.colorScheme.errorContainer,
              child: ListTile(
                leading: Icon(Icons.warning_amber, color: vTheme.colorScheme.onErrorContainer),
                title: Text(vText.tipWarning),
                subtitle: Text(vWarning),
              ),
            ),
        ],
      ),
    );
  }
}
