import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/app_settings.dart';
import '../logic/units.dart';
import '../state/settings_controller.dart';
import '../state/worksites_controller.dart';
import '../storage/backups.dart';
import '../support/crash_log.dart';
import 'backups_screen.dart';
import 'room_measure_picker.dart' show unitName;

/// À propos, et journal des plantages à partager si quelque chose ne va pas.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key, this.crashLog, this.backups, this.controller, this.settings});

  final CrashLog? crashLog;
  final Backups? backups;
  final WorksitesController? controller;
  final SettingsController? settings;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vLog = crashLog?.read() ?? '';

    return Scaffold(
      appBar: AppBar(title: Text(vText.aboutTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(vText.aboutText),
          if (settings != null) _DisplaySettings(settings: settings!),
          if (backups != null && controller != null) ...[
            const SizedBox(height: 16),
            Card(
              margin: EdgeInsets.zero,
              child: ListTile(
                leading: const Icon(Icons.history),
                title: Text(vText.backupsTitle),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => BackupsScreen(backups: backups!, controller: controller!),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(vText.crashLogTitle, style: Theme.of(context).textTheme.titleMedium),
          Text(vText.crashLogHelp),
          const SizedBox(height: 8),
          if (vLog.isEmpty)
            Text(vText.crashLogEmpty)
          else
            FilledButton.icon(
              onPressed: () => SharePlus.instance.share(ShareParams(text: vLog)),
              icon: const Icon(Icons.share),
              label: Text(vText.crashLogShare),
            ),
        ],
      ),
    );
  }
}

/// Thème et taille du texte, appliqués tout de suite.
class _DisplaySettings extends StatelessWidget {
  const _DisplaySettings({required this.settings});

  final SettingsController settings;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return ListenableBuilder(
      listenable: settings,
      builder: (pContext, _) {
        final vCurrent = settings.settings;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 24),
            Text(vText.displayTitle, style: vTheme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<ThemeChoice>(
              segments: [
                ButtonSegment(
                  value: ThemeChoice.system,
                  icon: const Icon(Icons.brightness_auto_outlined),
                  label: Text(vText.themeSystem),
                ),
                ButtonSegment(
                  value: ThemeChoice.light,
                  icon: const Icon(Icons.light_mode_outlined),
                  label: Text(vText.themeLight),
                ),
                ButtonSegment(
                  value: ThemeChoice.dark,
                  icon: const Icon(Icons.dark_mode_outlined),
                  label: Text(vText.themeDark),
                ),
              ],
              selected: {vCurrent.theme},
              onSelectionChanged: (pChoice) =>
                  settings.update(vCurrent.copyWith(theme: pChoice.single)),
            ),
            const SizedBox(height: 12),
            SegmentedButton<LanguageChoice>(
              segments: [
                ButtonSegment(
                  value: LanguageChoice.system,
                  icon: const Icon(Icons.translate),
                  label: Text(vText.languageSystem),
                ),
                ButtonSegment(value: LanguageChoice.french, label: Text(vText.languageFrench)),
                ButtonSegment(value: LanguageChoice.english, label: Text(vText.languageEnglish)),
              ],
              selected: {vCurrent.language},
              onSelectionChanged: (pChoice) =>
                  settings.update(vCurrent.copyWith(language: pChoice.single)),
            ),
            const SizedBox(height: 12),
            SegmentedButton<double>(
              segments: [
                for (final (vIndex, vScale) in textScales.indexed)
                  ButtonSegment(
                    value: vScale,
                    label: Text(
                      [vText.textNormal, vText.textLarge, vText.textHuge][vIndex],
                      textScaler: TextScaler.noScaling,
                    ),
                  ),
              ],
              selected: {vCurrent.textScale},
              onSelectionChanged: (pScale) =>
                  settings.update(vCurrent.copyWith(textScale: pScale.single)),
            ),
            const SizedBox(height: 12),
            Text(vText.planUnitLabel),
            const SizedBox(height: 4),
            SegmentedButton<FieldUnit>(
              segments: [
                for (final vUnit in const [FieldUnit.mm, FieldUnit.cm, FieldUnit.m])
                  ButtonSegment(value: vUnit, label: Text(unitName(vText, vUnit))),
              ],
              selected: {vCurrent.planUnit},
              onSelectionChanged: (pUnit) =>
                  settings.update(vCurrent.copyWith(planUnit: pUnit.single)),
            ),
          ],
        );
      },
    );
  }
}
