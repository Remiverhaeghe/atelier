import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/debris.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String debrisKindLabel(AppLocalizations pText, DebrisKind pKind) => switch (pKind) {
  DebrisKind.rubble => pText.debrisRubble,
  DebrisKind.plaster => pText.debrisPlaster,
  DebrisKind.wood => pText.debrisWood,
  DebrisKind.insulation => pText.debrisInsulation,
  DebrisKind.metal => pText.debrisMetal,
  DebrisKind.mixed => pText.debrisMixed,
};

/// Gravats à évacuer : ce qu'on démolit, puis volume, poids, big bags et voyages par benne.
class DebrisCalculator extends StatefulWidget {
  const DebrisCalculator({super.key});

  @override
  State<DebrisCalculator> createState() => _DebrisCalculatorState();
}

class _DebrisCalculatorState extends State<DebrisCalculator> {
  // Chaque ligne garde un numéro pour que ses champs ne se mélangent pas à la suppression
  final _lines = <(int, DebrisLine)>[(0, (kind: DebrisKind.rubble, areaM2: 10, thicknessMm: 60))];
  var _next = 1;

  void _set(int pIndex, DebrisLine pLine) =>
      setState(() => _lines[pIndex] = (_lines[pIndex].$1, pLine));

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPlan = debrisPlan([for (final (_, vLine) in _lines) vLine]);

    return Scaffold(
      appBar: AppBar(title: Text(vText.debrisTitle)),
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
                  BigFigure(vText.debrisVolume(formatDecimal(vPlan.bulkM3))),
                  IconLine(Icons.scale_outlined, vText.debrisWeight(vPlan.kg.round())),
                  IconLine(Icons.shopping_bag_outlined, vText.debrisBags(vPlan.bigBags)),
                  IconLine(Icons.rv_hookup, vText.debrisTrips(vPlan.trips)),
                  for (final vBin in vPlan.bins)
                    IconLine(
                      Icons.delete_outline,
                      vText.debrisBin(
                        debrisKindLabel(vText, vBin.kind),
                        formatDecimal(vBin.bulkM3),
                        vBin.kg.round(),
                      ),
                    ),
                ],
              ),
            ),
          ),
          for (final (vIndex, (vId, vLine)) in _lines.indexed)
            Card(
              key: ValueKey(vId),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 4, 8),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<DebrisKind>(
                            initialValue: vLine.kind,
                            decoration: InputDecoration(labelText: vText.debrisKind),
                            items: [
                              for (final vKind in DebrisKind.values)
                                DropdownMenuItem(
                                  value: vKind,
                                  child: Text(debrisKindLabel(vText, vKind)),
                                ),
                            ],
                            onChanged: (pKind) => _set(vIndex, (
                              kind: pKind!,
                              areaM2: vLine.areaM2,
                              thicknessMm: vLine.thicknessMm,
                            )),
                          ),
                        ),
                        IconButton(
                          tooltip: vText.delete,
                          icon: const Icon(Icons.close),
                          onPressed: _lines.length < 2
                              ? null
                              : () => setState(() => _lines.removeAt(vIndex)),
                        ),
                      ],
                    ),
                    NumberField<double>(
                      label: vText.debrisArea,
                      initial: formatDecimal(vLine.areaM2),
                      parse: parseDecimal,
                      onValue: (pValue) => _set(vIndex, (
                        kind: vLine.kind,
                        areaM2: pValue,
                        thicknessMm: vLine.thicknessMm,
                      )),
                    ),
                    NumberField<int>(
                      label: vText.debrisThickness,
                      initial: '${vLine.thicknessMm}',
                      parse: parseWhole,
                      onValue: (pValue) => _set(vIndex, (
                        kind: vLine.kind,
                        areaM2: vLine.areaM2,
                        thicknessMm: pValue,
                      )),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => setState(
              () => _lines.add((_next++, (kind: DebrisKind.plaster, areaM2: 10, thicknessMm: 13))),
            ),
            icon: const Icon(Icons.add),
            label: Text(vText.debrisAdd),
          ),
          const SizedBox(height: 12),
          Text(vText.debrisHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
