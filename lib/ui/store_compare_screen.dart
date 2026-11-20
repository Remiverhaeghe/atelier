import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/shopping.dart';
import '../logic/store_compare.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import '../state/worksites_controller.dart';
import 'dialogs.dart';
import 'parquet_view.dart';
import 'shopping_texts.dart';
import 'theme.dart';

/// Comparatif de magasins : prix relevés par magasin, total de chacun, meilleur panier mixte.
class StoreCompareScreen extends StatelessWidget {
  const StoreCompareScreen({super.key, required this.controller, required this.worksiteId});

  final WorksitesController controller;
  final String worksiteId;

  void _setPrice(Worksite pWorksite, String pStore, String pItem, double pPrice) {
    final vPrices = {
      for (final vEntry in pWorksite.storePrices.entries) vEntry.key: {...vEntry.value},
    };
    vPrices.putIfAbsent(pStore, () => {})[pItem] = pPrice;
    controller.updateWorksite(pWorksite.copyWith(storePrices: vPrices));
  }

  Future<void> _addStore(BuildContext pContext, Worksite pWorksite) async {
    final vText = AppLocalizations.of(pContext);
    final vName = await askName(pContext, pTitle: vText.storeAdd, pLabel: vText.storeName);
    if (vName != null && !pWorksite.storePrices.containsKey(vName)) {
      controller.updateWorksite(
        pWorksite.copyWith(storePrices: {...pWorksite.storePrices, vName: const {}}),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return ListenableBuilder(
      listenable: controller,
      builder: (pContext, _) {
        final vWorksite = controller.worksite(worksiteId);
        if (vWorksite == null) {
          return const Scaffold();
        }
        final vLines = shoppingList(vWorksite).where((pLine) => pLine.quantity > 0).toList();
        final vTotals = storeTotals(vLines, vWorksite.storePrices);
        final vBasket = bestBasket(vLines, vWorksite.storePrices);
        final vCheapest = vTotals.where((pTotal) => pTotal.missing == 0).firstOrNull;

        return Scaffold(
          appBar: AppBar(title: Text(vText.storeCompareTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addStore(pContext, vWorksite),
            icon: const Icon(Icons.add_business_outlined),
            label: Text(vText.storeAdd),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              if (vWorksite.storePrices.isEmpty)
                Padding(padding: const EdgeInsets.all(20), child: Text(vText.storeCompareEmpty)),
              if (vWorksite.storePrices.length >= 2 && vBasket.storeOf.isNotEmpty)
                Card(
                  color: vTheme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vText.storeBasket, style: vTheme.textTheme.titleMedium),
                        BigFigure('${formatEuros(vBasket.total)} €'),
                        EstimateNote(vText.estimateFromPrices),
                        if (vCheapest != null && vBasket.missing == 0)
                          IconLine(
                            Icons.savings_outlined,
                            vText.storeSaving(
                              formatEuros(vCheapest.total - vBasket.total),
                              vCheapest.store,
                            ),
                          ),
                        for (final vLine in vLines)
                          if (vBasket.storeOf.containsKey(vLine.item.name))
                            Text(
                              '${itemLabel(vText, vLine.item)} : ${vBasket.storeOf[vLine.item.name]}',
                            ),
                      ],
                    ),
                  ),
                ),
              for (final vTotal in vTotals)
                ExpansionTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: Text(vTotal.store),
                  subtitle: Text(
                    vTotal.missing == 0
                        ? vText.storeTotal(formatEuros(vTotal.total))
                        : vText.storeTotalMissing(formatEuros(vTotal.total), vTotal.missing),
                  ),
                  childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  children: [
                    for (final vLine in vLines)
                      NumberField<double>(
                        key: ValueKey('${vTotal.store}-${vLine.item.name}'),
                        label: '${itemLabel(vText, vLine.item)} (× ${vLine.quantity})',
                        initial: switch (vWorksite.storePrices[vTotal.store]?[vLine.item.name]) {
                          final double vPrice => formatDecimal(vPrice),
                          null => '',
                        },
                        parse: parseDecimal,
                        onValue: (pPrice) =>
                            _setPrice(vWorksite, vTotal.store, vLine.item.name, pPrice),
                      ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}
