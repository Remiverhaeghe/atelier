import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/units.dart';
import '../state/worksites_controller.dart';
import 'dialogs.dart';
import 'room_screen.dart';

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
          appBar: AppBar(title: Text(vWorksite.name)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _create(pContext),
            icon: const Icon(Icons.add),
            label: Text(vText.newRoom),
          ),
          body: vWorksite.rooms.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(vText.roomsEmpty, textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  children: [
                    for (final vRoom in vWorksite.rooms)
                      ListTile(
                        leading: const Icon(Icons.crop_square),
                        title: Text(vRoom.name),
                        subtitle: Text(
                          vText.areaSummary(formatSquareMetres(floorAreaM2(vRoom))),
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
                  ],
                ),
        );
      },
    );
  }
}
