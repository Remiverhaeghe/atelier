import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/kitchen.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'kitchen_plan_card.dart';
import 'parquet_view.dart';
import 'theme.dart';

/// Cuisine en I ou en L : meubles bas, fileurs, plans de travail, hauteurs de pose, triangle
/// d'activité, hotte et implantation.
class KitchenCalculator extends StatefulWidget {
  const KitchenCalculator({super.key, this.rooms = const []});

  /// Pièces saisies : la cuisine donne ses dimensions et son volume.
  final List<Room> rooms;

  @override
  State<KitchenCalculator> createState() => _KitchenCalculatorState();
}

class _KitchenCalculatorState extends State<KitchenCalculator> {
  int _run1 = 2730;
  int _run2 = 0;
  int _person = 1750;
  bool _gas = false;

  String _modules(AppLocalizations pText, ModuleRun pRun) => [
    for (final vModule in pRun.modules) formatCentimetres(vModule),
    if (pRun.fillerMm > 0) pText.kitchenFiller(formatCentimetres(pRun.fillerMm)),
  ].join(' + ');

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vRuns = [_run1, _run2].where((pRun) => pRun > 0).toList();
    final vHeights = kitchenHeights(_person, pGas: _gas);
    NumberField<int> vField(String pLabel, int pInitial, ValueChanged<int> pSet) =>
        NumberField<int>(
          label: pLabel,
          initial: '$pInitial',
          parse: parseWhole,
          onValue: (pValue) => setState(() => pSet(pValue)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(vText.kitchenTitle)),
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
                  for (final (vIndex, vRun) in vRuns.indexed)
                    IconLine(
                      Icons.kitchen_outlined,
                      vText.kitchenRun(vIndex + 1, _modules(vText, fillRun(vRun))),
                    ),
                  IconLine(
                    Icons.table_restaurant_outlined,
                    vText.kitchenWorktops(
                      worktopsFor(vRuns).map((pLength) => formatCentimetres(pLength)).join(' + '),
                    ),
                  ),
                  IconLine(
                    Icons.height,
                    vText.kitchenWorktopHeight(formatCentimetres(vHeights.worktopMm)),
                  ),
                  IconLine(
                    Icons.vertical_align_top,
                    vText.kitchenWallUnits(formatCentimetres(vHeights.wallUnitsMm)),
                  ),
                  IconLine(Icons.air, vText.kitchenHood(formatCentimetres(vHeights.hoodMm))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          vField(vText.kitchenRun1, _run1, (pValue) => _run1 = pValue),
          vField(vText.kitchenRun2, _run2, (pValue) => _run2 = pValue),
          vField(vText.kitchenPerson, _person, (pValue) => _person = pValue),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.kitchenGas),
            value: _gas,
            onChanged: (pValue) => setState(() => _gas = pValue),
          ),
          const SizedBox(height: 16),
          KitchenPlanCard(rooms: widget.rooms),
          const SizedBox(height: 12),
          Text(vText.kitchenHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
