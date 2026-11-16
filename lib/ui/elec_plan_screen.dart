import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/elec_plan.dart';
import '../logic/units.dart';
import '../state/worksites_controller.dart';
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
    final vPlan = elecPlan(controller.worksite(worksiteId)?.rooms ?? const []);
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
          Text(vText.elecPlanHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
