import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/house.dart';
import '../logic/living_area.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import '../state/worksites_controller.dart';
import 'house_screen.dart';
import 'theme.dart';

String usageLabel(AppLocalizations pText, RoomUsage pUsage) => switch (pUsage) {
  RoomUsage.habitable => pText.usageHabitable,
  RoomUsage.attic => pText.usageAttic,
  RoomUsage.cellar => pText.usageCellar,
  RoomUsage.garage => pText.usageGarage,
  RoomUsage.veranda => pText.usageVeranda,
  RoomUsage.outdoor => pText.usageOutdoor,
};

/// Surface habitable et Loi Carrez, par niveau et pour la maison.
class LivingAreaScreen extends StatelessWidget {
  const LivingAreaScreen({super.key, required this.controller, required this.worksiteId});

  final WorksitesController controller;
  final String worksiteId;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (pContext, _) {
        final vWorksite = controller.worksite(worksiteId);
        if (vWorksite == null) {
          return const Scaffold();
        }
        final vRooms = vWorksite.rooms;
        final vTotal = totalLivingArea(vRooms);
        final vLevels = houseLevels(vRooms);

        return Scaffold(
          appBar: AppBar(title: Text(vText.livingAreaTitle)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              Card(
                margin: EdgeInsets.zero,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vText.livingAreaHabitable, style: vTheme.textTheme.titleMedium),
                      BigFigure('${formatSquareMetres(vTotal.habitable)} m²'),
                      IconLine(
                        Icons.gavel_outlined,
                        vText.livingAreaCarrez(formatSquareMetres(vTotal.carrez)),
                      ),
                    ],
                  ),
                ),
              ),
              for (final vLevel in vLevels)
                if (vRooms.any((pRoom) => pRoom.level == vLevel)) ...[
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(levelLabel(vText, vLevel), style: vTheme.textTheme.titleMedium),
                    subtitle: Text(
                      vText.livingAreaLevel(
                        formatSquareMetres(
                          totalLivingArea(vRooms.where((pRoom) => pRoom.level == vLevel)).habitable,
                        ),
                      ),
                    ),
                  ),
                  for (final vRoom in vRooms.where((pRoom) => pRoom.level == vLevel))
                    _RoomRow(
                      room: vRoom,
                      onUsage: (pUsage) =>
                          controller.updateRoom(worksiteId, vRoom.copyWith(usage: pUsage)),
                    ),
                ],
              const SizedBox(height: 12),
              Text(vText.livingAreaRules, style: vTheme.textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}

class _RoomRow extends StatelessWidget {
  const _RoomRow({required this.room, required this.onUsage});

  final Room room;
  final ValueChanged<RoomUsage> onUsage;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vArea = roomLivingArea(room);
    final vLow = lowFloorM2(room);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(room.name, style: Theme.of(context).textTheme.titleSmall)),
                DropdownButton<RoomUsage>(
                  value: room.usage,
                  underline: const SizedBox(),
                  items: [
                    for (final vUsage in RoomUsage.values)
                      DropdownMenuItem(value: vUsage, child: Text(usageLabel(vText, vUsage))),
                  ],
                  onChanged: (pUsage) => onUsage(pUsage!),
                ),
              ],
            ),
            Text(
              vText.livingAreaRoom(
                formatSquareMetres(vArea.habitable),
                formatSquareMetres(vArea.carrez),
              ),
            ),
            if (vLow > 0.005)
              IconLine(Icons.height, vText.livingAreaLow(formatSquareMetres(vLow))),
            if (room.walls.length < 3 || !room.closed)
              IconLine(Icons.warning_amber_outlined, vText.livingAreaOpen),
          ],
        ),
      ),
    );
  }
}
