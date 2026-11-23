import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/room.dart';
import 'house_3d.dart';

/// La pièce en 3D, comme une maquette d'architecte : murs, sol et ouvertures, à faire tourner
/// d'un glissement du doigt. Rien tant que le plan n'a pas trois murs.
class Room3dCard extends StatelessWidget {
  const Room3dCard({super.key, required this.room});

  final Room room;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    if (room.walls.length < 3) {
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
            child: ClipRect(child: House3d(rooms: [room])),
          ),
        ],
      ),
    );
  }
}
