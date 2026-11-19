import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/planning.dart';
import '../logic/room.dart';
import '../logic/time_tracking.dart';
import '../logic/units.dart';
import '../logic/worksite.dart';
import '../state/worksites_controller.dart';
import 'planning_card.dart';
import 'real_cost_card.dart';
import 'theme.dart';

/// Temps passé : chrono par pièce et par étape, et estimation des pièces suivantes.
class TimeScreen extends StatefulWidget {
  const TimeScreen({
    super.key,
    required this.controller,
    required this.worksiteId,
    this.now = DateTime.now,
  });

  final WorksitesController controller;
  final String worksiteId;

  /// Horloge ; remplaçable dans les tests.
  final DateTime Function() now;

  @override
  State<TimeScreen> createState() => _TimeScreenState();
}

class _TimeScreenState extends State<TimeScreen> {
  String? _roomId;
  WorkPhase _phase = WorkPhase.parquet;
  Timer? _tick;

  @override
  void initState() {
    super.initState();
    // Le chrono affiché avance à la minute
    _tick = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }

  WorksitesController get _controller => widget.controller;

  void _start(Worksite pWorksite, String pRoomId) => _controller.updateWorksite(
    pWorksite.copyWith(
      timer: RunningTimer(roomId: pRoomId, phase: _phase, startedAt: widget.now()),
    ),
  );

  void _stop(Worksite pWorksite) => _controller.updateWorksite(
    pWorksite.copyWith(
      timeEntries: [...pWorksite.timeEntries, pWorksite.timer!.stop(widget.now())],
      clearTimer: true,
    ),
  );

  Future<void> _addManual(Worksite pWorksite, Room pRoom, WorkPhase pPhase) async {
    final vMinutes = await _askMinutes(context);
    if (vMinutes != null) {
      _controller.updateWorksite(
        pWorksite.copyWith(
          timeEntries: [
            ...pWorksite.timeEntries,
            TimeEntry(roomId: pRoom.id, phase: pPhase, minutes: vMinutes, day: dayOf(widget.now())),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return ListenableBuilder(
      listenable: _controller,
      builder: (pContext, _) {
        final vWorksite = _controller.worksite(widget.worksiteId);
        if (vWorksite == null) {
          return const Scaffold();
        }
        final vRooms = vWorksite.rooms;
        final vTimer = vWorksite.timer;
        final vRoomId = vRooms.any((pRoom) => pRoom.id == _roomId)
            ? _roomId
            : vRooms.firstOrNull?.id;

        return Scaffold(
          appBar: AppBar(title: Text(vText.timeTitle)),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              if (vRooms.isEmpty)
                Padding(padding: const EdgeInsets.all(20), child: Text(vText.timeEmpty))
              else
                Card(
                  color: vTimer == null ? null : vTheme.colorScheme.primaryContainer,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: vTimer == null
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DropdownButtonFormField<String>(
                                initialValue: vRoomId,
                                decoration: InputDecoration(labelText: vText.timeRoom),
                                items: [
                                  for (final vRoom in vRooms)
                                    DropdownMenuItem(value: vRoom.id, child: Text(vRoom.name)),
                                ],
                                onChanged: (pId) => setState(() => _roomId = pId),
                              ),
                              DropdownButtonFormField<WorkPhase>(
                                initialValue: _phase,
                                decoration: InputDecoration(labelText: vText.timePhase),
                                items: [
                                  for (final vPhase in WorkPhase.values)
                                    DropdownMenuItem(
                                      value: vPhase,
                                      child: Text(phaseLabel(vText, vPhase)),
                                    ),
                                ],
                                onChanged: (pPhase) => setState(() => _phase = pPhase!),
                              ),
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                onPressed: () => _start(vWorksite, vRoomId!),
                                icon: const Icon(Icons.play_arrow),
                                label: Text(vText.timeStart),
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              IconLine(
                                Icons.timer_outlined,
                                vText.timeRunning(
                                  phaseLabel(vText, vTimer.phase),
                                  vRooms
                                          .where((pRoom) => pRoom.id == vTimer.roomId)
                                          .firstOrNull
                                          ?.name ??
                                      '',
                                ),
                              ),
                              BigFigure(formatDuration(vTimer.elapsedMinutes(widget.now()))),
                              FilledButton.icon(
                                onPressed: () => _stop(vWorksite),
                                icon: const Icon(Icons.stop),
                                label: Text(vText.timeStop),
                              ),
                            ],
                          ),
                  ),
                ),
              if (vWorksite.timeEntries.isNotEmpty)
                ListTile(
                  title: Text(
                    vText.timeTotal(formatDuration(spentMinutes(vWorksite.timeEntries))),
                    style: vTheme.textTheme.titleMedium,
                  ),
                ),
              for (final vRoom in vRooms)
                ExpansionTile(
                  leading: const Icon(Icons.meeting_room_outlined),
                  title: Text(vRoom.name),
                  subtitle: Text(
                    formatDuration(spentMinutes(vWorksite.timeEntries, pRoomId: vRoom.id)),
                  ),
                  children: [
                    for (final vPhase in WorkPhase.values)
                      _PhaseRow(
                        label: phaseLabel(vText, vPhase),
                        spent: spentMinutes(
                          vWorksite.timeEntries,
                          pRoomId: vRoom.id,
                          pPhase: vPhase,
                        ),
                        estimate: estimateMinutes(vWorksite.timeEntries, vRooms, vRoom, vPhase),
                        onAdd: () => _addManual(vWorksite, vRoom, vPhase),
                      ),
                  ],
                ),
              if (vWorksite.timeEntries.isNotEmpty)
                RealCostCard(entries: vWorksite.timeEntries, expenses: vWorksite.expenses),
            ],
          ),
        );
      },
    );
  }
}

class _PhaseRow extends StatelessWidget {
  const _PhaseRow({
    required this.label,
    required this.spent,
    required this.estimate,
    required this.onAdd,
  });

  final String label;
  final int spent;
  final int? estimate;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vEstimate = estimate;

    return ListTile(
      dense: true,
      title: Text(label),
      subtitle: spent == 0 && vEstimate != null
          ? Text(vText.timeEstimate(formatDuration(vEstimate)))
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (spent > 0) Text(formatDuration(spent)),
          IconButton(tooltip: vText.timeAdd, icon: const Icon(Icons.more_time), onPressed: onAdd),
        ],
      ),
    );
  }
}

/// Minutes saisies à la main, pour un travail fait sans chrono.
Future<int?> _askMinutes(BuildContext pContext) =>
    showDialog<int>(context: pContext, builder: (_) => const _MinutesDialog());

class _MinutesDialog extends StatefulWidget {
  const _MinutesDialog();

  @override
  State<_MinutesDialog> createState() => _MinutesDialogState();
}

class _MinutesDialogState extends State<_MinutesDialog> {
  final _minutes = TextEditingController();

  @override
  void dispose() {
    _minutes.dispose();
    super.dispose();
  }

  void _submit() {
    final vMinutes = parseWhole(_minutes.text);
    if (vMinutes != null && vMinutes > 0) {
      Navigator.pop(context, vMinutes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(vText.timeAdd),
      content: TextField(
        controller: _minutes,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(labelText: vText.timeMinutes),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(onPressed: _submit, child: Text(vText.save)),
      ],
    );
  }
}
