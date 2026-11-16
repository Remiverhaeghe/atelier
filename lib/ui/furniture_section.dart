import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/furniture.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'fixtures_section.dart';
import 'theme.dart';

String furnitureLabel(AppLocalizations pText, FurnitureKind pKind) => switch (pKind) {
  FurnitureKind.doubleBed => pText.furnDoubleBed,
  FurnitureKind.singleBed => pText.furnSingleBed,
  FurnitureKind.sofa => pText.furnSofa,
  FurnitureKind.table => pText.furnTable,
  FurnitureKind.desk => pText.furnDesk,
  FurnitureKind.wardrobe => pText.furnWardrobe,
  FurnitureKind.chest => pText.furnChest,
  FurnitureKind.sideboard => pText.furnSideboard,
  FurnitureKind.other => pText.furnOther,
};

IconData furnitureIcon(FurnitureKind pKind) => switch (pKind) {
  FurnitureKind.doubleBed || FurnitureKind.singleBed => Icons.bed_outlined,
  FurnitureKind.sofa => Icons.weekend_outlined,
  FurnitureKind.table => Icons.table_restaurant_outlined,
  FurnitureKind.desk => Icons.desk_outlined,
  FurnitureKind.wardrobe => Icons.door_sliding_outlined,
  FurnitureKind.chest || FurnitureKind.sideboard => Icons.shelves,
  FurnitureKind.other => Icons.chair_outlined,
};

/// Meubles de la pièce, avec ce qui gêne : porte, passage, chevauchement.
class FurnitureSection extends StatelessWidget {
  const FurnitureSection({super.key, required this.room, required this.onChanged});

  final Room room;
  final ValueChanged<Room> onChanged;

  void _replace(Furniture pItem) => onChanged(
    room.copyWith(
      furniture: [for (final vItem in room.furniture) vItem.id == pItem.id ? pItem : vItem],
    ),
  );

  Future<void> _add(BuildContext pContext) async {
    final vKind = await showModalBottomSheet<FurnitureKind>(
      context: pContext,
      isScrollControlled: true,
      builder: (pSheetContext) {
        final vText = AppLocalizations.of(pSheetContext);

        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final vKind in FurnitureKind.values)
                  ListTile(
                    leading: Icon(furnitureIcon(vKind)),
                    title: Text(furnitureLabel(vText, vKind)),
                    subtitle: Text(
                      '${formatCentimetres(vKind.widthMm)} × ${formatCentimetres(vKind.depthMm)} cm',
                    ),
                    onTap: () => Navigator.pop(pSheetContext, vKind),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (vKind == null || !pContext.mounted) {
      return;
    }
    final vPoint = await pickPlanPoint(pContext, room);
    if (vPoint == null) {
      return;
    }
    onChanged(
      room.copyWith(
        furniture: [
          ...room.furniture,
          Furniture(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            kind: vKind,
            xMm: vPoint.xMm,
            yMm: vPoint.yMm,
            widthMm: vKind.widthMm,
            depthMm: vKind.depthMm,
          ),
        ],
      ),
    );
  }

  Future<void> _move(BuildContext pContext, Furniture pItem) async {
    final vPoint = await pickPlanPoint(pContext, room);
    if (vPoint != null) {
      _replace(pItem.copyWith(xMm: vPoint.xMm, yMm: vPoint.yMm));
    }
  }

  String _issue(AppLocalizations pText, FurnitureIssue pIssue) {
    String vName(String? pId) => switch (room.furniture.where((pItem) => pItem.id == pId).firstOrNull) {
      final Furniture vItem => furnitureLabel(pText, vItem.kind),
      null => '',
    };

    return switch (pIssue.kind) {
      FurnitureIssueKind.outside => pText.furnOutside,
      FurnitureIssueKind.overlap => pText.furnOverlap(vName(pIssue.otherId)),
      FurnitureIssueKind.door => pText.furnDoor(pIssue.wallIndex! + 1),
      FurnitureIssueKind.passage => pIssue.otherId == null
          ? pText.furnPassageWall(formatCentimetres(pIssue.gapMm!), pIssue.wallIndex! + 1)
          : pText.furnPassage(formatCentimetres(pIssue.gapMm!), vName(pIssue.otherId)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vIssues = furnitureIssues(room);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(title: Text(vText.furnTitle, style: vTheme.textTheme.titleMedium)),
        if (room.furniture.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(vText.furnEmpty),
          ),
        for (final vItem in room.furniture)
          ListTile(
            leading: Icon(furnitureIcon(vItem.kind)),
            title: Text(furnitureLabel(vText, vItem.kind)),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${formatCentimetres(vItem.widthMm)} × ${formatCentimetres(vItem.depthMm)} cm'),
                for (final vIssue in vIssues.where((pIssue) => pIssue.furnitureId == vItem.id))
                  IconLine(AtelierIcons.warning, _issue(vText, vIssue)),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (pAction) {
                switch (pAction) {
                  case 'turn':
                    _replace(vItem.copyWith(turned: !vItem.turned));
                  case 'move':
                    _move(context, vItem);
                  case 'delete':
                    onChanged(
                      room.copyWith(
                        furniture: [
                          for (final vOther in room.furniture)
                            if (vOther.id != vItem.id) vOther,
                        ],
                      ),
                    );
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(value: 'turn', child: Text(vText.furnTurn)),
                PopupMenuItem(value: 'move', child: Text(vText.fixtureMove)),
                PopupMenuItem(value: 'delete', child: Text(vText.delete)),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: OutlinedButton.icon(
            onPressed: room.walls.length < 3 ? null : () => _add(context),
            icon: const Icon(Icons.chair_outlined),
            label: Text(vText.furnAdd),
          ),
        ),
      ],
    );
  }
}
