import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/dropped_ceiling.dart';
import '../logic/extra_items.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'shopping_target.dart';
import 'sketch3d.dart';
import 'theme.dart';

/// Faux plafond : abaisser une pièce trop haute, l'ossature à acheter et le volume gagné.
class DroppedCeilingCalculator extends StatefulWidget {
  const DroppedCeilingCalculator({super.key});

  @override
  State<DroppedCeilingCalculator> createState() => _DroppedCeilingCalculatorState();
}

class _DroppedCeilingCalculatorState extends State<DroppedCeilingCalculator> {
  int _lengthMm = 5000;
  int _widthMm = 4000;
  int _heightMm = 3500;
  int _wantedMm = 2500;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planDroppedCeiling(
      pLengthMm: _lengthMm,
      pWidthMm: _widthMm,
      pHeightMm: _heightMm,
      pWantedMm: _wantedMm,
    );
    final vVolume = _lengthMm * _widthMm * _heightMm / 1e9;
    final vShare = vVolume <= 0 ? 0 : (100 * vPlan.savedVolumeM3 / vVolume).round();

    return Scaffold(
      appBar: AppBar(title: Text(vText.ceilingTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          AspectRatio(
            aspectRatio: 1.6,
            child: CeilingSketch(heightMm: _heightMm, wantedMm: _wantedMm),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vText.resultsTitle, style: vTheme.textTheme.titleMedium),
                  if (vPlan.tooLow)
                    IconLine(
                      Icons.warning_amber,
                      vText.ceilingTooLow(formatCentimetres(minLivingHeightMm)),
                      color: vTheme.colorScheme.error,
                    ),
                  IconLine(Icons.height, vText.ceilingPlenum(formatCentimetres(vPlan.plenumMm))),
                  IconLine(Icons.link, switch (vPlan.hanging) {
                    Hanging.direct => vText.ceilingHangDirect,
                    Hanging.rod => vText.ceilingHangRod,
                    Hanging.braced => vText.ceilingHangBraced,
                  }),
                  IconLine(
                    Icons.horizontal_rule,
                    vText.ceilingFurring(vPlan.furringBars, vPlan.rows),
                  ),
                  IconLine(Icons.vertical_align_top, vText.ceilingHangers(vPlan.hangers)),
                  if (vPlan.rods > 0) IconLine(Icons.straighten, vText.ceilingRods(vPlan.rods)),
                  if (vPlan.joints > 0)
                    IconLine(Icons.compare_arrows, vText.ceilingJoints(vPlan.joints)),
                  IconLine(Icons.border_outer, vText.ceilingAngles(vPlan.angleBars)),
                  IconLine(Icons.dashboard_outlined, vText.ceilingBoards(vPlan.boards)),
                  IconLine(Icons.hardware_outlined, vText.ceilingScrews(vPlan.screws)),
                  IconLine(
                    Icons.local_fire_department_outlined,
                    vText.ceilingSaved(formatDecimal(vPlan.savedVolumeM3), vShare),
                  ),
                  AddToShoppingButton(
                    items: () => [
                      ExtraItem(name: vText.ceilingFurringItem, quantity: vPlan.furringBars),
                      ExtraItem(name: vText.ceilingHangerItem, quantity: vPlan.hangers),
                      ExtraItem(name: vText.ceilingRodItem, quantity: vPlan.rods),
                      ExtraItem(name: vText.ceilingJointItem, quantity: vPlan.joints),
                      ExtraItem(name: vText.ceilingAngleItem, quantity: vPlan.angleBars),
                      ExtraItem(name: vText.ceilingBoardItem, quantity: vPlan.boards),
                      ExtraItem(name: vText.ceilingScrewItem, quantity: vPlan.screws),
                    ].where((pItem) => pItem.quantity > 0).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          NumberField(
            label: vText.ceilingLength,
            initial: formatCentimetres(_lengthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _lengthMm = pValue),
          ),
          NumberField(
            label: vText.ceilingWidth,
            initial: formatCentimetres(_widthMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _widthMm = pValue),
          ),
          NumberField(
            label: vText.ceilingNowHeight,
            initial: formatCentimetres(_heightMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _heightMm = pValue),
          ),
          NumberField(
            label: vText.ceilingWanted,
            initial: formatCentimetres(_wantedMm),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _wantedMm = pValue),
          ),
          const SizedBox(height: 12),
          IconLine(Icons.lightbulb_outline, vText.ceilingTip),
          Text(vText.ceilingHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Coupe de la pièce : le vieux plafond, le nouveau, et les suspentes entre les deux.
class CeilingSketch extends StatelessWidget {
  const CeilingSketch({super.key, required this.heightMm, required this.wantedMm});

  final int heightMm;
  final int wantedMm;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    // Hauteurs ramenées sur 100, pour garder le même dessin quelle que soit la pièce
    const vTop = 100.0;
    final vNew = heightMm <= 0 ? vTop : (100 * wantedMm / heightMm).clamp(20.0, vTop - 4);

    return Sketch3D(
      parts: [
        Prism.box(0, 140, 0, 50, -4, 0, role: PartRole.board),
        Prism.box(0, 140, 0, 50, vTop, vTop + 6, role: PartRole.board),
        for (final vX in [30.0, 70.0, 110.0])
          Prism.box(vX, vX + 1.5, 20, 21.5, vNew + 2, vTop, role: PartRole.ghost),
        Prism.box(0, 140, 0, 50, vNew, vNew + 2, role: PartRole.highlight),
      ],
      callouts: [
        (
          at: (x: 140.0, y: 0.0, z: vTop + 3),
          text: vText.ceilingOldLabel,
          shift: const Offset(30, -20),
        ),
        (
          at: (x: 140.0, y: 0.0, z: vNew + 1),
          text: vText.ceilingNewLabel,
          shift: const Offset(30, 10),
        ),
        (
          at: (x: 70.0, y: 20.0, z: (vNew + vTop) / 2),
          text: vText.ceilingHangerLabel,
          shift: const Offset(-90, 0),
        ),
      ],
    );
  }
}
