import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/worksite.dart';
import '../logic/app_settings.dart';
import '../logic/units.dart';
import '../state/settings_controller.dart';
import '../state/worksites_controller.dart';
import '../storage/backups.dart';
import '../support/crash_log.dart';
import 'about_screen.dart';
import 'calculators_screen.dart';
import 'dialogs.dart';
import 'plan_thumbnail.dart';
import 'search_screen.dart';
import 'tips_screen.dart';
import 'transfer.dart';
import 'worksite_screen.dart';

/// Liste des chantiers.
class WorksitesScreen extends StatelessWidget {
  const WorksitesScreen({
    super.key,
    required this.controller,
    this.crashLog,
    this.backups,
    this.settings,
    this.onExternalBackup,
    this.now,
  });

  final WorksitesController controller;
  final CrashLog? crashLog;
  final Backups? backups;
  final SettingsController? settings;

  /// Envoi de la sauvegarde complète ; remplaçable dans les tests.
  final Future<void> Function(List<Worksite> pWorksites, DateTime pDay)? onExternalBackup;

  /// Heure courante ; remplaçable dans les tests.
  final DateTime Function()? now;

  Future<void> _externalBackup(SettingsController pSettings) async {
    final vNow = (now ?? DateTime.now)();
    await (onExternalBackup ?? exportAllWorksites)(controller.worksites, vNow);
    await pSettings.update(pSettings.settings.copyWith(lastExternalBackup: vNow));
  }

  Future<void> _create(BuildContext pContext) async {
    final vText = AppLocalizations.of(pContext);
    final vName = await askName(pContext, pTitle: vText.newWorksite, pLabel: vText.worksiteName);
    if (vName == null) {
      return;
    }
    final vWorksite = await controller.addWorksite(vName);
    if (pContext.mounted) {
      await Navigator.push(
        pContext,
        MaterialPageRoute<void>(
          builder: (_) => WorksiteScreen(controller: controller, worksiteId: vWorksite.id),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(vText.worksitesTitle),
        actions: [
          IconButton(
            tooltip: vText.searchTitle,
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => SearchScreen(controller: controller)),
            ),
          ),
          IconButton(
            tooltip: vText.importWorksites,
            icon: const Icon(Icons.file_open_outlined),
            onPressed: () => importWorksites(context, controller),
          ),
          IconButton(
            tooltip: vText.calculatorsTitle,
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => CalculatorsScreen(
                  rooms: [for (final vWorksite in controller.worksites) ...vWorksite.rooms],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: vText.tipsTitle,
            icon: const Icon(Icons.tips_and_updates_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const TipsScreen()),
            ),
          ),
          IconButton(
            tooltip: vText.aboutTitle,
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => AboutScreen(
                  crashLog: crashLog,
                  backups: backups,
                  controller: controller,
                  settings: settings,
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _create(context),
        icon: const Icon(Icons.add),
        label: Text(vText.newWorksite),
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (pContext, _) {
          if (!controller.loaded) {
            return const Center(child: CircularProgressIndicator());
          }
          if (controller.worksites.isEmpty) {
            return EmptyState(icon: Icons.straighten, text: vText.worksitesEmpty);
          }

          final vSettings = settings;

          return ListView(
            padding: const EdgeInsets.only(top: 8, bottom: 96),
            children: [
              if (vSettings != null)
                ListenableBuilder(
                  listenable: vSettings,
                  builder: (_, _) {
                    final vLast = vSettings.settings.lastExternalBackup;
                    if (!externalBackupDue(vLast, (now ?? DateTime.now)())) {
                      return const SizedBox.shrink();
                    }

                    return Card(
                      color: Theme.of(pContext).colorScheme.tertiaryContainer,
                      child: ListTile(
                        leading: const Icon(Icons.cloud_upload_outlined),
                        title: Text(vText.externalBackupDue),
                        subtitle: Text(
                          vLast == null
                              ? vText.externalBackupNever
                              : vText.externalBackupSince(
                                  (now ?? DateTime.now)().difference(vLast).inDays,
                                ),
                        ),
                        trailing: FilledButton(
                          onPressed: () => _externalBackup(vSettings),
                          child: Text(vText.externalBackupSend),
                        ),
                      ),
                    );
                  },
                ),
              for (final vWorksite in controller.worksites)
                Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                    leading: PlanThumbnail(
                      room: vWorksite.rooms.isEmpty ? null : vWorksite.rooms.first,
                      icon: Icons.home_work_outlined,
                    ),
                    title: Text(vWorksite.name, style: Theme.of(pContext).textTheme.titleMedium),
                    subtitle: Text(
                      [
                        vText.roomCount(vWorksite.rooms.length),
                        if (vWorksite.rooms.isNotEmpty)
                          vText.totalArea(
                            formatSquareMetres(
                              vWorksite.rooms.fold(0.0, (pSum, pRoom) => pSum + floorAreaM2(pRoom)),
                            ),
                          ),
                      ].join(' · '),
                    ),
                    onTap: () => Navigator.push(
                      pContext,
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            WorksiteScreen(controller: controller, worksiteId: vWorksite.id),
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: vText.delete,
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        if (await confirmDelete(pContext, vWorksite.name)) {
                          await controller.deleteWorksite(vWorksite.id);
                        }
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
