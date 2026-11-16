import 'package:flutter/material.dart';

import '../logic/room.dart';
import 'room_plan.dart';

/// Vignette d'une pièce dans les listes : sa forme, ou une icône tant qu'elle n'a pas de murs.
class PlanThumbnail extends StatelessWidget {
  const PlanThumbnail({super.key, required this.room, required this.icon});

  final Room? room;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final vColors = Theme.of(context).colorScheme;
    final vRoom = room;

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: vColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: vRoom == null || vRoom.walls.isEmpty
          ? Icon(icon, color: vColors.primary)
          : RoomPlan(room: vRoom, compact: true),
    );
  }
}

/// Écran vide : une icône et ce qu'il faut faire pour commencer.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final vTheme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: vTheme.colorScheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: vTheme.colorScheme.primary),
            ),
            const SizedBox(height: 16),
            Text(text, textAlign: TextAlign.center, style: vTheme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
