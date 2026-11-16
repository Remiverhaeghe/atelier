import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/units.dart';
import '../logic/window_frame.dart';
import 'parquet_view.dart';
import 'theme.dart';

String glazingLabel(AppLocalizations pText, Glazing pGlazing) => switch (pGlazing) {
  Glazing.doubleGlazing => pText.glazingDouble,
  Glazing.polycarbonate => pText.glazingPolycarbonate,
  Glazing.laminatedGlass => pText.glazingLaminated,
  Glazing.plexi => pText.glazingPlexi,
};

/// Cadre de fenêtre fixe à fabriquer : débit, feuillure, vitrage à commander et étapes.
class FrameCalculator extends StatefulWidget {
  const FrameCalculator({super.key, this.widthMm = 780, this.heightMm = 980});

  final int widthMm;
  final int heightMm;

  @override
  State<FrameCalculator> createState() => _FrameCalculatorState();
}

class _FrameCalculatorState extends State<FrameCalculator> {
  late int _width = widget.widthMm;
  late int _height = widget.heightMm;
  Glazing _glazing = Glazing.doubleGlazing;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planFrame(_width, _height, _glazing);
    String vCm(int pMm) => formatCentimetres(pMm);
    final vSteps = [
      vText.frameStep1,
      vText.frameStep2,
      vText.frameStep3,
      vText.frameStep4,
      vText.frameStep5,
      vText.frameStep6,
      vText.frameStep7,
      vText.frameStep8,
    ];

    return Scaffold(
      appBar: AppBar(title: Text(vText.frameTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          NumberField<int>(
            label: vText.frameWidth,
            initial: vCm(_width),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _width = pValue),
          ),
          NumberField<int>(
            label: vText.frameHeight,
            initial: vCm(_height),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _height = pValue),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<Glazing>(
            initialValue: _glazing,
            decoration: InputDecoration(labelText: vText.frameGlazing),
            items: [
              for (final vGlazing in Glazing.values)
                DropdownMenuItem(value: vGlazing, child: Text(glazingLabel(vText, vGlazing))),
            ],
            onChanged: (pGlazing) => setState(() => _glazing = pGlazing!),
          ),
          const SizedBox(height: 12),
          if (vPlan == null)
            IconLine(AtelierIcons.warning, vText.frameTooSmall)
          else ...[
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vText.frameCuts, style: vTheme.textTheme.titleMedium),
                    IconLine(Icons.straighten, vText.frameStiles(vCm(vPlan.stileMm))),
                    IconLine(Icons.straighten, vText.frameRails(vCm(vPlan.railMm))),
                    IconLine(
                      Icons.crop_square,
                      vText.frameSection(vCm(vPlan.faceMm), vCm(vPlan.depthMm)),
                    ),
                    IconLine(
                      Icons.join_inner,
                      vText.frameJoint(vCm(vPlan.faceMm)),
                    ),
                    IconLine(
                      Icons.vertical_split_outlined,
                      vText.frameRebate(vCm(rebateWidthMm), vCm(vPlan.rebateDepthMm)),
                    ),
                    IconLine(Icons.shopping_cart_outlined, vText.frameStock(vPlan.stockPieces)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              margin: EdgeInsets.zero,
              color: vTheme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vText.frameGlass, style: vTheme.textTheme.titleMedium),
                    BigFigure('${vCm(vPlan.glassWidthMm)} × ${vCm(vPlan.glassHeightMm)} cm'),
                    Text(vText.frameGlassDetail(
                      glazingLabel(vText, _glazing),
                      _glazing.thicknessMm,
                    )),
                    IconLine(Icons.horizontal_rule, vText.frameBeads(vCm(vPlan.beadsMm))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(vText.frameStepsTitle, style: vTheme.textTheme.titleMedium),
            for (var vIndex = 0; vIndex < vSteps.length; vIndex++)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 14, child: Text('${vIndex + 1}')),
                title: Text(vSteps[vIndex]),
              ),
            IconLine(AtelierIcons.warning, vText.frameSafety),
          ],
        ],
      ),
    );
  }
}
