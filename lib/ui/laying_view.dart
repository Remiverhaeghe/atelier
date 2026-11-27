import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/laying_plan.dart';
import '../logic/parquet.dart';
import '../logic/room.dart';
import '../logic/units.dart';
import 'laying_preview.dart';
import 'theme.dart';
import 'plan_unit.dart';
import 'room_measure_picker.dart' show lengthText, unitName;

/// Plan de pose du parquet, rangée par rangée, à cocher au fur et à mesure.
class LayingView extends StatelessWidget {
  const LayingView({super.key, required this.room, required this.onChanged});

  final Room room;
  final ValueChanged<Room> onChanged;

  void _toggle(int pNumber, bool pLaid) {
    final vRows = {...room.laidRows};
    pLaid ? vRows.add(pNumber) : vRows.remove(pNumber);
    onChanged(room.copyWith(laidRows: vRows.toList()..sort()));
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vUnit = PlanUnit.of(context);
    final vTheme = Theme.of(context);
    final vPlan = planLaying(room, room.parquet);
    if (vPlan == null && room.parquet.type == ParquetType.herringbone && room.walls.length >= 3) {
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          HerringbonePreview(room: room),
          const SizedBox(height: 12),
          IconLine(Icons.info_outline, vText.herringboneLaying),
        ],
      );
    }
    if (vPlan == null) {
      return Center(
        child: Padding(padding: const EdgeInsets.all(24), child: Text(vText.layingUnavailable)),
      );
    }
    final vProblems = vPlan.problemRows;
    final vDone = vPlan.rows.where((pRow) => room.laidRows.contains(pRow.number)).length;

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        ListTile(
          title: Text(
            vText.layingSummary(vPlan.rows.length, vPlan.planksUsed),
            style: vTheme.textTheme.titleMedium,
          ),
          subtitle: Text(vText.layingHelp),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: LinearProgressIndicator(value: vPlan.rows.isEmpty ? 0 : vDone / vPlan.rows.length),
        ),
        ListTile(dense: true, title: Text(vText.layingProgress(vDone, vPlan.rows.length))),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: LayingPreview(plan: vPlan, laidRows: room.laidRows),
        ),
        if (vProblems.isNotEmpty)
          ListTile(
            leading: Icon(Icons.warning_amber, color: vTheme.colorScheme.error),
            title: Text(vText.layingProblems(vProblems.length)),
          ),
        for (final vRow in vPlan.rows)
          CheckboxListTile(
            value: room.laidRows.contains(vRow.number),
            onChanged: (pValue) => _toggle(vRow.number, pValue ?? false),
            title: Text(vText.layingRowTitle(vRow.number, lengthText(vText, vRow.widthMm, vUnit))),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final vRun in vRow.runs) ...[
                  Text(
                    vText.layingPieces(
                      '${vRun.pieces.map((pPiece) => lengthInUnit(pPiece, vUnit)).join(' + ')} '
                      '${unitName(vText, vUnit)}',
                    ),
                  ),
                  if (vRun.startsWithOffcut) Text(vText.layingOffcutStart),
                  if (!vRun.jointsOk)
                    Text(vText.layingProblem, style: TextStyle(color: vTheme.colorScheme.error)),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
