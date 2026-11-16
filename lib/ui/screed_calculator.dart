import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/screed.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String coatingLabel(AppLocalizations pText, Coating pCoating) => switch (pCoating) {
  Coating.selfLeveling => pText.coatingLeveling,
  Coating.skimCoat => pText.coatingSkim,
  Coating.filler => pText.coatingFiller,
};

String coveringLabel(AppLocalizations pText, Covering pCovering) => switch (pCovering) {
  Covering.tiles => pText.coveringTiles,
  Covering.floating => pText.coveringFloating,
  Covering.gluedParquet => pText.coveringGlued,
  Covering.vinyl => pText.coveringVinyl,
};

/// Enduit et ragréage : sacs, primaire, couches et attente avant la suite.
class ScreedCalculator extends StatefulWidget {
  const ScreedCalculator({super.key});

  @override
  State<ScreedCalculator> createState() => _ScreedCalculatorState();
}

class _ScreedCalculatorState extends State<ScreedCalculator> {
  Coating _coating = Coating.selfLeveling;
  Covering _covering = Covering.floating;
  double _area = 12;
  double _min = 2;
  double _max = 8;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vThickness = averageThickness(_min, _max);
    final vPlan = planCoating(
      pCoating: _coating,
      pAreaM2: _area,
      pThicknessMm: vThickness,
      pCovering: _covering,
    );
    final vLevel = _coating == Coating.selfLeveling;
    final vDays = vPlan.dryingHours ~/ 24;

    return Scaffold(
      appBar: AppBar(title: Text(vText.screedTitle)),
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
                  BigFigure(vText.screedBags(vPlan.bags, _coating.bagKg)),
                  Text(vText.screedKg(formatDecimal(vPlan.kg), formatDecimal(vThickness))),
                  if (vPlan.primerCans > 0)
                    IconLine(Icons.format_color_fill, vText.screedPrimer(vPlan.primerCans)),
                  if (!vLevel) IconLine(Icons.layers_outlined, vText.screedPasses(vPlan.passes)),
                  IconLine(Icons.hourglass_bottom, vText.screedWait(vDays)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Coating>(
            initialValue: _coating,
            decoration: InputDecoration(labelText: vText.screedProduct),
            items: [
              for (final vCoating in Coating.values)
                DropdownMenuItem(value: vCoating, child: Text(coatingLabel(vText, vCoating))),
            ],
            onChanged: (pCoating) => setState(() => _coating = pCoating!),
          ),
          if (vLevel) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<Covering>(
              initialValue: _covering,
              decoration: InputDecoration(labelText: vText.screedCovering),
              items: [
                for (final vCovering in Covering.values)
                  DropdownMenuItem(value: vCovering, child: Text(coveringLabel(vText, vCovering))),
              ],
              onChanged: (pCovering) => setState(() => _covering = pCovering!),
            ),
          ],
          NumberField<double>(
            label: vText.screedArea,
            initial: formatDecimal(_area),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _area = pValue),
          ),
          NumberField<double>(
            label: vText.screedMin,
            initial: formatDecimal(_min),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _min = pValue),
          ),
          NumberField<double>(
            label: vText.screedMax,
            initial: formatDecimal(_max),
            parse: parseDecimal,
            onValue: (pValue) => setState(() => _max = pValue),
          ),
          const SizedBox(height: 12),
          IconLine(Icons.straighten, vLevel ? vText.screedHowTo : vText.skimHowTo),
          Text(vText.conditionsNote, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
