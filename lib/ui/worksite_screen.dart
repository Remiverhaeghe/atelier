import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/shopping.dart';
import '../logic/units.dart';
import '../state/worksites_controller.dart';
import 'dialogs.dart';
import 'room_screen.dart';
import 'shopping_screen.dart';
import 'shopping_texts.dart';
import 'transfer.dart';
import 'plan_thumbnail.dart';

/// Pièces d'un chantier.
class WorksiteScreen extends StatelessWidget {
  const WorksiteScreen({super.key, required this.controller, required this.worksiteId});

  final WorksitesController controller;
  final String worksiteId;

  void _open(BuildContext pContext, String pRoomId) => Navigator.push(
    pContext,
    MaterialPageRoute<void>(
      builder: (_) => RoomScreen(controller: controller, worksiteId: worksiteId, roomId: pRoomId),
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
                    case 'guide':
                      controller.updateWorksite(
                        vWorksite.copyWith(showGuidance: !vWorksite.showGuidance),
                      );
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(value: 'export', child: Text(vText.exportWorksite)),
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
                    for (final vRoom in vWorksite.rooms)
                      Card(
                        child: ListTile(
                          contentPadding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
                          leading: PlanThumbnail(room: vRoom, icon: Icons.square_foot),
                          title: Text(vRoom.name, style: Theme.of(pContext).textTheme.titleMedium),
                          subtitle: Text(
                            [
                              vText.areaSummary(formatSquareMetres(floorAreaM2(vRoom))),
                              if (vWorksite.prices.isNotEmpty)
                                vText.roomCost(formatEuros(roomCost(vRoom, vWorksite.prices))),
                            ].join(' · '),
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
