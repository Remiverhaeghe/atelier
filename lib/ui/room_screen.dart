import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/inventory.dart';
import '../logic/journal.dart';
import '../logic/geometry.dart';
import '../logic/layout.dart';
import '../logic/room.dart';
import '../logic/extra_items.dart';
import '../logic/room_copy.dart';
import '../logic/room_shapes.dart';
import '../logic/units.dart';
import '../state/worksites_controller.dart';
import 'baseboard_view.dart';
import 'cut_list_pdf.dart';
import 'room_sheet_pdf.dart';
import 'diagonal_dialog.dart';
import 'dialogs.dart';
import 'fixtures_section.dart';
import 'furniture_section.dart';
import 'networks_section.dart';
import 'behind_walls_section.dart';
import 'guide_view.dart';
import 'laying_view.dart';
import 'parquet_view.dart';
import 'plan_unit.dart';
import 'pro_brief_dialog.dart';
import 'pro_brief_pdf.dart';
import 'quick_walls_screen.dart';
import 'room_sketch_screen.dart';
import 'room_3d_card.dart';
import 'room_measure_picker.dart' show unitName;
import 'room_plan_switcher.dart';
import 'site_mode_screen.dart';
import 'theme.dart';
import 'trace_screen.dart';
import 'touch_ups_view.dart';
import 'trades_screen.dart' show tradeName;
import 'paint_view.dart';

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
        final vGuide = controller.worksite(worksiteId)?.showGuidance ?? true;
        if (vRoom == null) {
          return const Scaffold();
        }

        final vText = AppLocalizations.of(pContext);
        void vSave(Room pRoom) => controller.updateRoom(worksiteId, pRoom);

        return DefaultTabController(
          length: vGuide ? 7 : 6,
          // Une zone sans murs (toit, extérieur) s'ouvre directement sur ses reprises
          initialIndex: vRoom.walls.isEmpty && vRoom.touchUps.isNotEmpty ? 1 : 0,
          child: Scaffold(
            appBar: AppBar(
              title: Text(vRoom.name),
              actions: [
                IconButton(
                  tooltip: vText.undo,
                  icon: const Icon(Icons.undo),
                  onPressed: controller.canUndo ? controller.undo : null,
                ),
                IconButton(
                  tooltip: vText.redo,
                  icon: const Icon(Icons.redo),
                  onPressed: controller.canRedo ? controller.redo : null,
                ),
                IconButton(
                  tooltip: vText.cutListPrint,
                  icon: const Icon(Icons.content_cut),
                  onPressed: () => Printing.layoutPdf(
                    name: vText.roomCutsTitle(vRoom.name),
                    onLayout: (_) => buildCutListPdf(vText, vRoom, pUnit: PlanUnit.of(pContext)),
                  ),
                ),
                PopupMenuButton<bool>(
                  tooltip: vText.roomSheetPrint,
                  icon: const Icon(Icons.print_outlined),
                  onSelected: (pForPro) async {
                    if (!pForPro) {
                      await Printing.layoutPdf(
                        name: vText.roomSheetTitle(vRoom.name),
                        onLayout: (_) => buildRoomSheetPdf(vText, vRoom, pUnit: PlanUnit.of(pContext)),
                      );

                      return;
                    }
                    final vChoice = await askProBrief(pContext);
                    if (vChoice == null) {
                      return;
                    }
                    final vJournal = journalOf(
                      controller.worksite(worksiteId)?.journal ?? const [],
                      pRoomId: vRoom.id,
                    );
                    await Printing.layoutPdf(
                      name: vText.proBriefTitle(vRoom.name),
                      onLayout: (_) => buildProBriefPdf(
                        vText,
                        vRoom,
                        pTrade: tradeName(vText, vChoice.trade),
                        pConstraints: vChoice.constraints,
                        pJournal: vJournal,
                      ),
                    );
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: false, child: Text(vText.roomSheetPrint)),
                    PopupMenuItem(value: true, child: Text(vText.proBriefMenu)),
                  ],
                ),
                PopupMenuButton<bool>(
                  tooltip: vText.copyRoomMenu,
                  icon: const Icon(Icons.copy_all_outlined),
                  onSelected: (pMirror) async {
                    final vName = await askName(
                      pContext,
                      pTitle: pMirror ? vText.copyRoomMirror : vText.copyRoomSame,
                      pLabel: vText.roomName,
                      pInitial: vText.copyRoomName(vRoom.name),
                    );
                    if (vName == null) {
                      return;
                    }
                    final vCopy = pMirror
                        ? mirrorRoom(vRoom, pId: controller.newId(), pName: vName)
                        : duplicateRoom(vRoom, pId: controller.newId(), pName: vName);
                    final vWorksite = controller.worksite(worksiteId)!;
                    await controller.updateWorksite(
                      vWorksite.copyWith(rooms: [...vWorksite.rooms, vCopy]),
                    );
                    if (pContext.mounted) {
                      ScaffoldMessenger.of(
                        pContext,
                      ).showSnackBar(SnackBar(content: Text(vText.copyRoomDone(vName))));
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(value: false, child: Text(vText.copyRoomSame)),
                    PopupMenuItem(value: true, child: Text(vText.copyRoomMirror)),
                  ],
                ),
                IconButton(
                  tooltip: vText.siteModeTitle,
                  icon: const Icon(Icons.construction),
                  onPressed: () => Navigator.push(
                    pContext,
                    MaterialPageRoute<void>(
                      builder: (_) => SiteModeScreen(
                        controller: controller,
                        worksiteId: worksiteId,
                        roomId: roomId,
                      ),
                    ),
                  ),
                ),
              ],
              bottom: TabBar(
                isScrollable: true,
                tabs: [
                  Tab(icon: const Icon(AtelierIcons.room), text: vText.tabRoom),
                  Tab(icon: const Icon(AtelierIcons.touchUps), text: vText.tabTouchUps),
                  Tab(icon: const Icon(AtelierIcons.parquet), text: vText.tabParquet),
                  Tab(icon: const Icon(AtelierIcons.laying), text: vText.tabLaying),
                  Tab(icon: const Icon(AtelierIcons.baseboard), text: vText.tabBaseboard),
                  Tab(icon: const Icon(AtelierIcons.paint), text: vText.tabPaint),
                  if (vGuide) Tab(icon: const Icon(AtelierIcons.guide), text: vText.tabGuide),
                ],
              ),
            ),
            body: TabBarView(
              children: [
                RoomWallsView(room: vRoom, onChanged: vSave),
                TouchUpsView(
                  room: vRoom,
                  onChanged: vSave,
                  otherRooms: [
                    for (final vOther in controller.worksite(worksiteId)?.rooms ?? const <Room>[])
                      if (vOther.id != roomId) vOther,
                  ],
                  shopping: controller.worksite(worksiteId)?.extras ?? const [],
                  onAddToShopping: (pItems) async {
                    final vWorksite = controller.worksite(worksiteId);
                    if (vWorksite != null) {
                      await controller.updateWorksite(
                        vWorksite.copyWith(extras: mergeExtras(vWorksite.extras, pItems)),
                      );
                    }
                  },
                ),
                ParquetView(room: vRoom, onChanged: vSave),
                LayingView(room: vRoom, onChanged: vSave),
                BaseboardView(room: vRoom, onChanged: vSave),
                PaintView(
                  room: vRoom,
                  onChanged: vSave,
                  prices: controller.worksite(worksiteId)?.prices ?? const {},
                ),
                if (vGuide)
                  GuideView(
                    room: vRoom,
                    onChanged: vSave,
                    ownedTools: controller.worksite(worksiteId)?.ownedTools ?? const [],
                    onToolOwned: (pTool, pOwned) {
                      final vWorksite = controller.worksite(worksiteId);
                      if (vWorksite != null) {
                        controller.updateWorksite(
                          vWorksite.copyWith(
                            ownedTools: toggleTool(vWorksite.ownedTools, pTool, pOwned),
                          ),
                        );
                      }
                    },
                  ),
              ],
            ),
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
    final rSummary = [
      vSummary,
      if (pWall.openings.isNotEmpty) pText.openings(pWall.openings.length),
      if (pWall.openings.any((pOpening) => pOpening.threshold)) pText.openingThresholdSummary,
    ].join(' · ');

    return rSummary;
  }

  /// Saisie à la suite : « Mur suivant » enregistre et rouvre la saisie du mur d'après.
  Future<void> _addWall(BuildContext pContext) async {
    var vRoom = room;
    while (pContext.mounted) {
      final vEntry = await editWall(pContext, pNumber: vRoom.walls.length + 1, pRoom: vRoom);
      if (vEntry == null) {
        return;
      }
      vRoom = vRoom.copyWith(walls: [...vRoom.walls, vEntry.wall]);
      onChanged(vRoom);
      if (!vEntry.next) {
        return;
      }
    }
  }

  Future<void> _editWall(BuildContext pContext, int pIndex) async {
    final vEntry = await editWall(
      pContext,
      pNumber: pIndex + 1,
      pWall: room.walls[pIndex],
      pRoom: room,
    );
    if (vEntry != null) {
      final vWalls = [...room.walls]..[pIndex] = vEntry.wall;
      onChanged(room.copyWith(walls: vWalls));
    }
  }

  Future<void> _addOpening(BuildContext pContext, int pIndex) async {
    final vWall = room.walls[pIndex];
    final vOpening = await addOpening(pContext, vWall.lengthMm);
    if (vOpening != null) {
      final vWalls = [...room.walls]
        ..[pIndex] = vWall.copyWith(openings: [...vWall.openings, vOpening]);
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

    final vWide = isWideWidth(MediaQuery.sizeOf(context).width) && room.walls.isNotEmpty;
    final vPlan = Padding(
      padding: const EdgeInsets.all(16),
      child: RoomPlanSwitcher(room: room),
    );
    final vList = ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (room.walls.isNotEmpty && !vWide) vPlan,
        Room3dCard(room: room),
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
        if (room.closed && room.walls.length >= 4)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: OutlinedButton.icon(
              onPressed: () async {
                final vFixed = await checkDiagonal(context, room);
                if (vFixed != null) {
                  onChanged(vFixed);
                }
              },
              icon: const Icon(Icons.call_made),
              label: Text(vText.diagonalTitle),
            ),
          ),
        SwitchListTile(
          value: room.closed,
          title: Text(vText.roomClosed),
          onChanged: (pValue) => onChanged(room.copyWith(closed: pValue)),
        ),
        ListTile(title: Text(vText.wallsTitle, style: vTheme.textTheme.titleMedium)),
        // La façon la plus simple : les longueurs des murs sur un seul écran, les angles se
        // déduisent tout seuls. Le dessin d'une forme toute faite reste en second.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: FilledButton.icon(
            onPressed: () async {
              final vWalls = await editAllWalls(context, room);
              if (vWalls != null) {
                // Un obstacle posé sur un mur retiré n'a plus de place
                onChanged(
                  room.copyWith(
                    walls: vWalls,
                    obstacles: [
                      for (final vObstacle in room.obstacles)
                        if (vObstacle.wallIndex < vWalls.length) vObstacle,
                    ],
                  ),
                );
              }
            },
            icon: const Icon(Icons.edit_note),
            label: Text(vText.quickWallsOpen),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: OutlinedButton.icon(
            onPressed: () async {
              final vDrawn = await sketchRoom(context, room);
              if (vDrawn != null) {
                onChanged(
                  vDrawn.copyWith(
                    obstacles: [
                      for (final vObstacle in vDrawn.obstacles)
                        if (vObstacle.wallIndex < vDrawn.walls.length) vObstacle,
                    ],
                  ),
                );
              }
            },
            icon: const Icon(Icons.crop_square),
            label: Text(vText.sketchTitle),
          ),
        ),
        if (room.walls.isEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(vText.wallsEmpty),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: OutlinedButton.icon(
              onPressed: () async {
                final vWalls = await tracePaperPlan(context);
                if (vWalls == null || !context.mounted) {
                  return;
                }
                // Rectangle, L ou T reconnu : on finit sur le dessin, murs à vérifier en
                // pointillés ; sinon les murs tracés sont gardés tels quels
                final vShaped = shapeFromTrace(vWalls);
                final vTraced = room.copyWith(walls: vShaped ?? vWalls, closed: true);
                if (vShaped == null) {
                  onChanged(vTraced);
                  return;
                }
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(vText.traceShapeFound)));
                onChanged(await sketchRoom(context, vTraced) ?? vTraced);
              },
              icon: const Icon(Icons.document_scanner_outlined),
              label: Text(vText.traceMenu),
            ),
          ),
        ],
        for (var vIndex = 0; vIndex < room.walls.length; vIndex++)
          ListTile(
            leading: TapeLabel(
              '${lengthInUnit(room.walls[vIndex].lengthMm, PlanUnit.of(context))} '
              '${unitName(vText, PlanUnit.of(context))}',
            ),
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
              onPressed: () =>
                  onChanged(room.copyWith(obstacles: [...room.obstacles]..removeAt(vIndex))),
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
        FixturesSection(room: room, onChanged: onChanged),
        FurnitureSection(room: room, onChanged: onChanged),
        NetworksSection(room: room, onChanged: onChanged),
        BehindWallsSection(room: room, onChanged: onChanged),
      ],
    );
    if (!vWide) {
      return vList;
    }

    // Tablette ou paysage : le plan reste à gauche pendant qu'on parcourt les murs
    return Row(
      key: const ValueKey('room-wide'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 5, child: SingleChildScrollView(child: vPlan)),
        const VerticalDivider(width: 1),
        Expanded(flex: 6, child: vList),
      ],
    );
  }
}
