import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../state/worksites_controller.dart';
import 'dialogs.dart';
import 'worksite_screen.dart';

/// Liste des chantiers.
class WorksitesScreen extends StatelessWidget {
  const WorksitesScreen({super.key, required this.controller});

  final WorksitesController controller;

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
      appBar: AppBar(title: Text(vText.worksitesTitle)),
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
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(vText.worksitesEmpty, textAlign: TextAlign.center),
              ),
            );
          }

          return ListView(
            children: [
              for (final vWorksite in controller.worksites)
                ListTile(
                  leading: const Icon(Icons.home_work_outlined),
                  title: Text(vWorksite.name),
                  subtitle: Text(vText.roomCount(vWorksite.rooms.length)),
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
            ],
          );
        },
      ),
    );
  }
}
