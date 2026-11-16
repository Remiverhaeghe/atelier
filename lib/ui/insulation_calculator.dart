import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/insulation.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String partLabel(AppLocalizations pText, InsulatedPart pPart) => switch (pPart) {
  InsulatedPart.lostAttic => pText.insulLostAttic,
  InsulatedPart.rafters => pText.insulRafters,
  InsulatedPart.walls => pText.insulWalls,
  InsulatedPart.floor => pText.insulFloor,
};

String insulantLabel(AppLocalizations pText, Insulant pInsulant) => switch (pInsulant) {
  Insulant.glassWool => pText.insulGlassWool,
  Insulant.rockWool => pText.insulRockWool,
  Insulant.woodFibre => pText.insulWoodFibre,
  Insulant.cellulose => pText.insulCellulose,
  Insulant.polyurethane => pText.insulPolyurethane,
};

/// Isolation : épaisseur selon la résistance visée, couches, paquets et pare-vapeur.
class InsulationCalculator extends StatefulWidget {
  const InsulationCalculator({super.key});

  @override
  State<InsulationCalculator> createState() => _InsulationCalculatorState();
}

class _InsulationCalculatorState extends State<InsulationCalculator> {
  InsulatedPart _part = InsulatedPart.rafters;
  Insulant _insulant = Insulant.glassWool;
  double _area = 20;
  double _pack = 5;
  double? _targetR;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planInsulation(
      pPart: _part,
      pInsulant: _insulant,
      pAreaM2: _area,
      pPackM2: _pack,
      pTargetR: _targetR,
    );
    final vBlown = _insulant.thicknessesMm.isEmpty;

    return Scaffold(
      appBar: AppBar(title: Text(vText.insulTitle)),
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
                  Text(vText.insulThickness, style: vTheme.textTheme.titleMedium),
                  BigFigure(
                    vPlan.layersMm.map((pLayer) => '${formatCentimetres(pLayer)} cm').join(' + '),
                  ),
                  if (vPlan.layersMm.length == 2) IconLine(Icons.layers_outlined, vText.insulCrossed),
                  IconLine(
                    Icons.speed,
                    vText.insulR(formatDecimal(vPlan.achievedR), formatDecimal(vPlan.targetR)),
                  ),
                  if (vBlown)
                    IconLine(
                      Icons.inventory_2_outlined,
                      vText.insulBags(celluloseBags(_area, vPlan.layersMm.first)),
                    )
                  else
                    IconLine(Icons.inventory_2_outlined, vText.insulPacks(vPlan.packs)),
                  if (vPlan.vaporBarrierM2 > 0)
                    IconLine(
                      Icons.water_drop_outlined,
                      vText.insulVapor(formatSquareMetres(vPlan.vaporBarrierM2)),
                    ),
                  if (vPlan.hangers > 0)
                    IconLine(Icons.hardware_outlined, vText.insulHangers(vPlan.hangers)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<InsulatedPart>(
            initialValue: _part,
            decoration: InputDecoration(labelText: vText.insulPart),
            items: [
              for (final vPart in InsulatedPart.values)
                DropdownMenuItem(value: vPart, child: Text(partLabel(vText, vPart))),
            ],
            onChanged: (pPart) => setState(() {
              _part = pPart!;
              _targetR = null;
            }),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<Insulant>(
            initialValue: _insulant,
            decoration: InputDecoration(labelText: vText.insulMaterial),
            items: [
              for (final vInsulant in Insulant.values)
                DropdownMenuItem(value: vInsulant, child: Text(insulantLabel(vText, vInsulant))),
            ],
            onChanged: (pInsulant) => setState(() => _insulant = pInsulant!),
          ),
          NumberField<double>(
            label: vText.insulArea,
            initial: formatDecimal(_area),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _area = pValue),
          ),
          NumberField<double>(
            key: ValueKey(_part),
            label: vText.insulTarget,
            initial: formatDecimal(_part.targetR),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _targetR = pValue),
          ),
          if (!vBlown)
            NumberField<double>(
              label: vText.insulPackArea,
              initial: formatDecimal(_pack),
              parse: parseDecimal,
              onValue: (pValue) => setState(() => _pack = pValue),
            ),
          const SizedBox(height: 12),
          IconLine(Icons.thermostat_outlined, vText.insulThermalCheck),
        ],
      ),
    );
  }
}
