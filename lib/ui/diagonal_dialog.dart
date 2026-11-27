import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/diagonal.dart';
import '../logic/fixtures.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'dialogs.dart';
import 'quick_walls_screen.dart' show wallUnits;
import 'room_measure_picker.dart' show unitName;
import 'theme.dart';

/// Contrôle par la diagonale ; renvoie la pièce aux angles corrigés, ou null.
Future<Room?> checkDiagonal(BuildContext pContext, Room pRoom) => showDialog<Room>(
  context: pContext,
  builder: (_) => _DiagonalDialog(room: pRoom),
);

class _DiagonalDialog extends StatefulWidget {
  const _DiagonalDialog({required this.room});

  final Room room;

  @override
  State<_DiagonalDialog> createState() => _DiagonalDialogState();
}

class _DiagonalDialogState extends State<_DiagonalDialog> {
  final _measured = TextEditingController();
  var _unit = FieldUnit.cm;

  @override
  void dispose() {
    _measured.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vColors = Theme.of(context).colorScheme;
    final vRoom = widget.room;
    final vPlan = planDiagonalMm(vRoom)!;
    final vMeasured = parseInUnit(_measured.text, _unit);
    final vGap = vMeasured == null || vMeasured == 0 ? null : diagonalGapMm(vRoom, vMeasured)!;
    final vOk = vGap != null && vGap.abs() <= diagonalToleranceMm;
    final vAngles = vGap == null || vOk ? null : anglesFromDiagonal(vRoom, vMeasured!);

    return AlertDialog(
      title: Text(vText.diagonalTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconLine(AtelierIcons.length, vText.diagonalHint(cornerName(0), cornerName(2))),
            for (final vPair in oppositeMismatches(vRoom))
              IconLine(
                AtelierIcons.warning,
                vText.diagonalOpposite(vPair.first, vPair.second, formatCentimetres(vPair.gapMm)),
                color: vColors.error,
              ),
            TextField(
              controller: _measured,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: vText.diagonalMeasured,
                suffixText: unitName(vText, _unit),
                helperText: vText.diagonalPlan(
                  '${lengthInUnit(vPlan.round(), _unit)} ${unitName(vText, _unit)}',
                ),
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<FieldUnit>(
              segments: [
                for (final vUnit in wallUnits)
                  ButtonSegment(value: vUnit, label: Text(unitName(vText, vUnit))),
              ],
              selected: {_unit},
              onSelectionChanged: (pUnit) => setState(() {
                final vValue = parseInUnit(_measured.text, _unit);
                _unit = pUnit.single;
                if (vValue != null) {
                  _measured.text = lengthInUnit(vValue, _unit);
                }
              }),
            ),
            if (vGap != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: IconLine(
                  vOk ? Icons.check_circle_outline : AtelierIcons.warning,
                  vOk ? vText.diagonalOk : vText.diagonalGap(formatCentimetres(vGap.abs().round())),
                  color: vOk ? vColors.primary : vColors.error,
                ),
              ),
            if (vAngles != null) Text(vText.diagonalAngles(vAngles.map(formatAngle).join(' · '))),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.close)),
        if (vAngles != null)
          FilledButton(
            onPressed: () => Navigator.pop(
              context,
              vRoom.copyWith(
                walls: [
                  for (var vIndex = 0; vIndex < 4; vIndex++)
                    vRoom.walls[vIndex].copyWith(angleToNextDeg: vAngles[vIndex]),
                ],
              ),
            ),
            child: Text(vText.diagonalFix),
          ),
      ],
    );
  }
}
