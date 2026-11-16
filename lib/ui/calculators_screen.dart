import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import 'deck_calculator.dart';
import 'drywall_calculator.dart';
import 'electricity_calculator.dart';
import 'garden_calculator.dart';
import 'plumbing_calculator.dart';
import 'shelf_calculator.dart';
import 'wardrobe_calculator.dart';
import 'welding_calculator.dart';

/// Une entrée du menu des calculs : titre, explication, icône et écran.
typedef Calculator = ({String title, String help, IconData icon, WidgetBuilder builder});

/// Calculs hors des pièces, en grille de tuiles.
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
      title: pText.wardrobeTitle,
      help: pText.wardrobeHelp,
      icon: Icons.door_sliding_outlined,
      builder: (_) => const WardrobeCalculator(),
    ),
    (
      title: pText.gardenTitle,
      help: pText.gardenHelp,
      icon: Icons.yard_outlined,
      builder: (_) => const GardenCalculator(),
    ),
    (
      title: pText.deckTitle,
      help: pText.deckHelp,
      icon: Icons.deck_outlined,
      builder: (_) => const DeckCalculator(),
    ),
    (
      title: pText.drywallTitle,
      help: pText.drywallHelp,
      icon: Icons.view_column_outlined,
      builder: (_) => const DrywallCalculator(),
    ),
    (
      title: pText.elecTitle,
      help: pText.elecHelp,
      icon: Icons.electrical_services,
      builder: (_) => const ElectricityCalculator(),
    ),
    (
      title: pText.plumbingTitle,
      help: pText.plumbingHelp,
      icon: Icons.plumbing,
      builder: (_) => const PlumbingCalculator(),
    ),
    (
      title: pText.weldingTitle,
      help: pText.weldingHelp,
      icon: Icons.local_fire_department_outlined,
      builder: (_) => const WeldingCalculator(),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.calculatorsTitle)),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(12),
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        childAspectRatio: 0.85,
        children: [
          for (final vEntry in entries(vText))
            Card(
              margin: const EdgeInsets.all(4),
              child: InkWell(
                onTap: () =>
                    Navigator.push(context, MaterialPageRoute<void>(builder: vEntry.builder)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: vTheme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          vEntry.icon,
                          size: 30,
                          color: vTheme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const Spacer(),
                      Text(vEntry.title, style: vTheme.textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        vEntry.help,
                        style: vTheme.textTheme.bodySmall,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
