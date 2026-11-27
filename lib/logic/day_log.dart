/// Journal de chantier quotidien : une ligne par jour avec les heures, ce qui est fait et une photo.
library;

import 'journal.dart';
import 'time_tracking.dart';

/// Ce que la personne a noté à la main pour un jour.
class DayNote {
  const DayNote({required this.day, this.done = '', this.minutes, this.photoPath});

  /// Jour au format AAAA-MM-JJ.
  final String day;
  final String done;

  /// Heures saisies à la main, en minutes ; sinon celles du chronomètre ce jour-là.
  final int? minutes;
  final String? photoPath;

  DayNote copyWith({String? done, int? minutes, String? photoPath, bool clearMinutes = false}) =>
      DayNote(
        day: day,
        done: done ?? this.done,
        minutes: clearMinutes ? null : minutes ?? this.minutes,
        photoPath: photoPath ?? this.photoPath,
      );

  Map<String, Object?> toJson() => {
    'day': day,
    if (done.isNotEmpty) 'done': done,
    if (minutes != null) 'minutes': minutes,
    if (photoPath != null) 'photoPath': photoPath,
  };

  static DayNote fromJson(Map<String, Object?> pJson) => DayNote(
    day: pJson['day']! as String,
    done: (pJson['done'] as String?) ?? '',
    minutes: pJson['minutes'] as int?,
    photoPath: pJson['photoPath'] as String?,
  );
}

/// Une ligne du journal : la note du jour complétée par le chronomètre et le carnet.
typedef DayLine = ({
  String day,
  int minutes,
  bool minutesTyped,
  String done,
  List<String> works,
  String? photoPath,
});

/// Lignes du journal, du jour le plus récent au plus ancien. Un jour existe dès qu'il a une note,
/// du temps chronométré ou un travail inscrit au carnet : rien n'est à ressaisir.
List<DayLine> dayLines({
  required List<DayNote> notes,
  required List<TimeEntry> timeEntries,
  required List<JournalEntry> journal,
}) {
  final vDays = {
    for (final vNote in notes) vNote.day,
    for (final vEntry in timeEntries) vEntry.day,
    for (final vEntry in journal) vEntry.day,
  }.toList()..sort((pA, pB) => pB.compareTo(pA));

  return [
    for (final vDay in vDays)
      (
        day: vDay,
        minutes:
            notes.where((pNote) => pNote.day == vDay).firstOrNull?.minutes ??
            timeEntries
                .where((pEntry) => pEntry.day == vDay)
                .fold<int>(0, (pSum, pEntry) => pSum + pEntry.minutes),
        minutesTyped: notes.where((pNote) => pNote.day == vDay).firstOrNull?.minutes != null,
        done: notes.where((pNote) => pNote.day == vDay).firstOrNull?.done ?? '',
        works: [
          for (final vEntry in journal)
            if (vEntry.day == vDay) vEntry.title,
        ],
        photoPath:
            notes.where((pNote) => pNote.day == vDay).firstOrNull?.photoPath ??
            journal
                .where((pEntry) => pEntry.day == vDay && pEntry.photoPath != null)
                .firstOrNull
                ?.photoPath,
      ),
  ];
}

/// Remplace la note d'un jour, ou l'ajoute ; une note vide est retirée.
List<DayNote> withDayNote(List<DayNote> pNotes, DayNote pNote) {
  final vEmpty = pNote.done.trim().isEmpty && pNote.minutes == null && pNote.photoPath == null;
  final vOthers = [
    for (final vNote in pNotes)
      if (vNote.day != pNote.day) vNote,
  ];

  return vEmpty ? vOthers : [...vOthers, pNote];
}

/// Jours où l'on a travaillé : au moins une minute, ou une note.
int daysWorked(List<DayLine> pLines) => pLines
    .where((pLine) => pLine.minutes > 0 || pLine.done.isNotEmpty || pLine.works.isNotEmpty)
    .length;
