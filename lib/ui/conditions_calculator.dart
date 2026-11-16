import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/conditions.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String productLabel(AppLocalizations pText, SiteProduct pProduct) => switch (pProduct) {
  SiteProduct.acrylicPaint => pText.productAcrylic,
  SiteProduct.alkydPaint => pText.productAlkyd,
  SiteProduct.floorVarnish => pText.productVarnish,
  SiteProduct.parquetGlue => pText.productParquetGlue,
  SiteProduct.tileAdhesive => pText.productTileAdhesive,
  SiteProduct.filler => pText.productFiller,
  SiteProduct.sealant => pText.productSealant,
  SiteProduct.expandingFoam => pText.productFoam,
};

String issueLabel(AppLocalizations pText, SiteProduct pProduct, ConditionIssue pIssue) =>
    switch (pIssue) {
      ConditionIssue.tooCold => pText.issueCold(formatDecimal(pProduct.minC)),
      ConditionIssue.tooHot => pText.issueHot(formatDecimal(pProduct.maxC)),
      ConditionIssue.tooDry => pText.issueDry(formatDecimal(pProduct.minHumidity)),
      ConditionIssue.tooHumid => pText.issueHumid(formatDecimal(pProduct.maxHumidity)),
      ConditionIssue.condensation => pText.issueDew,
    };

/// Conditions de chantier : ce qu'on peut peindre, coller ou vernir avec la météo du jour.
class ConditionsCalculator extends StatefulWidget {
  const ConditionsCalculator({super.key});

  @override
  State<ConditionsCalculator> createState() => _ConditionsCalculatorState();
}

class _ConditionsCalculatorState extends State<ConditionsCalculator> {
  double _air = 18;
  double _humidity = 55;
  double? _surface;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vColors = vTheme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(vText.conditionsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          NumberField<double>(
            label: vText.conditionsAir,
            initial: formatDecimal(_air),
            parse: parseSignedDecimal,
            onValue: (pValue) => setState(() => _air = pValue),
          ),
          NumberField<double>(
            label: vText.conditionsHumidity,
            initial: formatDecimal(_humidity),
            parse: (pText) => switch (parseDecimal(pText)) {
              final double vValue when vValue <= 100 => vValue,
              _ => null,
            },
            onValue: (pValue) => setState(() => _humidity = pValue),
          ),
          NumberField<double>(
            label: vText.conditionsSurface,
            initial: '',
            parse: parseSignedDecimal,
            onValue: (pValue) => setState(() => _surface = pValue),
          ),
          const SizedBox(height: 12),
          IconLine(
            Icons.water_drop_outlined,
            vText.conditionsDew(formatDecimal(dewPointC(_air, _humidity))),
          ),
          const SizedBox(height: 8),
          for (final vProduct in SiteProduct.values)
            Builder(
              builder: (pContext) {
                final vIssues = checkConditions(
                  vProduct,
                  pAirC: _air,
                  pHumidity: _humidity,
                  pSurfaceC: _surface,
                );

                return Card(
                  child: ListTile(
                    leading: Icon(
                      vIssues.isEmpty ? Icons.check_circle : Icons.do_not_disturb_on_outlined,
                      color: vIssues.isEmpty ? vColors.primary : vColors.error,
                    ),
                    title: Text(productLabel(vText, vProduct)),
                    subtitle: Text(
                      vIssues.isEmpty
                          ? vText.conditionsOk
                          : [
                              for (final vIssue in vIssues) issueLabel(vText, vProduct, vIssue),
                            ].join('\n'),
                    ),
                  ),
                );
              },
            ),
          const SizedBox(height: 8),
          Text(vText.conditionsNote, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
