import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/elec_layout.dart';
import '../logic/electricity.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import '../state/worksites_controller.dart';
import 'electricity_calculator.dart';
import 'room_plan.dart';
import 'theme.dart';

/// Prises et éclairage d'une pièce : minimum courant de la norme, ce qui est déjà posé, et
/// les places proposées, dessinées sur le plan avant de les poser.
class RoomElecScreen extends StatefulWidget {
  const RoomElecScreen({
    super.key,
    required this.controller,
    required this.worksiteId,
    required this.roomId,
  });

  final WorksitesController controller;
  final String worksiteId;
  final String roomId;

  @override
  State<RoomElecScreen> createState() => _RoomElecScreenState();
}

class _RoomElecScreenState extends State<RoomElecScreen> {
  ElecRoomKind? _kind;

  Room? get _room => widget.controller
      .worksite(widget.worksiteId)
      ?.rooms
      .where((pRoom) => pRoom.id == widget.roomId)
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (pContext, _) {
        final vRoom = _room;
        if (vRoom == null) {
          return const Scaffold();
        }
        final vKind = _kind ?? guessElecKind(vRoom.name);
        final vProposal = proposeElec(vRoom, pKind: vKind);
        final vNothing =
            vProposal == null || (vProposal.newSockets.isEmpty && vProposal.newSwitch == null);
        final vPreview = vProposal == null
            ? vRoom
            : withProposal(vRoom, vProposal, pNewId: widget.controller.newId);

        return Scaffold(
          appBar: AppBar(title: Text(vText.elecRoomTitle(vRoom.name))),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              DropdownButtonFormField<ElecRoomKind>(
                initialValue: vKind,
                decoration: InputDecoration(labelText: vText.elecRoomKind),
                items: [
                  for (final vChoice in ElecRoomKind.values)
                    DropdownMenuItem(value: vChoice, child: Text(elecRoomLabel(vText, vChoice))),
                ],
                onChanged: (pKind) => setState(() => _kind = pKind),
              ),
              const SizedBox(height: 8),
              if (vProposal == null)
                Text(vText.elecRoomNoPlan)
              else ...[
                AspectRatio(
                  aspectRatio: 1.3,
                  child: RoomPlan(
                    room: vPreview,
                    // Les numéros de mur se confondraient avec le repère du point lumineux
                    wallNumbers: false,
                    markers: [
                      (
                        number: 1,
                        xMm: vProposal.light.x.round(),
                        yMm: vProposal.light.y.round(),
                        done: false,
                      ),
                    ],
                  ),
                ),
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BigFigure(vText.elecRoomSockets(vProposal.requiredSockets)),
                        IconLine(
                          Icons.power_outlined,
                          vText.elecRoomExisting(
                            vProposal.existingSockets,
                            vProposal.newSockets.length,
                          ),
                        ),
                        IconLine(Icons.lightbulb_outline, vText.elecRoomLight(vProposal.lights)),
                        IconLine(
                          Icons.toggle_on_outlined,
                          vProposal.hasSwitch ? vText.elecRoomSwitchDone : vText.elecRoomSwitch,
                        ),
                        IconLine(
                          Icons.height,
                          vText.elecRoomHeights(
                            formatCentimetres(socketAxisMm),
                            formatCentimetres(switchAxisMm),
                          ),
                        ),
                        if (vKind == ElecRoomKind.kitchen)
                          IconLine(
                            Icons.kitchen_outlined,
                            vText.elecRoomKitchen(formatCentimetres(worktopSocketAxisMm)),
                          ),
                        if (hasWetZones(vKind))
                          IconLine(
                            Icons.shower_outlined,
                            vText.elecRoomWet,
                            color: vTheme.colorScheme.error,
                          ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          onPressed: vNothing
                              ? null
                              : () => widget.controller.updateRoom(widget.worksiteId, vPreview),
                          icon: const Icon(Icons.add_location_alt_outlined),
                          label: Text(vNothing ? vText.elecRoomComplete : vText.elecRoomPlace),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Text(vText.elecRoomHint, style: vTheme.textTheme.bodySmall),
            ],
          ),
        );
      },
    );
  }
}
