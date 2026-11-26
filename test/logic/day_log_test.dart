import 'package:atelier/logic/day_log.dart';
import 'package:atelier/logic/journal.dart';
import 'package:atelier/logic/planning.dart';
import 'package:atelier/logic/review.dart';
import 'package:atelier/logic/time_tracking.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vTime = [
    TimeEntry(roomId: 'salon', phase: WorkPhase.walls, minutes: 90, day: '2026-11-10'),
    TimeEntry(roomId: 'salon', phase: WorkPhase.walls, minutes: 30, day: '2026-11-10'),
    TimeEntry(roomId: 'salon', phase: WorkPhase.walls, minutes: 45, day: '2026-11-12'),
  ];
  const vJournal = [
    JournalEntry(
      id: 'j1',
      roomId: 'salon',
      day: '2026-11-12',
      title: 'Sous-couche',
      photoPath: '/p/j1.jpg',
    ),
  ];

  test('les heures chronométrées et le carnet remplissent le journal sans ressaisie', () {
    final vLines = dayLines(notes: const [], timeEntries: vTime, journal: vJournal);

    expect(vLines.map((pLine) => pLine.day), ['2026-11-12', '2026-11-10']);
    expect(vLines.first.minutes, 45);
    expect(vLines.first.works, ['Sous-couche']);
    expect(vLines.first.photoPath, '/p/j1.jpg');
    expect(vLines.last.minutes, 120);
  });

  test('les heures saisies à la main passent avant le chronomètre', () {
    final vLines = dayLines(
      notes: const [DayNote(day: '2026-11-10', done: 'Ponçage', minutes: 200, photoPath: '/p/a.jpg')],
      timeEntries: vTime,
      journal: vJournal,
    );
    final vDay = vLines.last;

    expect((vDay.minutes, vDay.minutesTyped, vDay.done, vDay.photoPath), (200, true, 'Ponçage', '/p/a.jpg'));
  });

  test('une note remplace celle du même jour ; une note vide est retirée', () {
    final vFirst = withDayNote(const [], const DayNote(day: '2026-11-10', done: 'A'));
    final vSecond = withDayNote(vFirst, const DayNote(day: '2026-11-10', done: 'B'));
    final vRemoved = withDayNote(vSecond, const DayNote(day: '2026-11-10'));

    expect(vSecond.single.done, 'B');
    expect(vRemoved, isEmpty);
  });

  test('la note se range et se relit avec le chantier', () {
    final vSite = Worksite(
      id: 'w',
      name: 'Maison',
      dayNotes: const [DayNote(day: '2026-11-10', done: 'Ponçage', minutes: 90, photoPath: '/p.jpg')],
    );
    final vBack = Worksite.fromJson(vSite.toJson());

    expect(vBack.dayNotes.single.toJson(), vSite.dayNotes.single.toJson());
    expect(Worksite.fromJson(const Worksite(id: 'w', name: 'M').toJson()).dayNotes, isEmpty);
  });

  test('le bilan compte les jours de chantier', () {
    final vSite = Worksite(
      id: 'w',
      name: 'Maison',
      timeEntries: vTime,
      journal: vJournal,
      dayNotes: const [DayNote(day: '2026-11-20', done: 'Rangement')],
    );

    expect(reviewWorksite(vSite).daysWorked, 3);
    expect(daysWorked(const []), 0);
  });
}
