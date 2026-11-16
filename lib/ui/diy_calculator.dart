import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/diy_or_pro.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'shopping_texts.dart';
import 'theme.dart';

/// Faire soi-même ou faire faire : devis, matériel, outils, temps et aides.
class DiyCalculator extends StatefulWidget {
  const DiyCalculator({super.key});

  @override
  State<DiyCalculator> createState() => _DiyCalculatorState();
}

class _DiyCalculatorState extends State<DiyCalculator> {
  double _quote = 2400;
  double _material = 900;
  double _tools = 100;
  double _hours = 14;
  bool _beginner = true;
  bool _aidsNeedPro = false;
  double _aid = 0;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vVerdict = compareDiy((
      quoteEuros: _quote,
      materialEuros: _material,
      toolsEuros: _tools,
      hours: _hours,
      beginner: _beginner,
      aidsNeedPro: _aidsNeedPro,
      aidEuros: _aid,
    ));
    final vWorth = vVerdict.savingEuros > 0;
    NumberField<double> vField(String pLabel, double pInitial, ValueChanged<double> pSet) =>
        NumberField<double>(
          label: pLabel,
          initial: formatDecimal(pInitial),
          parse: parseDecimal,
          onValue: (pValue) => setState(() => pSet(pValue)),
        );

    return Scaffold(
      appBar: AppBar(title: Text(vText.diyTitle)),
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
                    vWorth
                        ? vText.diySaving(formatEuros(vVerdict.savingEuros))
                        : vText.diyNoSaving,
                  ),
                  IconLine(Icons.handyman_outlined, vText.diyCost(formatEuros(vVerdict.diyEuros))),
                  IconLine(Icons.engineering_outlined, vText.diyPro(formatEuros(vVerdict.proEuros))),
                  IconLine(Icons.timer_outlined, vText.diyHours(formatDecimal(vVerdict.realHours))),
                  if (vWorth)
                    IconLine(
                      Icons.euro,
                      vText.diyPerHour(formatEuros(vVerdict.savingPerHour)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          vField(vText.diyQuote, _quote, (pValue) => _quote = pValue),
          vField(vText.diyMaterial, _material, (pValue) => _material = pValue),
          vField(vText.diyTools, _tools, (pValue) => _tools = pValue),
          vField(vText.diyTime, _hours, (pValue) => _hours = pValue),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.diyBeginner),
            subtitle: Text(vText.diyBeginnerHelp),
            value: _beginner,
            onChanged: (pValue) => setState(() => _beginner = pValue),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(vText.diyAids),
            subtitle: Text(vText.diyAidsHelp),
            value: _aidsNeedPro,
            onChanged: (pValue) => setState(() => _aidsNeedPro = pValue),
          ),
          if (_aidsNeedPro) vField(vText.diyAidAmount, _aid, (pValue) => _aid = pValue),
          const SizedBox(height: 12),
          Text(vText.diyHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
