import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/day_log.dart';
import '../logic/time_tracking.dart';
import '../logic/units.dart';
import '../state/worksites_controller.dart';
import '../storage/photo_store.dart';
import 'photos.dart';

/// Journal quotidien : une ligne par jour avec les heures, ce qui est fait et une photo.
class DayLogScreen extends StatefulWidget {
  const DayLogScreen({
    super.key,
    required this.controller,
    required this.worksiteId,
    this.photos,
    this.now = DateTime.now,
  });

  final WorksitesController controller;
  final String worksiteId;

  /// Prise de photo ; remplaçable dans les tests.
  final PhotoTaker? photos;
  final DateTime Function() now;

  @override
  State<DayLogScreen> createState() => _DayLogScreenState();
}

class _DayLogScreenState extends State<DayLogScreen> {
  Future<void> _edit(String pDay) async {
    final vWorksite = widget.controller.worksite(widget.worksiteId);
    if (vWorksite == null) {
      return;
    }
    final vLine = dayLines(
      notes: vWorksite.dayNotes,
      timeEntries: vWorksite.timeEntries,
      journal: vWorksite.journal,
    ).where((pLine) => pLine.day == pDay).firstOrNull;
    final vNote = await showDialog<DayNote>(
      context: context,
      builder: (_) => _DayDialog(
        day: pDay,
        initial: vWorksite.dayNotes.where((pNote) => pNote.day == pDay).firstOrNull,
        suggestedMinutes: vLine?.minutes ?? 0,
        photos: widget.photos ?? takePhoto,
      ),
    );
    if (vNote != null) {
      widget.controller.updateWorksite(
        vWorksite.copyWith(dayNotes: withDayNote(vWorksite.dayNotes, vNote)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (pContext, _) {
        final vWorksite = widget.controller.worksite(widget.worksiteId);
        if (vWorksite == null) {
          return const Scaffold();
        }
        final vLines = dayLines(
          notes: vWorksite.dayNotes,
          timeEntries: vWorksite.timeEntries,
          journal: vWorksite.journal,
        );

        return Scaffold(
          appBar: AppBar(title: Text(vText.dayLogTitle)),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _edit(dayOf(widget.now())),
            icon: const Icon(Icons.edit_calendar_outlined),
            label: Text(vText.dayLogToday),
          ),
          body: vLines.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(vText.dayLogEmpty, textAlign: TextAlign.center),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 96),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Text(
                        vText.dayLogSummary(
                          daysWorked(vLines),
                          formatDuration(
                            vLines.fold<int>(0, (pSum, pLine) => pSum + pLine.minutes),
                          ),
                        ),
                        style: vTheme.textTheme.bodyMedium,
                      ),
                    ),
                    for (final vLine in vLines)
                      ListTile(
                        onTap: () => _edit(vLine.day),
                        leading: vLine.photoPath == null
                            ? const Icon(Icons.event_note_outlined)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image(
                                  image: photoProvider(vLine.photoPath!),
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) =>
                                      const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                        title: Text(
                          '${vLine.day} · ${vLine.minutes > 0 ? formatDuration(vLine.minutes) : vText.dayLogNoHours}',
                        ),
                        subtitle: Text(
                          [if (vLine.done.isNotEmpty) vLine.done, ...vLine.works].join('\n'),
                        ),
                        isThreeLine: vLine.done.isNotEmpty && vLine.works.isNotEmpty,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _DayDialog extends StatefulWidget {
  const _DayDialog({
    required this.day,
    required this.initial,
    required this.suggestedMinutes,
    required this.photos,
  });

  final String day;
  final DayNote? initial;
  final int suggestedMinutes;
  final PhotoTaker photos;

  @override
  State<_DayDialog> createState() => _DayDialogState();
}

class _DayDialogState extends State<_DayDialog> {
  late final _done = TextEditingController(text: widget.initial?.done ?? '');
  late final _hours = TextEditingController(
    text: widget.initial?.minutes == null ? '' : formatDecimal(widget.initial!.minutes! / 60),
  );
  String? _photo;

  @override
  void initState() {
    super.initState();
    _photo = widget.initial?.photoPath;
  }

  @override
  void dispose() {
    _done.dispose();
    _hours.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vHours = parseDecimal(_hours.text);

    return AlertDialog(
      title: Text(vText.dayLogDialog(widget.day)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _done,
              autofocus: true,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(labelText: vText.dayLogDone),
            ),
            TextField(
              controller: _hours,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: vText.dayLogHours,
                helperText: widget.suggestedMinutes > 0
                    ? vText.dayLogTimerHint(formatDuration(widget.suggestedMinutes))
                    : null,
                errorText: _hours.text.trim().isNotEmpty && vHours == null
                    ? vText.invalidNumber
                    : null,
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () async {
                final vPath = await widget.photos('jour-${widget.day}');
                if (vPath != null) {
                  setState(() => _photo = vPath);
                }
              },
              icon: Icon(_photo == null ? Icons.add_a_photo_outlined : Icons.check),
              label: Text(vText.dayLogPhoto),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(vText.cancel)),
        FilledButton(
          onPressed: _hours.text.trim().isNotEmpty && vHours == null
              ? null
              : () => Navigator.pop(
                  context,
                  DayNote(
                    day: widget.day,
                    done: _done.text.trim(),
                    minutes: vHours == null ? null : (vHours * 60).round(),
                    photoPath: _photo,
                  ),
                ),
          child: Text(vText.save),
        ),
      ],
    );
  }
}
