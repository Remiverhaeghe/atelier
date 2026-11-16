import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/search.dart';
import '../logic/tips.dart';
import '../state/worksites_controller.dart';
import 'calculators_screen.dart';
import 'journal_screen.dart';
import 'room_screen.dart';
import 'tips_screen.dart';
import 'worksite_screen.dart';

/// Ce qu'ouvre un résultat : son icône et l'écran à pousser.
typedef SearchTarget = ({IconData icon, Widget Function() screen});

/// Tout ce qu'on peut chercher : chantiers, pièces, carnet, calculs et fiches.
List<SearchItem<SearchTarget>> searchCatalog(
  AppLocalizations pText,
  WorksitesController pController,
) {
  final vRooms = [for (final vWorksite in pController.worksites) ...vWorksite.rooms];

  return [
    for (final vWorksite in pController.worksites) ...[
      (
        title: vWorksite.name,
        detail: pText.searchWorksite,
        key: (
          icon: Icons.home_work_outlined,
          screen: () => WorksiteScreen(controller: pController, worksiteId: vWorksite.id),
        ),
      ),
      for (final vRoom in vWorksite.rooms)
        (
          title: vRoom.name,
          detail: vWorksite.name,
          key: (
            icon: Icons.square_foot,
            screen: () => RoomScreen(
              controller: pController,
              worksiteId: vWorksite.id,
              roomId: vRoom.id,
            ),
          ),
        ),
      for (final vEntry in vWorksite.journal)
        (
          title: vEntry.title,
          detail: '${vEntry.product} ${vEntry.reference} ${vEntry.note} ${vEntry.day}',
          key: (
            icon: Icons.menu_book_outlined,
            screen: () => JournalScreen(controller: pController, worksiteId: vWorksite.id),
          ),
        ),
    ],
    for (final vCalculator in CalculatorsScreen.entries(pText, vRooms))
      (
        title: vCalculator.title,
        detail: vCalculator.help,
        key: (icon: vCalculator.icon, screen: () => Builder(builder: vCalculator.builder)),
      ),
    for (final vTip in Tip.values)
      (
        title: tipTexts(pText, vTip).title,
        detail: tipTexts(pText, vTip).steps,
        key: (icon: Icons.tips_and_updates_outlined, screen: () => TipScreen(tip: vTip)),
      ),
  ];
}

/// Recherche dans toute l'appli.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.controller});

  final WorksitesController controller;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  var _query = '';

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vHits = searchItems(_query, searchCatalog(vText, widget.controller));

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          autofocus: true,
          decoration: InputDecoration(hintText: vText.searchHint, border: InputBorder.none),
          onChanged: (pValue) => setState(() => _query = pValue),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          if (_query.trim().isNotEmpty && vHits.isEmpty)
            Padding(padding: const EdgeInsets.all(16), child: Text(vText.searchNothing)),
          for (final vHit in vHits)
            ListTile(
              leading: Icon(vHit.key.icon),
              title: Text(vHit.title),
              subtitle: Text(
                vHit.detail.trim(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (_) => vHit.key.screen()),
              ),
            ),
        ],
      ),
    );
  }
}
