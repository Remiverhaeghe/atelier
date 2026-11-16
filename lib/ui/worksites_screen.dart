import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

/// Liste des chantiers ; vide tant que la saisie n'existe pas.
class WorksitesScreen extends StatelessWidget {
  const WorksitesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.worksitesTitle)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(vText.worksitesEmpty, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
