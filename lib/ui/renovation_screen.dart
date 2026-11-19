import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/heat_loss.dart';
import '../logic/renovation_steps.dart';
import 'energy_diagnosis_screen.dart';
import 'theme.dart';

String heatingLabel(AppLocalizations pText, HeatingSystem pSystem) => switch (pSystem) {
  HeatingSystem.oldBoiler => pText.renovOldBoiler,
  HeatingSystem.condensingBoiler => pText.renovCondensing,
  HeatingSystem.electric => pText.renovElectric,
  HeatingSystem.heatPump => pText.renovHeatPump,
  HeatingSystem.woodStove => pText.renovWoodStove,
};

String stepTitle(AppLocalizations pText, RenovationStep pStep) => switch (pStep) {
  RenovationStep.roof => pText.renovStepRoof,
  RenovationStep.windows => pText.renovStepWindows,
  RenovationStep.walls => pText.renovStepWalls,
  RenovationStep.heating => pText.renovStepHeating,
  RenovationStep.ventilation => pText.renovStepVentilation,
};

/// Pourquoi l'étape vient à cette place.
String stepWhy(AppLocalizations pText, RenovationStep pStep) => switch (pStep) {
  RenovationStep.roof => pText.renovWhyRoof,
  RenovationStep.windows => pText.renovWhyWindows,
  RenovationStep.walls => pText.renovWhyWalls,
  RenovationStep.heating => pText.renovWhyHeating,
  RenovationStep.ventilation => pText.renovWhyVentilation,
};

/// Rénovation énergétique pas à pas : ordre des travaux, effet estimé sur la facture et aides
/// à vérifier avant chaque devis.
class RenovationScreen extends StatefulWidget {
  const RenovationScreen({super.key, this.envelope = const Envelope()});

  /// Maison telle que décrite dans le diagnostic thermique.
  final Envelope envelope;

  @override
  State<RenovationScreen> createState() => _RenovationScreenState();
}

class _RenovationScreenState extends State<RenovationScreen> {
  HeatingSystem _now = HeatingSystem.oldBoiler;
  HeatingSystem _new = HeatingSystem.heatPump;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vSteps = renovationPlan(widget.envelope, _now, _new);
    DropdownButtonFormField<HeatingSystem> vHeating(
      String pLabel,
      HeatingSystem pValue,
      ValueChanged<HeatingSystem> pSet,
    ) => DropdownButtonFormField<HeatingSystem>(
      key: ValueKey(pLabel),
      initialValue: pValue,
      isExpanded: true,
      decoration: InputDecoration(labelText: pLabel),
      items: [
        for (final vSystem in HeatingSystem.values)
          DropdownMenuItem(value: vSystem, child: Text(heatingLabel(vText, vSystem))),
      ],
      onChanged: (pSystem) => setState(() => pSet(pSystem!)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(vText.renovTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(vText.renovIntro),
          const SizedBox(height: 8),
          vHeating(vText.renovHeatingNow, _now, (pSystem) => _now = pSystem),
          vHeating(vText.renovHeatingNew, _new, (pSystem) => _new = pSystem),
          const SizedBox(height: 12),
          for (final (vIndex, vStep) in vSteps.indexed)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vText.renovStepNumber(vIndex + 1, stepTitle(vText, vStep.step)),
                      style: vTheme.textTheme.titleMedium,
                    ),
                    Text(stepWhy(vText, vStep.step)),
                    const SizedBox(height: 6),
                    if (vStep.skipped)
                      IconLine(Icons.check_circle_outline, vText.renovSkipped)
                    else
                      IconLine(
                        Icons.trending_down,
                        roundedPercent(vStep.stepShare) == 0
                            ? vText.renovSmallGain
                            : vText.renovGain(roundedPercent(vStep.stepShare)),
                      ),
                    IconLine(
                      Icons.receipt_long_outlined,
                      vText.renovRemaining(roundedPercent(vStep.remainingShare)),
                    ),
                    LinearProgressIndicator(value: vStep.remainingShare.clamp(0.0, 1.0)),
                    if (!vStep.skipped) ...[
                      const SizedBox(height: 6),
                      IconLine(Icons.account_balance_outlined, vText.renovAidCheck),
                    ],
                  ],
                ),
              ),
            ),
          IconLine(Icons.info_outline, vText.renovFloorNote),
          IconLine(Icons.account_balance_outlined, vText.energyAids),
          const SizedBox(height: 8),
          Text(vText.renovHint, style: vTheme.textTheme.bodySmall),
          const SizedBox(height: 8),
          Text(
            vText.renovStart(
              envelopeStateLabel(
                vText,
                EnvelopePart.roof,
                widget.envelope.stateOf(EnvelopePart.roof),
              ),
              envelopeStateLabel(
                vText,
                EnvelopePart.walls,
                widget.envelope.stateOf(EnvelopePart.walls),
              ),
            ),
            style: vTheme.textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
