import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/room.dart';

/// « Reprendre d'une pièce » : choix d'une pièce dont le calcul reprend les surfaces.
class RoomSourcePicker extends StatelessWidget {
  const RoomSourcePicker({super.key, required this.rooms, required this.value, required this.onChanged});

  final List<Room> rooms;
  final String? value;
  final ValueChanged<Room?> onChanged;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vUsable = [
      for (final vRoom in rooms)
        if (vRoom.walls.length >= 3) vRoom,
    ];
    if (vUsable.isEmpty) {
      return const SizedBox.shrink();
    }

    return DropdownButtonFormField<String?>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: vText.roomSource,
        prefixIcon: const Icon(Icons.square_foot),
      ),
      items: [
        DropdownMenuItem(value: null, child: Text(vText.roomSourceNone)),
        for (final vRoom in vUsable) DropdownMenuItem(value: vRoom.id, child: Text(vRoom.name)),
      ],
      onChanged: (pId) => onChanged(vUsable.where((pRoom) => pRoom.id == pId).firstOrNull),
    );
  }
}
