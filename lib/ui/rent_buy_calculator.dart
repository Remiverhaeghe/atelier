import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/rent_or_buy.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'shopping_texts.dart';
import 'theme.dart';

/// Louer ou acheter : ponceuse, perforateur, carrelette…
class RentBuyCalculator extends StatefulWidget {
  const RentBuyCalculator({super.key});

  @override
  State<RentBuyCalculator> createState() => _RentBuyCalculatorState();
}

class _RentBuyCalculatorState extends State<RentBuyCalculator> {
  var _choice = const RentOrBuy();

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vResult = rentOrBuy(_choice);
    void vSet(RentOrBuy pChoice) => setState(() => _choice = pChoice);

    return Scaffold(
      appBar: AppBar(title: Text(vText.rentTitle)),
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
                  Text(vText.resultsTitle, style: vTheme.textTheme.titleMedium),
                  IconLine(Icons.event_repeat, vText.rentCost(formatEuros(vResult.rentCost))),
                  IconLine(
                    Icons.shopping_bag_outlined,
                    vText.buyCost(formatEuros(vResult.buyCost)),
                  ),
                  if (vResult.breakEvenDays != null) ...[
                    IconLine(Icons.balance, vText.rentBreakEven(vResult.breakEvenDays!)),
                    const SizedBox(height: 8),
                    Text(
                      vResult.buy ? vText.rentVerdictBuy : vText.rentVerdictRent,
                      style: vTheme.textTheme.titleMedium!.copyWith(
                        color: vTheme.colorScheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          NumberField<double>(
            label: vText.rentPurchase,
            initial: '',
            parse: parseDecimal,
            onValue: (pValue) => vSet(_choice.copyWith(purchasePrice: pValue)),
          ),
          NumberField<double>(
            label: vText.rentDayRate,
            initial: '',
            parse: parseDecimal,
            onValue: (pValue) => vSet(_choice.copyWith(dayRate: pValue)),
          ),
          NumberField<int>(
            label: vText.rentDays,
            initial: '${_choice.days}',
            parse: parseWhole,
            onValue: (pValue) => vSet(_choice.copyWith(days: pValue)),
          ),
          NumberField<double>(
            label: vText.rentResale,
            initial: '0',
            parse: parseDecimal,
            onValue: (pValue) => vSet(_choice.copyWith(resalePercent: pValue)),
          ),
        ],
      ),
    );
  }
}
