import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import 'drywall_calculator.dart';
import 'garden_calculator.dart';
import 'shelf_calculator.dart';

/// Une entrée du menu des calculs : titre, explication, icône et écran.
typedef Calculator = ({String title, String help, IconData icon, WidgetBuilder builder});

/// Calculs hors des pièces : étagère, et ce que les lots suivants ajoutent.
class CalculatorsScreen extends StatelessWidget {
  const CalculatorsScreen({super.key});

  static List<Calculator> entries(AppLocalizations pText) => [
    (
      title: pText.shelfTitle,
      help: pText.shelfHelp,
      icon: Icons.shelves,
      builder: (_) => const ShelfCalculator(),
    ),
    (
      title: pText.gardenTitle,
      help: pText.gardenHelp,
      icon: Icons.yard_outlined,
      builder: (_) => const GardenCalculator(),
    ),
    (
      title: pText.drywallTitle,
      help: pText.drywallHelp,
      icon: Icons.view_column_outlined,
      builder: (_) => const DrywallCalculator(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.calculatorsTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final vEntry in entries(vText))
            Card(
              child: ListTile(
                leading: Icon(vEntry.icon, color: Theme.of(context).colorScheme.primary),
                title: Text(vEntry.title),
                subtitle: Text(vEntry.help),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute<void>(builder: vEntry.builder)),
              ),
            ),
        ],
      ),
    );
  }
}
