import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/worksite.dart';

/// Matériel ajouté aux courses depuis un calcul, à cocher en magasin ou à retirer.
class ExtraItemsCard extends StatelessWidget {
  const ExtraItemsCard({super.key, required this.worksite, required this.onChanged});

  final Worksite worksite;
  final ValueChanged<Worksite> onChanged;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: const Icon(Icons.calculate_outlined),
            title: Text(vText.extrasTitle),
            subtitle: Text(vText.extrasHelp),
          ),
          for (final (vIndex, vItem) in worksite.extras.indexed)
            ListTile(
              dense: true,
              title: Text(vItem.name),
              leading: Text('× ${vItem.quantity}'),
              trailing: IconButton(
                tooltip: vText.extrasRemove,
                icon: const Icon(Icons.delete_outline),
                onPressed: () =>
                    onChanged(worksite.copyWith(extras: [...worksite.extras]..removeAt(vIndex))),
              ),
            ),
        ],
      ),
    );
  }
}
