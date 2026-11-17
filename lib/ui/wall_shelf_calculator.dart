import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/fixings.dart';
import '../logic/shelf.dart';
import '../logic/shelf_joinery.dart';
import '../logic/units.dart';
import 'fixings_calculator.dart';
import 'parquet_view.dart';
import 'shelf_calculator.dart';
import 'shelf_joinery_card.dart';
import 'theme.dart';

/// Tablette murale sur équerres : nombre et écart des équerres, bras, poids et chevilles.
class WallShelfCalculator extends StatefulWidget {
  const WallShelfCalculator({super.key});

  @override
  State<WallShelfCalculator> createState() => _WallShelfCalculatorState();
}

class _WallShelfCalculatorState extends State<WallShelfCalculator> {
  var _shelf = const WallShelf();

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planBrackets(_shelf);
    void vSet(WallShelf pShelf) => setState(() => _shelf = pShelf);

    return Scaffold(
      appBar: AppBar(title: Text(vText.wallShelfTitle)),
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
                  BigFigure(
                    vText.bracketCount(vPlan.brackets, formatCentimetres(vPlan.spacingMm)),
                  ),
                  IconLine(
                    Icons.open_in_full,
                    vText.bracketOverhang(formatCentimetres(vPlan.overhangMm)),
                  ),
                  IconLine(Icons.turn_right, vText.bracketArm(formatCentimetres(vPlan.armMm))),
                  IconLine(
                    Icons.scale_outlined,
                    vText.bracketLoad(
                      vPlan.totalKg.round(),
                      vPlan.kgPerBracket.round(),
                      vPlan.pullKg.round(),
                    ),
                  ),
                  IconLine(
                    Icons.hardware_outlined,
                    vText.bracketFixing(
                      plugLabel(vText, vPlan.fixing.plug),
                      vPlan.fixing.screwDiameterMm,
                      vPlan.fixing.screwLengthMm,
                      vPlan.fixing.drillMm,
                    ),
                  ),
                  Text(vText.bracketTip, style: vTheme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ShelfLoadField(load: _shelf.load, onChanged: (pLoad) => vSet(_shelf.copyWith(load: pLoad))),
          DropdownButtonFormField<WallSupport>(
            initialValue: _shelf.wall,
            decoration: InputDecoration(labelText: vText.fixingsSupport),
            items: [
              for (final vSupport in WallSupport.values)
                DropdownMenuItem(value: vSupport, child: Text(supportLabel(vText, vSupport))),
            ],
            onChanged: (pSupport) => vSet(_shelf.copyWith(wall: pSupport)),
          ),
          DropdownButtonFormField<ShelfMaterial>(
            initialValue: _shelf.material,
            decoration: InputDecoration(labelText: vText.shelfMaterial),
            items: [
              for (final vMaterial in ShelfMaterial.values)
                DropdownMenuItem(
                  value: vMaterial,
                  child: Text(shelfMaterialLabel(vText, vMaterial)),
                ),
            ],
            onChanged: (pMaterial) => vSet(_shelf.copyWith(material: pMaterial)),
          ),
          for (final (vLabel, vValue, vApply) in [
            (
              vText.shelfWidth,
              _shelf.lengthMm,
              (int pValue) => _shelf.copyWith(lengthMm: pValue),
            ),
            (vText.shelfDepth, _shelf.depthMm, (int pValue) => _shelf.copyWith(depthMm: pValue)),
            (
              vText.shelfThickness,
              _shelf.thicknessMm,
              (int pValue) => _shelf.copyWith(thicknessMm: pValue),
            ),
          ])
            NumberField(
              label: vLabel,
              initial: formatCentimetres(vValue),
              parse: parseCentimetres,
              onValue: (pValue) => vSet(vApply(pValue)),
            ),
        ],
      ),
    );
  }
}
