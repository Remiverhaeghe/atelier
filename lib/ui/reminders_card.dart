import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/reminders.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';

String waitLabel(AppLocalizations pText, WaitKind pKind) => switch (pKind) {
  WaitKind.acclimatise => pText.waitAcclimatise,
  WaitKind.screed => pText.waitScreed,
  WaitKind.filler => pText.waitFiller,
  WaitKind.paintCoat => pText.waitPaintCoat,
  WaitKind.glue => pText.waitGlue,
  WaitKind.custom => pText.waitCustom,
};

/// Attentes en cours sur le chantier : ce qui est prêt, et dans combien d'heures pour le reste.
class RemindersCard extends StatelessWidget {
  const RemindersCard({
    super.key,
    required this.worksite,
    required this.onChanged,
    required this.now,
  });

  final Worksite worksite;
  final ValueChanged<Worksite> onChanged;
  final DateTime now;

  Future<void> _add(BuildContext pContext) async {
    final vReminder = await showDialog<Reminder>(
      context: pContext,
      builder: (_) => _WaitDialog(worksite: worksite, now: now),
    );
    if (vReminder != null) {
      onChanged(worksite.copyWith(reminders: [...worksite.reminders, vReminder]));
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    String vRoom(String? pId) =>
        worksite.rooms.where((pRoom) => pRoom.id == pId).firstOrNull?.name ?? '';

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(vText.remindersTitle, style: vTheme.textTheme.titleMedium)),
                IconButton(
                  tooltip: vText.reminderAdd,
                  icon: const Icon(Icons.alarm_add_outlined),
                  onPressed: () => _add(context),
                ),
              ],
            ),
            if (worksite.reminders.isEmpty) Text(vText.remindersEmpty),
            for (final vReminder in sortedReminders(worksite.reminders))
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  hoursLeft(vReminder, now) == 0 ? Icons.check_circle : Icons.hourglass_top,
                  color: hoursLeft(vReminder, now) == 0 ? vTheme.colorScheme.primary : null,
                ),
                title: Text(
                  [
                    vReminder.label.isEmpty ? waitLabel(vText, vReminder.kind) : vReminder.label,
                    vRoom(vReminder.roomId),
                  ].where((pPart) => pPart.isNotEmpty).join(', '),
                ),
                subtitle: Text(
                  hoursLeft(vReminder, now) == 0
                      ? vText.reminderReady
                      : vText.reminderLeft(hoursLeft(vReminder, now)),
                ),
                trailing: IconButton(
                  tooltip: vText.delete,
                  icon: const Icon(Icons.close),
                  onPressed: () => onChanged(
                    worksite.copyWith(
                      reminders: [
                        for (final vOther in worksite.reminders)
                          if (vOther.id != vReminder.id) vOther,
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _WaitDialog extends StatefulWidget {
  const _WaitDialog({required this.worksite, required this.now});

  final Worksite worksite;
  final DateTime now;

  @override
  State<_WaitDialog> createState() => _WaitDialogState();
}

class _WaitDialogState extends State<_WaitDialog> {
  WaitKind _kind = WaitKind.acclimatise;
  String? _roomId;
  late final _hours = TextEditingController(text: '${_kind.hours}');
  final _label = TextEditingController();

  @override
  void dispose() {
    _hours.dispose();
    _label.dispose();
    super.dispose();
  }

  void _submit() {
    final vHours = parseWhole(_hours.text);
    if (vHours == null || vHours == 0) {
      return;
    }
    Navigator.pop(
      context,
      startWait(
        pId: DateTime.now().microsecondsSinceEpoch.toString(),
        pKind: _kind,
        pNow: widget.now,
        pLabel: _label.text.trim(),
        pRoomId: _roomId,
        pHours: vHours,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(vText.reminderAdd),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<WaitKind>(
              initialValue: _kind,
              items: [
                for (final vKind in WaitKind.values)
                  DropdownMenuItem(value: vKind, child: Text(waitLabel(vText, vKind))),
              ],
              onChanged: (pKind) => setState(() {
                _kind = pKind!;
                if (_kind.hours > 0) {
                  _hours.text = '${_kind.hours}';
                }
              }),
            ),
            if (widget.worksite.rooms.isNotEmpty)
              DropdownButtonFormField<String?>(
                initialValue: _roomId,
                items: [
                  DropdownMenuItem(value: null, child: Text(vText.reminderWholeSite)),
                  for (final vRoom in widget.worksite.rooms)
                    DropdownMenuItem(value: vRoom.id, child: Text(vRoom.name)),
                ],
                onChanged: (pId) => setState(() => _roomId = pId),
              ),
            TextField(
              controller: _hours,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: vText.reminderHours),
            ),
            TextField(
              controller: _label,
              decoration: InputDecoration(labelText: vText.reminderLabel),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(onPressed: _submit, child: Text(vText.save)),
      ],
    );
  }
}
