import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/delivery.dart';
import '../logic/shopping.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import 'parquet_view.dart';
import 'shopping_texts.dart';
import 'theme.dart';

/// À la livraison : ce qui est arrivé, ligne par ligne, contre la commande.
class DeliveryCard extends StatelessWidget {
  const DeliveryCard({
    super.key,
    required this.worksite,
    required this.lines,
    required this.onChanged,
  });

  final Worksite worksite;
  final List<ShoppingLine> lines;
  final ValueChanged<Worksite> onChanged;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vCheck = checkDelivery(lines, worksite.received);
    if (vCheck.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: ExpansionTile(
        leading: Icon(
          deliveryDone(vCheck) ? Icons.check_circle : Icons.local_shipping_outlined,
          color: deliveryDone(vCheck) ? vTheme.colorScheme.primary : null,
        ),
        title: Text(vText.deliveryTitle),
        subtitle: Text(deliveryDone(vCheck) ? vText.deliveryDone : vText.deliveryHelp),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          for (final vLine in vCheck) ...[
            IconLine(
              switch (vLine.state) {
                DeliveryState.complete => Icons.check,
                DeliveryState.missing => Icons.remove_circle_outline,
                DeliveryState.extra => Icons.add_circle_outline,
                DeliveryState.unchecked => Icons.radio_button_unchecked,
              },
              switch (vLine.state) {
                DeliveryState.missing => vText.deliveryMissing(
                  itemLabel(vText, vLine.item),
                  vLine.ordered - vLine.received!,
                ),
                DeliveryState.extra => vText.deliveryExtra(
                  itemLabel(vText, vLine.item),
                  vLine.received! - vLine.ordered,
                ),
                _ => vText.deliveryOrdered(itemLabel(vText, vLine.item), vLine.ordered),
              },
            ),
            NumberField<int>(
              key: ValueKey('received-${vLine.item.name}'),
              label: vText.deliveryReceived,
              initial: vLine.received == null ? '' : '${vLine.received}',
              parse: parseWhole,
              onValue: (pCount) => onChanged(
                worksite.copyWith(received: {...worksite.received, vLine.item.name: pCount}),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(vText.deliveryHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
