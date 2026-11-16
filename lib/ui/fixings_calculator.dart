import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/fixings.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String supportLabel(AppLocalizations pText, WallSupport pSupport) => switch (pSupport) {
  WallSupport.drywall => pText.supportDrywall,
  WallSupport.concrete => pText.supportConcrete,
  WallSupport.solidBrick => pText.supportSolidBrick,
  WallSupport.hollowBrick => pText.supportHollowBrick,
  WallSupport.aeratedBlock => pText.supportAerated,
  WallSupport.wood => pText.supportWood,
};

String plugLabel(AppLocalizations pText, PlugKind pPlug) => switch (pPlug) {
  PlugKind.none => pText.plugNone,
  PlugKind.universalNylon => pText.plugUniversal,
  PlugKind.drywallMetal => pText.plugDrywallMetal,
  PlugKind.drywallToggle => pText.plugToggle,
  PlugKind.longNylon => pText.plugLong,
  PlugKind.chemical => pText.plugChemical,
  PlugKind.aeratedSpiral => pText.plugAerated,
};

/// Quelle cheville, quelle vis : support, poids de l'objet et nombre de points.
class FixingsCalculator extends StatefulWidget {
  const FixingsCalculator({super.key});

  @override
  State<FixingsCalculator> createState() => _FixingsCalculatorState();
}

class _FixingsCalculatorState extends State<FixingsCalculator> {
  WallSupport _support = WallSupport.drywall;
  double _weight = 20;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vPoints = fixingPoints(_weight, FixingLoad.medium);
    final vLoad = loadFor(_weight, vPoints);
    final vAdvice = adviseFixing(_support, vLoad);

    return Scaffold(
      appBar: AppBar(title: Text(vText.fixingsTitle)),
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
                  BigFigure(plugLabel(vText, vAdvice.plug)),
                  IconLine(Icons.hardware_outlined, vText.fixingsDrill(vAdvice.drillMm)),
                  IconLine(
                    Icons.settings_outlined,
                    vText.fixingsScrew(vAdvice.screwDiameterMm, vAdvice.screwLengthMm),
                  ),
                  IconLine(Icons.push_pin_outlined, vText.fixingsPoints(vPoints)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<WallSupport>(
            initialValue: _support,
            decoration: InputDecoration(labelText: vText.fixingsSupport),
            items: [
              for (final vSupport in WallSupport.values)
                DropdownMenuItem(value: vSupport, child: Text(supportLabel(vText, vSupport))),
            ],
            onChanged: (pSupport) => setState(() => _support = pSupport!),
          ),
          NumberField<double>(
            label: vText.fixingsWeight,
            initial: formatDecimal(_weight),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _weight = pValue),
          ),
          const SizedBox(height: 12),
          IconLine(Icons.sensors, vText.netDrillDetector),
          Text(vText.fixingsHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
