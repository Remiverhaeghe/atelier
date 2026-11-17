import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/height_safety.dart';
import '../logic/units.dart';
import 'parquet_view.dart';

String heightCheckLabel(AppLocalizations pText, HeightCheck pCheck) => switch (pCheck) {
  HeightCheck.notAlone => pText.heightCheckNotAlone,
  HeightCheck.stepladder => pText.heightCheckStepladder,
  HeightCheck.guardrails => pText.heightCheckGuardrails,
  HeightCheck.towerBraked => pText.heightCheckTower,
  HeightCheck.zoneBelow => pText.heightCheckZone,
  HeightCheck.harness => pText.heightCheckHarness,
  HeightCheck.weather => pText.heightCheckWeather,
};

/// Avant de monter : vérifications selon la hauteur de travail, à cocher une à une.
class HeightWorkScreen extends StatefulWidget {
  const HeightWorkScreen({super.key, this.workHeightMm = 2500});

  final int workHeightMm;

  @override
  State<HeightWorkScreen> createState() => _HeightWorkScreenState();
}

class _HeightWorkScreenState extends State<HeightWorkScreen> {
  late var _height = widget.workHeightMm;
  var _roof = false;
  final _done = <HeightCheck>{};

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vChecks = heightChecks(_height, pRoof: _roof);
    final vReady = vChecks.every(_done.contains);

    return Scaffold(
      appBar: AppBar(title: Text(vText.heightWorkTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          NumberField(
            label: vText.heightWorkHeight,
            initial: formatCentimetres(_height),
            parse: parseCentimetres,
            onValue: (pValue) => setState(() => _height = pValue),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.heightWorkRoof),
            value: _roof,
            onChanged: (pValue) => setState(() => _roof = pValue),
          ),
          Card(
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                for (final vCheck in vChecks)
                  CheckboxListTile(
                    value: _done.contains(vCheck),
                    title: Text(heightCheckLabel(vText, vCheck)),
                    onChanged: (pValue) =>
                        setState(() => pValue == true ? _done.add(vCheck) : _done.remove(vCheck)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            vReady ? vText.heightWorkReady : vText.heightWorkNotReady,
            style: vTheme.textTheme.titleMedium?.copyWith(
              color: vReady ? null : vTheme.colorScheme.error,
            ),
          ),
        ],
      ),
    );
  }
}
