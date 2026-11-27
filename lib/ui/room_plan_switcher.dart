import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/room.dart';
import 'room_plan.dart';

/// Plan de la pièce en deux niveaux : « Simple » (murs, ouvertures et cotes) au départ, « Complet »
/// avec le quadrillage, les éléments fixes, les meubles et les lettres des coins.
class RoomPlanSwitcher extends StatefulWidget {
  const RoomPlanSwitcher({super.key, required this.room});

  final Room room;

  @override
  State<RoomPlanSwitcher> createState() => _RoomPlanSwitcherState();
}

class _RoomPlanSwitcherState extends State<RoomPlanSwitcher> {
  bool _simple = true;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Column(
      children: [
        RoomPlan(room: widget.room, simple: _simple),
        const SizedBox(height: 8),
        SegmentedButton<bool>(
          segments: [
            ButtonSegment(value: true, label: Text(vText.planSimple)),
            ButtonSegment(value: false, label: Text(vText.planFull)),
          ],
          selected: {_simple},
          onSelectionChanged: (pValue) => setState(() => _simple = pValue.first),
        ),
      ],
    );
  }
}
