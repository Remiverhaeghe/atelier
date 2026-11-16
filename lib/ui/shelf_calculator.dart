import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/shelf.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String shelfMaterialLabel(AppLocalizations pText, ShelfMaterial pMaterial) => switch (pMaterial) {
  ShelfMaterial.particleBoard => pText.materialParticleBoard,
  ShelfMaterial.mdf => pText.materialMdf,
  ShelfMaterial.plywood => pText.materialPlywood,
  ShelfMaterial.solidWood => pText.materialSolidWood,
};

String shelfPartLabel(AppLocalizations pText, String pName) => switch (pName) {
  sidePart => pText.partSide,
  shelfPart => pText.partShelf,
  _ => pText.partBack,
};

/// Étagère sur mesure : dimensions, panneau, liste de débit et alerte de portée.
class ShelfCalculator extends StatefulWidget {
  const ShelfCalculator({super.key});

  @override
  State<ShelfCalculator> createState() => _ShelfCalculatorState();
}

class _ShelfCalculatorState extends State<ShelfCalculator> {
  var _design = const ShelfDesign();

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planShelf(_design);
    void vSet(ShelfDesign pDesign) => setState(() => _design = pDesign);

    return Scaffold(
      appBar: AppBar(title: Text(vText.shelfTitle)),
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
                  Text(vText.cutListTitle, style: vTheme.textTheme.titleMedium),
                  for (final vPart in vPlan.parts)
                    IconLine(
                      Icons.straighten,
                      vText.cutListLine(
                        vPart.count,
                        shelfPartLabel(vText, vPart.name),
                        formatCentimetres(vPart.lengthMm),
                        formatCentimetres(vPart.widthMm),
                      ),
                    ),
                  IconLine(Icons.layers_outlined, vText.shelfBoards(vPlan.boards)),
                  IconLine(Icons.hardware_outlined, vText.shelfScrews(vPlan.screws)),
                  IconLine(Icons.height, vText.shelfGap(formatCentimetres(vPlan.gapMm))),
                  if (vPlan.tooWide)
                    IconLine(
                      Icons.warning_amber,
                      vText.shelfTooWide(formatCentimetres(vPlan.maxSpanMm)),
                      color: vTheme.colorScheme.error,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ShelfMaterial>(
            initialValue: _design.material,
            decoration: InputDecoration(labelText: vText.shelfMaterial),
            items: [
              for (final vMaterial in ShelfMaterial.values)
                DropdownMenuItem(
                  value: vMaterial,
                  child: Text(shelfMaterialLabel(vText, vMaterial)),
                ),
            ],
            onChanged: (pMaterial) => vSet(_design.copyWith(material: pMaterial)),
          ),
          for (final (vLabel, vValue, vApply) in [
            (vText.shelfWidth, _design.widthMm, (int pValue) => _design.copyWith(widthMm: pValue)),
            (
              vText.shelfHeight,
              _design.heightMm,
              (int pValue) => _design.copyWith(heightMm: pValue),
            ),
            (vText.shelfDepth, _design.depthMm, (int pValue) => _design.copyWith(depthMm: pValue)),
            (
              vText.shelfThickness,
              _design.thicknessMm,
              (int pValue) => _design.copyWith(thicknessMm: pValue),
            ),
          ])
            NumberField(
              label: vLabel,
              initial: formatCentimetres(vValue),
              parse: parseCentimetres,
              onValue: (pValue) => vSet(vApply(pValue)),
            ),
          NumberField(
            label: vText.shelfCount,
            initial: '${_design.shelves}',
            parse: parseWhole,
            onValue: (pValue) => vSet(_design.copyWith(shelves: pValue)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.shelfBack),
            value: _design.back,
            onChanged: (pValue) => vSet(_design.copyWith(back: pValue)),
          ),
        ],
      ),
    );
  }
}
