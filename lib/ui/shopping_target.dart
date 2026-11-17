import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/extra_items.dart';
import '../logic/worksite.dart';

/// Chantiers dont un calcul peut remplir la liste de courses, fournis par l'écran des calculs.
class ShoppingTarget extends InheritedWidget {
  const ShoppingTarget({
    super.key,
    required this.worksites,
    required this.add,
    required super.child,
  });

  final List<Worksite> worksites;
  final Future<void> Function(String pWorksiteId, List<ExtraItem> pItems) add;

  static ShoppingTarget? maybeOf(BuildContext pContext) =>
      pContext.dependOnInheritedWidgetOfExactType<ShoppingTarget>();

  @override
  bool updateShouldNotify(ShoppingTarget pOld) => worksites != pOld.worksites;
}

/// Bouton « Ajouter aux courses » d'un calcul ; caché sans chantier où les mettre.
class AddToShoppingButton extends StatelessWidget {
  const AddToShoppingButton({super.key, required this.items});

  final List<ExtraItem> Function() items;

  @override
  Widget build(BuildContext context) {
    final vTarget = ShoppingTarget.maybeOf(context);
    if (vTarget == null || vTarget.worksites.isEmpty) {
      return const SizedBox.shrink();
    }
    final vText = AppLocalizations.of(context);

    return Align(
      alignment: Alignment.centerLeft,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.add_shopping_cart),
        label: Text(vText.addToShopping),
        onPressed: () async {
          final vWorksite = vTarget.worksites.length == 1
              ? vTarget.worksites.single
              : await showDialog<Worksite>(
                  context: context,
                  builder: (pContext) => SimpleDialog(
                    title: Text(vText.addToShoppingWhich),
                    children: [
                      for (final vChoice in vTarget.worksites)
                        SimpleDialogOption(
                          onPressed: () => Navigator.pop(pContext, vChoice),
                          child: Text(vChoice.name),
                        ),
                    ],
                  ),
                );
          if (vWorksite == null) {
            return;
          }
          final vItems = items();
          await vTarget.add(vWorksite.id, vItems);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(vText.addedToShopping(vItems.length, vWorksite.name))),
            );
          }
        },
      ),
    );
  }
}
