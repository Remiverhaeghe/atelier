import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../support/platform_limits.dart';
import '../logic/maintenance.dart';
import '../logic/noise.dart';
import '../logic/reminders.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import 'reminder_alarm.dart';
import 'theme.dart';

String waitLabel(AppLocalizations pText, WaitKind pKind) => switch (pKind) {
  WaitKind.acclimatise => pText.waitAcclimatise,
  WaitKind.screed => pText.waitScreed,
  WaitKind.filler => pText.waitFiller,
  WaitKind.paintCoat => pText.waitPaintCoat,
  WaitKind.glue => pText.waitGlue,
  WaitKind.noisyWeekend => pText.waitNoisyWeekend,
  WaitKind.maintenance => pText.waitMaintenance,
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
      if (pContext.mounted) {
        final vText = AppLocalizations.of(pContext);
        await aReminderAlarm.schedule(
          vReminder,
          vText.reminderNotifyTitle,
          vReminder.label.isNotEmpty
              ? vReminder.label
              : vReminder.kind == WaitKind.noisyWeekend
              ? vText.waitNoisyWeekendBody
              : waitLabel(vText, vReminder.kind),
        );
      }
    }
  }

  /// Temps restant dit à l'échelle de l'attente : heures, jours, puis mois.
  String _left(AppLocalizations pText, Reminder pReminder) {
    final vDays = daysLeft(pReminder, now);

    return vDays >= monthsFromDays
        ? pText.reminderLeftMonths((vDays / 30).round())
        : vDays > 3
        ? pText.reminderLeftDays(vDays)
        : pText.reminderLeft(hoursLeft(pReminder, now));
  }

  Future<void> _addMaintenance(BuildContext pContext) async {
    final vChoice = await showDialog<({List<MaintenanceTask> tasks, String? roomId})>(
      context: pContext,
      builder: (_) => _MaintenanceDialog(worksite: worksite),
    );
    if (vChoice == null || vChoice.tasks.isEmpty || !pContext.mounted) {
      return;
    }
    final vText = AppLocalizations.of(pContext);
    final vReminders = [
      for (final vTask in vChoice.tasks)
        maintenanceReminder(
          pId: '${now.microsecondsSinceEpoch}-${vTask.name}',
          pTask: vTask,
          pLabel: maintenanceLabel(vText, vTask),
          pFrom: now,
          pRoomId: vChoice.roomId,
        ),
    ];
    onChanged(worksite.copyWith(reminders: [...worksite.reminders, ...vReminders]));
    for (final vReminder in vReminders) {
      await aReminderAlarm.schedule(vReminder, vText.reminderNotifyTitle, vReminder.label);
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
                  tooltip: vText.maintenanceTitle,
                  icon: const Icon(Icons.build_circle_outlined),
                  onPressed: () => _addMaintenance(context),
                ),
                IconButton(
                  tooltip: vText.reminderAdd,
                  icon: const Icon(Icons.alarm_add_outlined),
                  onPressed: () => _add(context),
                ),
              ],
            ),
            // Safari ne programme pas de notification : l'attente reste notée ici
            if (aOnWeb) IconLine(Icons.notifications_off_outlined, vText.remindersWebNote),
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
                  hoursLeft(vReminder, now) == 0 ? vText.reminderReady : _left(vText, vReminder),
                ),
                trailing: IconButton(
                  tooltip: vText.delete,
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    onChanged(
                      worksite.copyWith(
                        reminders: [
                          for (final vOther in worksite.reminders)
                            if (vOther.id != vReminder.id) vOther,
                        ],
                      ),
                    );
                    aReminderAlarm.cancel(vReminder);
                  },
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
    if (_kind == WaitKind.noisyWeekend) {
      Navigator.pop(
        context,
        Reminder(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          kind: _kind,
          label: _label.text.trim(),
          dueAt: weekendNoiseReminder(widget.now),
          roomId: _roomId,
        ),
      );
      return;
    }
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
                  if (vKind != WaitKind.maintenance)
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
            if (_kind == WaitKind.noisyWeekend)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(noisyReminderAt(vText, weekendNoiseReminder(widget.now))),
              )
            else
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

/// Jour et heure du rappel du week-end, dits comme sur un agenda.
String noisyReminderAt(AppLocalizations pText, DateTime pAt) => pText.waitNoisyWeekendAt(
  pAt.weekday == DateTime.saturday ? pText.noiseSaturdayDay : pText.noiseSundayDay,
  pText.noiseClock(pAt.hour, pAt.minute.toString().padLeft(2, '0')),
);

String maintenanceLabel(AppLocalizations pText, MaintenanceTask pTask) => switch (pTask) {
  MaintenanceTask.silicone => pText.maintenanceSilicone,
  MaintenanceTask.grout => pText.maintenanceGrout,
  MaintenanceTask.parquetCare => pText.maintenanceParquet,
  MaintenanceTask.windowSeals => pText.maintenanceWindows,
  MaintenanceTask.woodStain => pText.maintenanceStain,
  MaintenanceTask.ventFilters => pText.maintenanceVent,
};

/// Choix des entretiens à planifier après les travaux, chacun avec son intervalle.
class _MaintenanceDialog extends StatefulWidget {
  const _MaintenanceDialog({required this.worksite});

  final Worksite worksite;

  @override
  State<_MaintenanceDialog> createState() => _MaintenanceDialogState();
}

class _MaintenanceDialogState extends State<_MaintenanceDialog> {
  final _chosen = <MaintenanceTask>{};
  String? _roomId;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(vText.maintenanceTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(vText.maintenanceHelp),
            for (final vTask in MaintenanceTask.values)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _chosen.contains(vTask),
                title: Text(maintenanceLabel(vText, vTask)),
                subtitle: Text(vText.maintenanceEvery(vTask.months)),
                onChanged: (pOn) =>
                    setState(() => pOn ?? false ? _chosen.add(vTask) : _chosen.remove(vTask)),
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
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(
          onPressed: _chosen.isEmpty
              ? null
              : () => Navigator.pop(context, (
                  tasks: MaintenanceTask.values.where(_chosen.contains).toList(),
                  roomId: _roomId,
                )),
          child: Text(vText.save),
        ),
      ],
    );
  }
}
