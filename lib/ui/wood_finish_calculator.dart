import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/extra_items.dart';
import '../logic/units.dart';
import '../logic/wood_finish.dart';
import 'parquet_view.dart';
import 'shopping_target.dart';
import 'sketch3d.dart';
import 'theme.dart';

/// Finitions du bois : choisir selon l'usage, puis la quantité, les pots et le temps de séchage.
class WoodFinishCalculator extends StatefulWidget {
  const WoodFinishCalculator({super.key});

  @override
  State<WoodFinishCalculator> createState() => _WoodFinishCalculatorState();
}

class _WoodFinishCalculatorState extends State<WoodFinishCalculator> {
  FinishUse _use = FinishUse.furniture;
  WoodFinish _finish = WoodFinish.varnish;
  double _area = 4;

  void _setUse(FinishUse pUse) {
    final vChoices = finishesFor(pUse);
    setState(() {
      _use = pUse;
      if (!vChoices.contains(_finish)) {
        _finish = vChoices.first;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planFinish(_finish, _area);
    final vName = finishName(vText, _finish);

    return Scaffold(
      appBar: AppBar(title: Text(vText.finishTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SegmentedButton<FinishUse>(
            segments: [
              ButtonSegment(value: FinishUse.furniture, label: Text(vText.finishUseFurniture)),
              ButtonSegment(value: FinishUse.floor, label: Text(vText.finishUseFloor)),
              ButtonSegment(value: FinishUse.outdoor, label: Text(vText.finishUseOutdoor)),
            ],
            selected: {_use},
            onSelectionChanged: (pUse) => _setUse(pUse.single),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final vFinish in finishesFor(_use))
                ChoiceChip(
                  label: Text(finishName(vText, vFinish)),
                  selected: vFinish == _finish,
                  onSelected: (_) => setState(() => _finish = vFinish),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vName, style: vTheme.textTheme.titleMedium),
                  Text(finishLook(vText, _finish), style: vTheme.textTheme.bodySmall),
                  AspectRatio(aspectRatio: 2.2, child: FinishSketch(finish: _finish)),
                  IconLine(
                    Icons.format_paint_outlined,
                    vText.finishLitres(formatDecimal(vPlan.litres), _finish.coats),
                  ),
                  for (final vPot in vPlan.pots.entries)
                    IconLine(
                      Icons.inventory_2_outlined,
                      vText.potCount(vPot.value, formatDecimal(vPot.key)),
                    ),
                  IconLine(
                    Icons.hourglass_bottom,
                    vText.finishWait(_finish.recoatHours, vPlan.waitHours),
                  ),
                  IconLine(
                    Icons.autorenew,
                    _finish.film
                        ? vText.finishRenewFilm(_finish.renewYears)
                        : vText.finishRenewSoak(_finish.renewYears),
                  ),
                  AddToShoppingButton(
                    items: () => [
                      for (final vPot in vPlan.pots.entries)
                        ExtraItem(
                          name: vText.finishPot(vName, formatDecimal(vPot.key)),
                          quantity: vPot.value,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          NumberField<double>(
            label: vText.finishArea,
            initial: formatDecimal(_area),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _area = pValue),
          ),
          const SizedBox(height: 12),
          IconLine(Icons.lightbulb_outline, vText.finishPrepare),
          Text(vText.finishHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}

String finishName(AppLocalizations pText, WoodFinish pFinish) => switch (pFinish) {
  WoodFinish.stain => pText.finishStain,
  WoodFinish.varnish => pText.finishVarnish,
  WoodFinish.floorVarnish => pText.finishFloorVarnish,
  WoodFinish.oil => pText.finishOil,
  WoodFinish.wax => pText.finishWax,
  WoodFinish.microporousPaint => pText.finishPaint,
};

String finishLook(AppLocalizations pText, WoodFinish pFinish) => switch (pFinish) {
  WoodFinish.stain => pText.finishStainLook,
  WoodFinish.varnish => pText.finishVarnishLook,
  WoodFinish.floorVarnish => pText.finishFloorVarnishLook,
  WoodFinish.oil => pText.finishOilLook,
  WoodFinish.wax => pText.finishWaxLook,
  WoodFinish.microporousPaint => pText.finishPaintLook,
};

/// Coupe d'une planche : un film posé dessus, ou une finition qui entre dans les fibres.
class FinishSketch extends StatelessWidget {
  const FinishSketch({super.key, required this.finish});

  final WoodFinish finish;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Sketch3D(
      parts: [
        if (finish.film) ...[
          Prism.box(0, 120, 0, 40, 0, 20),
          Prism.box(0, 120, 0, 40, 20, 23, role: PartRole.highlight),
        ] else ...[
          Prism.box(0, 120, 0, 40, 0, 14),
          Prism.box(0, 120, 0, 40, 14, 20, role: PartRole.highlight),
        ],
      ],
      callouts: [
        (
          at: (x: 60.0, y: 0.0, z: finish.film ? 22.0 : 17.0),
          text: finish.film ? vText.finishFilmLabel : vText.finishSoakLabel,
          shift: const Offset(0, -50),
        ),
        (at: (x: 20.0, y: 0.0, z: 6.0), text: vText.finishWoodLabel, shift: const Offset(-30, 40)),
      ],
    );
  }
}
