import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/room.dart';
import 'house_3d.dart';

/// La pièce en 3D, comme une maquette d'architecte : murs, sol et ouvertures, à faire tourner
/// d'un glissement du doigt. Sobre au départ ; « Détails » ajoute les meubles et les structures.
/// Rien tant que le plan n'a pas trois murs.
class Room3dCard extends StatefulWidget {
  const Room3dCard({super.key, required this.room});

  final Room room;

  @override
  State<Room3dCard> createState() => _Room3dCardState();
}

class _Room3dCardState extends State<Room3dCard> {
  bool _simple = true;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    if (widget.room.walls.length < 3) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Text(vText.room3dTitle, style: Theme.of(context).textTheme.titleMedium),
            subtitle: Text(vText.room3dHelp),
          ),
          SizedBox(
            height: 260,
            child: ClipRect(child: House3d(rooms: [widget.room], simple: _simple)),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: true, label: Text(vText.planSimple)),
                ButtonSegment(value: false, label: Text(vText.room3dDetails)),
              ],
              selected: {_simple},
              onSelectionChanged: (pValue) => setState(() => _simple = pValue.first),
            ),
          ),
        ],
      ),
    );
  }
}
