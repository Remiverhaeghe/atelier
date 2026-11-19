import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/elec_layout.dart';
import '../logic/elec_plan.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import '../state/worksites_controller.dart';
import 'room_elec_screen.dart';
import 'theme.dart';

/// Électricité d'après les prises et interrupteurs posés sur les plans des pièces.
class ElecPlanScreen extends StatelessWidget {
  const ElecPlanScreen({super.key, required this.controller, required this.worksiteId});

  final WorksitesController controller;
  final String worksiteId;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return ListenableBuilder(listenable: controller, builder: (pContext, _) => _body(vText, vTheme, pContext));
  }

  Widget _body(AppLocalizations pText, ThemeData pTheme, BuildContext pContext) {
    final vText = pText;
    final vTheme = pTheme;
    final vRooms = controller.worksite(worksiteId)?.rooms ?? const <Room>[];
    final vPlan = elecPlan(vRooms);
    String vM(int pMm) => formatDecimal((pMm / 100).round() / 10);

    return Scaffold(
      appBar: AppBar(title: Text(vText.elecPlanTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          if (vPlan.boxes == 0)
            Text(vText.elecPlanEmpty)
          else
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BigFigure(vText.elecPlanCircuits(vPlan.socketCircuits + vPlan.lightCircuits)),
                    IconLine(
                      Icons.power_outlined,
                      vText.elecPlanSockets(vPlan.sockets, vPlan.socketCircuits),
                    ),
                    IconLine(
                      Icons.toggle_on_outlined,
                      vText.elecPlanLights(vPlan.lights, vPlan.lightCircuits),
                    ),
                    IconLine(
                      Icons.cable,
                      vText.elecPlanSheath(vM(vPlan.sheath20Mm), vM(vPlan.sheath16Mm)),
                    ),
                    IconLine(
                      Icons.linear_scale,
                      vText.elecPlanWire(vM(vPlan.wire25Mm), vM(vPlan.wire15Mm)),
                    ),
                    IconLine(Icons.crop_square, vText.elecPlanBoxes(vPlan.boxes)),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 12),
          Text(vText.elecRoomsTitle, style: vTheme.textTheme.titleMedium),
          for (final vRoom in vRooms)
            if (proposeElec(vRoom) case final vProposal?)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  vProposal.newSockets.isEmpty ? Icons.check_circle_outline : Icons.power_outlined,
                ),
                title: Text(vRoom.name),
                subtitle: Text(
                  vText.elecRoomCount(vProposal.existingSockets, vProposal.requiredSockets),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  pContext,
                  MaterialPageRoute<void>(
                    builder: (_) => RoomElecScreen(
                      controller: controller,
                      worksiteId: worksiteId,
                      roomId: vRoom.id,
                    ),
                  ),
                ),
              ),
          const SizedBox(height: 12),
          Text(vText.elecPlanHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
