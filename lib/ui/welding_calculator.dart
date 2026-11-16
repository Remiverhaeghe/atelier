import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/welding.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String metalLabel(AppLocalizations pText, Metal pMetal) => switch (pMetal) {
  Metal.steel => pText.metalSteel,
  Metal.stainless => pText.metalStainless,
  Metal.aluminium => pText.metalAluminium,
};

(String, String) processTexts(AppLocalizations pText, WeldProcess pProcess) => switch (pProcess) {
  WeldProcess.stick => (pText.processStick, pText.processStickHelp),
  WeldProcess.migMag => (pText.processMigMag, pText.processMigMagHelp),
  WeldProcess.fluxCore => (pText.processFluxCore, pText.processFluxCoreHelp),
  WeldProcess.tig => (pText.processTig, pText.processTigHelp),
};

/// Soudure : métal, épaisseur, lieu ; procédés classés et réglages de départ.
class WeldingCalculator extends StatefulWidget {
  const WeldingCalculator({super.key});

  @override
  State<WeldingCalculator> createState() => _WeldingCalculatorState();
}

class _WeldingCalculatorState extends State<WeldingCalculator> {
  var _metal = Metal.steel;
  var _thickness = 3.0;
  var _outdoor = false;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vProcesses = rankProcesses(_metal, _thickness, pOutdoor: _outdoor);

    return Scaffold(
      appBar: AppBar(title: Text(vText.weldingTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          SegmentedButton<Metal>(
            segments: [
              for (final vMetal in Metal.values)
                ButtonSegment(value: vMetal, label: Text(metalLabel(vText, vMetal))),
            ],
            selected: {_metal},
            onSelectionChanged: (pMetal) => setState(() => _metal = pMetal.first),
          ),
          NumberField<double>(
            label: vText.weldingThickness,
            initial: formatDecimal(_thickness),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _thickness = pValue),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.weldingOutdoor),
            value: _outdoor,
            onChanged: (pValue) => setState(() => _outdoor = pValue),
          ),
          for (var vIndex = 0; vIndex < vProcesses.length; vIndex++)
            _ProcessCard(
              setting: weldSetting(vProcesses[vIndex], _thickness),
              best: vIndex == 0,
              metal: _metal,
            ),
          Card(
            color: vTheme.colorScheme.errorContainer,
            child: ListTile(
              leading: Icon(Icons.warning_amber, color: vTheme.colorScheme.onErrorContainer),
              title: Text(vText.tipWarning),
              subtitle: Text(vText.weldingSafety),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessCard extends StatelessWidget {
  const _ProcessCard({required this.setting, required this.best, required this.metal});

  final WeldSetting setting;
  final bool best;
  final Metal metal;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final (vName, vHelp) = processTexts(vText, setting.process);
    final vDiameter = formatDecimal(setting.diameterMm);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(vName, style: vTheme.textTheme.titleMedium)),
                if (best)
                  Text(
                    vText.recommended,
                    style: vTheme.textTheme.labelMedium!.copyWith(
                      color: vTheme.colorScheme.primary,
                    ),
                  ),
              ],
            ),
            Text(vHelp, style: vTheme.textTheme.bodySmall),
            const SizedBox(height: 6),
            IconLine(Icons.bolt, vText.weldingAmps(setting.minAmps, setting.maxAmps)),
            IconLine(Icons.straighten, switch (setting.process) {
              WeldProcess.stick => vText.weldingElectrode(vDiameter),
              WeldProcess.tig => vText.weldingTungsten(
                vDiameter,
                metal == Metal.aluminium ? vText.currentAc : vText.currentDc,
              ),
              _ => vText.weldingWire(vDiameter),
            }),
          ],
        ),
      ),
    );
  }
}
