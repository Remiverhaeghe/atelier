import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/garden.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Jardin : pelouse, massifs, terre, paillage et plants à acheter.
class GardenCalculator extends StatefulWidget {
  const GardenCalculator({super.key});

  @override
  State<GardenCalculator> createState() => _GardenCalculatorState();
}

class _GardenCalculatorState extends State<GardenCalculator> {
  var _design = const GardenDesign();

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vNeeds = gardenNeeds(_design);
    void vSet(GardenDesign pDesign) => setState(() => _design = pDesign);

    return Scaffold(
      appBar: AppBar(title: Text(vText.gardenTitle)),
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
                  Text(vText.resultsTitle, style: vTheme.textTheme.titleMedium),
                  if (_design.turf)
                    IconLine(Icons.grass, vText.gardenTurf(vNeeds.turfRolls))
                  else
                    IconLine(Icons.grass, vText.gardenSeed(vNeeds.seedBoxes)),
                  IconLine(Icons.landscape_outlined, vText.gardenSoil(vNeeds.soilBags)),
                  IconLine(Icons.layers_outlined, vText.gardenMulch(vNeeds.mulchBags)),
                  IconLine(Icons.local_florist_outlined, vText.gardenPlants(vNeeds.plants)),
                  const SizedBox(height: 4),
                  Text(vText.gardenHint, style: vTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          NumberField<double>(
            label: vText.gardenLawn,
            initial: '',
            parse: parseDecimal,
            onValue: (pValue) => vSet(_design.copyWith(lawnM2: pValue)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.gardenTurfSwitch),
            value: _design.turf,
            onChanged: (pValue) => vSet(_design.copyWith(turf: pValue)),
          ),
          NumberField<double>(
            label: vText.gardenBeds,
            initial: '',
            parse: parseDecimal,
            onValue: (pValue) => vSet(_design.copyWith(bedsM2: pValue)),
          ),
          NumberField(
            label: vText.gardenSoilDepth,
            initial: formatCentimetres(_design.soilDepthMm),
            parse: parseCentimetres,
            onValue: (pValue) => vSet(_design.copyWith(soilDepthMm: pValue)),
          ),
          NumberField(
            label: vText.gardenMulchDepth,
            initial: formatCentimetres(_design.mulchDepthMm),
            parse: parseCentimetres,
            onValue: (pValue) => vSet(_design.copyWith(mulchDepthMm: pValue)),
          ),
          NumberField(
            label: vText.gardenDensity,
            initial: '${_design.plantsPerM2}',
            parse: parseWhole,
            onValue: (pValue) => vSet(_design.copyWith(plantsPerM2: pValue)),
          ),
        ],
      ),
    );
  }
}
