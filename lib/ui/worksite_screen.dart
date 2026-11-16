import 'achievements_screen.dart';
import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/progress.dart';
import '../logic/shopping.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import '../state/worksites_controller.dart';
import 'dialogs.dart';
import 'room_screen.dart';
import 'shopping_screen.dart';
import 'shopping_texts.dart';
import 'plan_thumbnail.dart';
import 'planning_card.dart';
import 'theme.dart';
import 'time_screen.dart';
import 'transfer.dart';
import 'goal_card.dart';
import 'house_screen.dart';
import 'offcuts_screen.dart';

/// Pièces d'un chantier.
class WorksiteScreen extends StatelessWidget {
  const WorksiteScreen({super.key, required this.controller, required this.worksiteId, this.today});

  final WorksitesController controller;
  final String worksiteId;

  /// Jour de l'objectif ; aujourd'hui si absent, fixé dans les tests.
  final DateTime? today;

  void _open(BuildContext pContext, String pRoomId) => Navigator.push(
    pContext,
    MaterialPageRoute<void>(
      builder: (_) => RoomScreen(controller: controller, worksiteId: worksiteId, roomId: pRoomId),
    ),
  );

  void _openShopping(BuildContext pContext) => Navigator.push(
    pContext,
    MaterialPageRoute<void>(
      builder: (_) => ShoppingScreen(controller: controller, worksiteId: worksiteId),
    ),
  );

  Future<void> _create(BuildContext pContext) async {
    final vText = AppLocalizations.of(pContext);
    final vName = await askName(pContext, pTitle: vText.newRoom, pLabel: vText.roomName);
    if (vName == null) {
      return;
    }
    final vRoom = await controller.addRoom(worksiteId, vName);
    if (pContext.mounted) {
      _open(pContext, vRoom.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (pContext, _) {
        final vWorksite = controller.worksite(worksiteId);
        if (vWorksite == null) {
          return const Scaffold();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(vWorksite.name),
            actions: [
              IconButton(
                tooltip: vText.badgesTitle,
                icon: const Icon(Icons.emoji_events_outlined),
                onPressed: () => Navigator.push(
                  pContext,
                  MaterialPageRoute<void>(builder: (_) => AchievementsScreen(worksite: vWorksite)),
                ),
              ),
              IconButton(
                tooltip: vText.timeTitle,
                icon: const Icon(Icons.timer_outlined),
                onPressed: () => Navigator.push(
                  pContext,
                  MaterialPageRoute<void>(
                    builder: (_) => TimeScreen(controller: controller, worksiteId: worksiteId),
                  ),
                ),
              ),
              IconButton(
                tooltip: vText.shoppingTitle,
                icon: const Icon(Icons.shopping_cart_outlined),
                onPressed: () => Navigator.push(
                  pContext,
                  MaterialPageRoute<void>(
                    builder: (_) => ShoppingScreen(controller: controller, worksiteId: worksiteId),
                  ),
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (pAction) {
                  switch (pAction) {
                    case 'export':
                      exportWorksite(vWorksite);
                    case 'plan':
                      exportPlanFile(vWorksite);
                    case 'house':
                      Navigator.push(
                        pContext,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              HouseScreen(controller: controller, worksiteId: worksiteId),
                        ),
                      );
                    case 'gltf':
                      exportGltfFile(vWorksite);
                    case 'homeAssistant':
                      exportHomeAssistantFile(vWorksite);
                    case 'offcuts':
                      Navigator.push(
                        pContext,
                        MaterialPageRoute<void>(
                          builder: (_) =>
                              OffcutsScreen(controller: controller, worksiteId: worksiteId),
                        ),
                      );
                    case 'guide':
                      controller.updateWorksite(
                        vWorksite.copyWith(showGuidance: !vWorksite.showGuidance),
                      );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'export', child: Text(vText.exportWorksite)),
                  PopupMenuItem(value: 'house', child: Text(vText.houseTitle)),
                  PopupMenuItem(value: 'plan', child: Text(vText.exportPlan)),
                  PopupMenuItem(value: 'gltf', child: Text(vText.exportGltf)),
                  PopupMenuItem(value: 'homeAssistant', child: Text(vText.exportHomeAssistant)),
                  PopupMenuItem(value: 'offcuts', child: Text(vText.offcutsTitle)),
                  PopupMenuItem(
                    value: 'guide',
                    child: Text(vWorksite.showGuidance ? vText.guideHidden : vText.guideShown),
                  ),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _create(pContext),
            icon: const Icon(Icons.add),
            label: Text(vText.newRoom),
          ),
          body: vWorksite.rooms.isEmpty
              ? EmptyState(icon: Icons.square_foot, text: vText.roomsEmpty)
              : ListView(
                  padding: const EdgeInsets.only(top: 8, bottom: 96),
                  children: [
                    _Summary(worksite: vWorksite, onShopping: () => _openShopping(pContext)),
                    PlanningCard(worksite: vWorksite),
                    GoalCard(
                      worksite: vWorksite,
                      today: today ?? DateTime.now(),
                      onChanged: controller.updateWorksite,
                    ),
                    for (final vRoom in vWorksite.rooms)
                      Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                          leading: PlanThumbnail(room: vRoom, icon: Icons.square_foot),
                          title: Text(vRoom.name, style: Theme.of(pContext).textTheme.titleMedium),
                          subtitle: _RoomSubtitle(
                            text: [
                              vText.areaSummary(formatSquareMetres(floorAreaM2(vRoom))),
                              if (vWorksite.prices.isNotEmpty)
                                vText.roomCost(formatEuros(roomCost(vRoom, vWorksite.prices))),
                            ].join(' · '),
                            progress: roomProgress(vRoom),
                          ),
                          onTap: () => _open(pContext, vRoom.id),
                          trailing: IconButton(
                            tooltip: vText.delete,
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              if (await confirmDelete(pContext, vRoom.name)) {
                                await controller.deleteRoom(worksiteId, vRoom.id);
                              }
                            },
                          ),
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }
}

/// Résumé du chantier : surface, budget et accès direct aux courses.
class _Summary extends StatelessWidget {
  const _Summary({required this.worksite, required this.onShopping});

  final Worksite worksite;
  final VoidCallback onShopping;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vArea = worksite.rooms.fold(0.0, (pSum, pRoom) => pSum + floorAreaM2(pRoom));
    final vLines = shoppingList(worksite);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BigFigure(vText.totalArea(formatSquareMetres(vArea))),
            IconLine(Icons.door_front_door_outlined, vText.roomCount(worksite.rooms.length)),
            if (worksite.prices.isNotEmpty)
              IconLine(Icons.euro, vText.budgetTotal(formatEuros(budgetTotal(vLines)))),
            const SizedBox(height: 8),
            FilledButton.tonalIcon(
              onPressed: onShopping,
              icon: const Icon(Icons.shopping_cart_outlined),
              label: Text(vText.shoppingTitle),
            ),
          ],
        ),
      ),
    );
  }
}

/// Surface, coût et barre d'avancement d'une pièce.
class _RoomSubtitle extends StatelessWidget {
  const _RoomSubtitle({required this.text, required this.progress});

  final String text;
  final RoomProgress progress;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text),
        if (progress.total > 0) ...[
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: progress.ratio,
            semanticsLabel: vText.roomProgress(progress.done, progress.total),
          ),
        ],
      ],
    );
  }
}
