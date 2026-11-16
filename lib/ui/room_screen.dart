import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/geometry.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import '../state/worksites_controller.dart';
import 'dialogs.dart';
import 'room_plan.dart';

/// Une pièce : plan, murs et obstacles.
class RoomScreen extends StatelessWidget {
  const RoomScreen({
    super.key,
    required this.controller,
    required this.worksiteId,
    required this.roomId,
  });

  final WorksitesController controller;
  final String worksiteId;
  final String roomId;

  Room? _room() {
    final vWorksite = controller.worksite(worksiteId);
    if (vWorksite == null) {
      return null;
    }
    for (final vRoom in vWorksite.rooms) {
      if (vRoom.id == roomId) {
        return vRoom;
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (pContext, _) {
        final vRoom = _room();
        if (vRoom == null) {
          return const Scaffold();
        }

        return Scaffold(
          appBar: AppBar(title: Text(vRoom.name)),
          body: RoomWallsView(
            room: vRoom,
            onChanged: (pRoom) => controller.updateRoom(worksiteId, pRoom),
          ),
        );
      },
    );
  }
}

/// Saisie de la pièce : plan, contrôle de fermeture, murs, ouvertures et obstacles.
class RoomWallsView extends StatelessWidget {
  const RoomWallsView({super.key, required this.room, required this.onChanged});

  final Room room;
  final ValueChanged<Room> onChanged;

  String _wallSummary(AppLocalizations pText, Wall pWall) {
    final vLength = formatCentimetres(pWall.lengthMm);
    final vKind = pWall.isOutsideCornerAfter ? pText.cornerOutside : pText.cornerInside;
    final vSummary = pWall.freeEndAfter
        ? pText.freeEndSummary(vLength)
        : pText.wallSummary(vLength, formatAngle(pWall.angleToNextDeg), vKind);
    final rSummary = pWall.openings.isEmpty
        ? vSummary
        : '$vSummary · ${pText.openings(pWall.openings.length)}';

    return rSummary;
  }

  Future<void> _addWall(BuildContext pContext) async {
    final vWall = await editWall(pContext);
    if (vWall != null) {
      onChanged(room.copyWith(walls: [...room.walls, vWall]));
    }
  }

  Future<void> _editWall(BuildContext pContext, int pIndex) async {
    final vWall = await editWall(pContext, pWall: room.walls[pIndex]);
    if (vWall != null) {
      final vWalls = [...room.walls]..[pIndex] = vWall;
      onChanged(room.copyWith(walls: vWalls));
    }
  }

  Future<void> _addOpening(BuildContext pContext, int pIndex) async {
    final vWall = room.walls[pIndex];
    final vOpening = await addOpening(pContext, vWall.lengthMm);
    if (vOpening != null) {
      final vWalls = [...room.walls]..[pIndex] = vWall.copyWith(openings: [...vWall.openings, vOpening]);
      onChanged(room.copyWith(walls: vWalls));
    }
  }

  void _removeWall(int pIndex) {
    final vWalls = [...room.walls]..removeAt(pIndex);
    // Les obstacles du mur retiré disparaissent, ceux des murs suivants changent de numéro.
    final vObstacles = [
      for (final vObstacle in room.obstacles)
        if (vObstacle.wallIndex < pIndex)
          vObstacle
        else if (vObstacle.wallIndex > pIndex)
          Obstacle(
            kind: vObstacle.kind,
            wallIndex: vObstacle.wallIndex - 1,
            offsetMm: vObstacle.offsetMm,
            widthMm: vObstacle.widthMm,
            depthMm: vObstacle.depthMm,
          ),
    ];
    onChanged(room.copyWith(walls: vWalls, obstacles: vObstacles));
  }

  Future<void> _addObstacle(BuildContext pContext) async {
    final vObstacle = await addObstacle(pContext, room);
    if (vObstacle != null) {
      onChanged(room.copyWith(obstacles: [...room.obstacles, vObstacle]));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vGap = closureGapMm(room);

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (room.walls.isNotEmpty)
          Padding(padding: const EdgeInsets.all(16), child: RoomPlan(room: room)),
        if (room.closed && room.walls.length >= 3)
          ListTile(
            leading: Icon(
              closesProperly(room) ? Icons.check_circle_outline : Icons.warning_amber,
              color: closesProperly(room) ? vTheme.colorScheme.primary : vTheme.colorScheme.error,
            ),
            title: Text(
              closesProperly(room)
                  ? vText.closureOk
                  : vText.closureGap(formatCentimetres(vGap.round())),
            ),
            subtitle: Text(vText.areaSummary(formatSquareMetres(floorAreaM2(room)))),
          ),
        SwitchListTile(
          value: room.closed,
          title: Text(vText.roomClosed),
          onChanged: (pValue) => onChanged(room.copyWith(closed: pValue)),
        ),
        ListTile(title: Text(vText.wallsTitle, style: vTheme.textTheme.titleMedium)),
        if (room.walls.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(vText.wallsEmpty),
          ),
        for (var vIndex = 0; vIndex < room.walls.length; vIndex++)
          ListTile(
            title: Text(vText.wallTitle(vIndex + 1)),
            subtitle: Text(_wallSummary(vText, room.walls[vIndex])),
            onTap: () => _editWall(context, vIndex),
            trailing: PopupMenuButton<String>(
              onSelected: (pAction) {
                switch (pAction) {
                  case 'opening':
                    _addOpening(context, vIndex);
                  case 'clear':
                    final vWalls = [...room.walls]
                      ..[vIndex] = room.walls[vIndex].copyWith(openings: const []);
                    onChanged(room.copyWith(walls: vWalls));
                  case 'delete':
                    _removeWall(vIndex);
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'opening', child: Text(vText.addOpening)),
                if (room.walls[vIndex].openings.isNotEmpty)
                  PopupMenuItem(value: 'clear', child: Text(vText.removeOpenings)),
                PopupMenuItem(value: 'delete', child: Text(vText.delete)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: FilledButton.icon(
            onPressed: () => _addWall(context),
            icon: const Icon(Icons.add),
            label: Text(vText.addWall),
          ),
        ),
        ListTile(title: Text(vText.obstaclesTitle, style: vTheme.textTheme.titleMedium)),
        if (room.obstacles.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(vText.obstaclesEmpty),
          ),
        for (var vIndex = 0; vIndex < room.obstacles.length; vIndex++)
          ListTile(
            title: Text(
              vText.obstacleSummary(
                obstacleLabel(vText, room.obstacles[vIndex].kind),
                room.obstacles[vIndex].wallIndex + 1,
                formatCentimetres(room.obstacles[vIndex].widthMm),
              ),
            ),
            trailing: IconButton(
              tooltip: vText.delete,
              icon: const Icon(Icons.delete_outline),
              onPressed: () => onChanged(
                room.copyWith(obstacles: [...room.obstacles]..removeAt(vIndex)),
              ),
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: room.walls.isEmpty ? null : () => _addObstacle(context),
            icon: const Icon(Icons.add),
            label: Text(room.walls.isEmpty ? vText.obstacleNeedsWall : vText.addObstacle),
          ),
        ),
      ],
    );
  }
}
