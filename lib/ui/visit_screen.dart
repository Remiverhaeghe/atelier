import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/touch_up.dart';
import '../logic/visit.dart';
import '../state/worksites_controller.dart';
import 'theme.dart';

String visitCheckLabel(AppLocalizations pText, VisitCheck pCheck) => switch (pCheck) {
  VisitCheck.floorLevel => pText.visitFloor,
  VisitCheck.dampness => pText.visitDamp,
  VisitCheck.cracks => pText.visitCracks,
  VisitCheck.windows => pText.visitWindows,
  VisitCheck.outlets => pText.visitOutlets,
  VisitCheck.lights => pText.visitLights,
  VisitCheck.heating => pText.visitHeating,
  VisitCheck.ventilation => pText.visitVentilation,
  VisitCheck.ceilingStains => pText.visitCeiling,
  VisitCheck.smell => pText.visitSmell,
};

String houseCheckLabel(AppLocalizations pText, HouseCheck pCheck) => switch (pCheck) {
  HouseCheck.electricPanel => pText.visitPanel,
  HouseCheck.waterHeater => pText.visitWaterHeater,
  HouseCheck.roofSpace => pText.visitRoofSpace,
  HouseCheck.gutters => pText.visitGutters,
  HouseCheck.meters => pText.visitMeters,
};

/// Visite pièce par pièce : on coche ce qui est à voir, puis tout passe dans les reprises.
class VisitScreen extends StatefulWidget {
  const VisitScreen({super.key, required this.controller, required this.worksiteId});

  final WorksitesController controller;
  final String worksiteId;

  @override
  State<VisitScreen> createState() => _VisitScreenState();
}

class _VisitScreenState extends State<VisitScreen> {
  final _answers = <String, VisitAnswers>{};
  final _house = <HouseCheck>{};

  Future<void> _save() async {
    final vText = AppLocalizations.of(context);
    final vWorksite = widget.controller.worksite(widget.worksiteId);
    if (vWorksite == null) {
      return;
    }
    await widget.controller.updateWorksite(
      vWorksite.copyWith(
        rooms: [
          for (final vRoom in vWorksite.rooms)
            vRoom.copyWith(
              touchUps: [
                ...vRoom.touchUps,
                for (final vEntry in (_answers[vRoom.id] ?? const <VisitCheck, String>{}).entries)
                  TouchUp(
                    id: '${widget.controller.newId()}-${vEntry.key.name}',
                    label: visitCheckLabel(vText, vEntry.key),
                    note: vEntry.value,
                  ),
              ],
            ),
        ],
      ),
    );
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    final vRooms = widget.controller.worksite(widget.worksiteId)?.rooms ?? const [];
    final vCount = visitSummary(_answers).values.fold(0, (pSum, pCount) => pSum + pCount);

    return Scaffold(
      appBar: AppBar(title: Text(vText.visitTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: vCount == 0 ? null : _save,
        icon: const Icon(Icons.playlist_add_check),
        label: Text(vText.visitSave(vCount)),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
        children: [
          IconLine(Icons.info_outline, vText.visitHelp),
          Card(
            child: ExpansionTile(
              leading: const Icon(Icons.home_outlined),
              title: Text(vText.visitHouse),
              children: [
                for (final vCheck in HouseCheck.values)
                  CheckboxListTile(
                    value: _house.contains(vCheck),
                    title: Text(houseCheckLabel(vText, vCheck)),
                    onChanged: (pOn) =>
                        setState(() => pOn! ? _house.add(vCheck) : _house.remove(vCheck)),
                  ),
              ],
            ),
          ),
          for (final vRoom in vRooms)
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.square_foot),
                title: Text(vRoom.name),
                subtitle: (_answers[vRoom.id] ?? const {}).isEmpty
                    ? null
                    : Text(vText.visitToSee(_answers[vRoom.id]!.length)),
                children: [
                  for (final vCheck in VisitCheck.values) ...[
                    CheckboxListTile(
                      value: _answers[vRoom.id]?.containsKey(vCheck) ?? false,
                      title: Text(visitCheckLabel(vText, vCheck)),
                      onChanged: (pOn) => setState(() {
                        final vRoomAnswers = _answers.putIfAbsent(vRoom.id, () => {});
                        if (pOn!) {
                          vRoomAnswers[vCheck] = '';
                        } else {
                          vRoomAnswers.remove(vCheck);
                        }
                      }),
                    ),
                    if (_answers[vRoom.id]?.containsKey(vCheck) ?? false)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(56, 0, 16, 8),
                        child: TextField(
                          decoration: InputDecoration(labelText: vText.visitNote),
                          onChanged: (pNote) => _answers[vRoom.id]![vCheck] = pNote.trim(),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 8),
          Text(vText.visitHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
