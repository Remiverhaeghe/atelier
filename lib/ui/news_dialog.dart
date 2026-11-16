import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';

/// Nouveautés de la dernière mise à jour, en quelques lignes.
Future<void> showNews(BuildContext pContext) {
  final vText = AppLocalizations.of(pContext);

  return showDialog<void>(
    context: pContext,
    builder: (pDialog) => AlertDialog(
      icon: const Icon(Icons.auto_awesome_outlined),
      title: Text(vText.newsTitle),
      content: SingleChildScrollView(child: Text(vText.newsLines)),
      actions: [FilledButton(onPressed: () => Navigator.pop(pDialog), child: Text(vText.newsOk))],
    ),
  );
}
