import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/wood_species.dart';
import 'theme.dart';

String speciesLabel(AppLocalizations pText, WoodSpecies pSpecies) => switch (pSpecies) {
  WoodSpecies.spruce => pText.speciesSpruce,
  WoodSpecies.pine => pText.speciesPine,
  WoodSpecies.douglas => pText.speciesDouglas,
  WoodSpecies.larch => pText.speciesLarch,
  WoodSpecies.oak => pText.speciesOak,
  WoodSpecies.ash => pText.speciesAsh,
  WoodSpecies.beech => pText.speciesBeech,
  WoodSpecies.tropical => pText.speciesTropical,
};

String speciesTip(AppLocalizations pText, WoodSpecies pSpecies) => switch (pSpecies) {
  WoodSpecies.spruce => pText.speciesSpruceTip,
  WoodSpecies.pine => pText.speciesPineTip,
  WoodSpecies.douglas => pText.speciesDouglasTip,
  WoodSpecies.larch => pText.speciesLarchTip,
  WoodSpecies.oak => pText.speciesOakTip,
  WoodSpecies.ash => pText.speciesAshTip,
  WoodSpecies.beech => pText.speciesBeechTip,
  WoodSpecies.tropical => pText.speciesTropicalTip,
};

String useClassLabel(AppLocalizations pText, UseClass pUse) => switch (pUse) {
  UseClass.indoorDry => pText.useClassIndoorDry,
  UseClass.indoorDamp => pText.useClassIndoorDamp,
  UseClass.outdoor => pText.useClassOutdoor,
  UseClass.groundContact => pText.useClassGround,
};

/// Quel bois prendre pour cet usage : l'essence choisie convient-elle, lesquelles conviennent.
class WoodSpeciesCard extends StatefulWidget {
  const WoodSpeciesCard({super.key, required this.useClass});

  final UseClass useClass;

  @override
  State<WoodSpeciesCard> createState() => _WoodSpeciesCardState();
}

class _WoodSpeciesCardState extends State<WoodSpeciesCard> {
  late var _species = speciesFor(widget.useClass).firstOrNull ?? WoodSpecies.douglas;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vFits = _species.fits(widget.useClass);
    final vGood = [
      for (final vSpecies in speciesFor(widget.useClass)) speciesLabel(vText, vSpecies),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(vText.speciesTitle, style: vTheme.textTheme.titleMedium),
            Text(useClassLabel(vText, widget.useClass), style: vTheme.textTheme.bodySmall),
            const SizedBox(height: 8),
            DropdownButtonFormField<WoodSpecies>(
              initialValue: _species,
              decoration: InputDecoration(labelText: vText.speciesChoice),
              items: [
                for (final vSpecies in WoodSpecies.values)
                  DropdownMenuItem(value: vSpecies, child: Text(speciesLabel(vText, vSpecies))),
              ],
              onChanged: (pSpecies) => setState(() => _species = pSpecies!),
            ),
            const SizedBox(height: 8),
            IconLine(
              vFits ? Icons.check_circle_outline : Icons.warning_amber,
              vFits ? vText.speciesFits : vText.speciesNotFit(widget.useClass.level),
              color: vFits ? null : vTheme.colorScheme.error,
            ),
            IconLine(Icons.forest_outlined, speciesTip(vText, _species)),
            IconLine(
              Icons.euro,
              vText.speciesTraits('€' * _species.price, _species.ease, _species.densityKgM3),
            ),
            if (vGood.isNotEmpty)
              Text(vText.speciesGood(vGood.join(', ')), style: vTheme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
