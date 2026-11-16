import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/units.dart';
import '../logic/ventilation.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// VMC simple flux : débits par pièce humide, entrées d'air, détalonnage des portes.
class VentilationCalculator extends StatefulWidget {
  const VentilationCalculator({super.key});

  @override
  State<VentilationCalculator> createState() => _VentilationCalculatorState();
}

class _VentilationCalculatorState extends State<VentilationCalculator> {
  int _mainRooms = 4;
  int _bathrooms = 1;
  int _toilets = 1;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planVentilation(
      pMainRooms: _mainRooms,
      pBathrooms: _bathrooms,
      pToilets: _toilets,
    );
    final vFlows = extractionFor(_mainRooms);

    return Scaffold(
      appBar: AppBar(title: Text(vText.ventTitle)),
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
                  BigFigure(vText.ventExtracted(vPlan.extractedM3h)),
                  IconLine(Icons.kitchen_outlined, vText.ventKitchen(vFlows.kitchen)),
                  if (_bathrooms > 0)
                    IconLine(Icons.shower_outlined, vText.ventBathroom(_bathrooms, vFlows.bathroom)),
                  if (_toilets > 0) IconLine(Icons.wc, vText.ventToilet(_toilets, vFlows.toilet)),
                  IconLine(Icons.air, vText.ventVents(vPlan.extractVents)),
                  IconLine(Icons.sensor_window_outlined, vText.ventInlets(vPlan.airInlets, vPlan.inletsM3h)),
                  IconLine(
                    Icons.door_back_door_outlined,
                    vText.ventUndercut(
                      formatCentimetres(undercutMm),
                      formatCentimetres(kitchenUndercutMm),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          NumberField<int>(
            label: vText.ventMainRooms,
            initial: '$_mainRooms',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _mainRooms = pValue),
          ),
          NumberField<int>(
            label: vText.ventBathrooms,
            initial: '$_bathrooms',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _bathrooms = pValue),
          ),
          NumberField<int>(
            label: vText.ventToilets,
            initial: '$_toilets',
            parse: parseWhole,
            onValue: (pValue) => setState(() => _toilets = pValue),
          ),
          const SizedBox(height: 12),
          Text(vText.ventHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
