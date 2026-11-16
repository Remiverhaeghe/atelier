import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/shopping.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import 'parquet_view.dart';
import 'shopping_texts.dart';

/// Une ligne des courses : case du chariot, stock, prix, magasin et référence.
class ShoppingLineCard extends StatelessWidget {
  const ShoppingLineCard({
    super.key,
    required this.line,
    required this.worksite,
    required this.onChanged,
  });

  final ShoppingLine line;
  final Worksite worksite;
  final ValueChanged<Worksite> onChanged;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vName = line.item.name;
    final vBought = worksite.bought.contains(vName);

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: vBought,
              onChanged: (pValue) {
                final vSet = {...worksite.bought};
                (pValue ?? false) ? vSet.add(vName) : vSet.remove(vName);
                onChanged(worksite.copyWith(bought: vSet.toList()..sort()));
              },
              title: Text(
                itemLabel(vText, line.item),
                style: vTheme.textTheme.titleMedium!.copyWith(
                  decoration: vBought ? TextDecoration.lineThrough : null,
                ),
              ),
              subtitle: Text(
                [
                  lineDetail(vText, line),
                  if (line.inStock > 0) vText.lineInStock(line.inStock),
                ].join('\n'),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                children: [
                  NumberField<int>(
                    key: ValueKey('stock-$vName'),
                    label: vText.stockField,
                    initial: '${worksite.stock[vName] ?? 0}',
                    parse: parseWhole,
                    onValue: (pStock) =>
                        onChanged(worksite.copyWith(stock: {...worksite.stock, vName: pStock})),
                  ),
                  NumberField<double>(
                    key: ValueKey(line.item),
                    label: vText.unitPrice,
                    initial: priceField(line.unitPrice),
                    parse: parseDecimal,
                    onValue: (pPrice) =>
                        onChanged(worksite.copyWith(prices: {...worksite.prices, vName: pPrice})),
                  ),
                  _TextSetting(
                    key: ValueKey('store-$vName'),
                    label: vText.storeField,
                    initial: worksite.stores[vName] ?? '',
                    onValue: (pStore) =>
                        onChanged(worksite.copyWith(stores: {...worksite.stores, vName: pStore})),
                  ),
                  _TextSetting(
                    key: ValueKey('ref-$vName'),
                    label: vText.referenceField,
                    initial: worksite.references[vName] ?? '',
                    onValue: (pReference) => onChanged(
                      worksite.copyWith(references: {...worksite.references, vName: pReference}),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Champ de texte libre, enregistré quand on quitte le champ ou qu'on valide.
class _TextSetting extends StatefulWidget {
  const _TextSetting({super.key, required this.label, required this.initial, required this.onValue});

  final String label;
  final String initial;
  final ValueChanged<String> onValue;

  @override
  State<_TextSetting> createState() => _TextSettingState();
}

class _TextSettingState extends State<_TextSetting> {
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    if (_controller.text.trim() != widget.initial) {
      widget.onValue(_controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: Focus(
      onFocusChange: (pFocused) {
        if (!pFocused) {
          _save();
        }
      },
      child: TextField(
        controller: _controller,
        textCapitalization: TextCapitalization.sentences,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(labelText: widget.label),
      ),
    ),
  );
}
