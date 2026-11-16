import 'package:atelier/logic/planning.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/time_tracking.dart';
import 'package:atelier/logic/touch_up.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

final _salon = rectangleRoom();
const _chambre = Room(
  id: 'chambre',
  name: 'Chambre',
  walls: [Wall(lengthMm: 3000), Wall(lengthMm: 3000), Wall(lengthMm: 3000), Wall(lengthMm: 3000)],
);

void main() {
  test('chrono : minutes arrondies, une au moins, jour du départ', () {
    final vTimer = RunningTimer(
      roomId: 'salon',
      phase: WorkPhase.baseboards,
      startedAt: DateTime(2026, 11, 16, 23, 50),
    );

    expect(vTimer.elapsedMinutes(DateTime(2026, 11, 16, 23, 50, 10)), 1);
    final vEntry = vTimer.stop(DateTime(2026, 11, 17, 1, 30, 40));
    expect(vEntry.minutes, 101);
    expect(vEntry.day, '2026-11-16');
    expect(RunningTimer.fromJson(vTimer.toJson()).startedAt, vTimer.startedAt);
  });

  test('quantités par étape : sol, périmètre, peinture, reprises', () {
    expect(phaseQuantity(_salon, WorkPhase.parquet), closeTo(12, 1e-9));
    expect(phaseQuantity(_salon, WorkPhase.baseboards), 14);
    expect(phaseQuantity(_salon, WorkPhase.sealing), 14);
    expect(phaseQuantity(_salon, WorkPhase.ceiling), closeTo(12, 1e-9));
    expect(phaseQuantity(_salon, WorkPhase.walls), greaterThan(30));
    expect(phaseQuantity(_salon, WorkPhase.woodwork), greaterThanOrEqualTo(0));
    final vZone = const Room(id: 'z', name: 'Toit').copyWith(
      touchUps: const [TouchUp(id: 't', label: 'Tuile', passes: 3)],
    );
    expect(phaseQuantity(vZone, WorkPhase.touchUps), 3);
    expect(phaseQuantity(vZone, WorkPhase.parquet), 0);
  });

  test('estimation au rythme des autres pièces', () {
    const vEntries = [
      TimeEntry(roomId: 'salon', phase: WorkPhase.baseboards, minutes: 70, day: '2026-11-10'),
      TimeEntry(roomId: 'salon', phase: WorkPhase.baseboards, minutes: 28, day: '2026-11-11'),
    ];
    final vRooms = [_salon, _chambre];

    expect(spentMinutes(vEntries, pRoomId: 'salon'), 98);
    expect(spentMinutes(vEntries, pPhase: WorkPhase.parquet), 0);
    expect(minutesPerUnit(vEntries, vRooms, WorkPhase.baseboards), closeTo(7, 1e-9));
    // 12 m de plinthes à 7 min le mètre
    expect(estimateMinutes(vEntries, vRooms, _chambre, WorkPhase.baseboards), 84);
    expect(estimateMinutes(vEntries, vRooms, _salon, WorkPhase.baseboards), isNull);
    expect(estimateMinutes(vEntries, vRooms, _chambre, WorkPhase.parquet), isNull);
  });

  test('durées lisibles', () {
    expect(formatDuration(45), '45 min');
    expect(formatDuration(120), '2 h');
    expect(formatDuration(100), '1 h 40');
    expect(formatDuration(65), '1 h 05');
  });

  test('temps et chrono enregistrés avec le chantier', () {
    final vWorksite = Worksite(
      id: 'w',
      name: 'Maison',
      timeEntries: const [
        TimeEntry(roomId: 'salon', phase: WorkPhase.parquet, minutes: 90, day: '2026-11-16'),
      ],
      timer: RunningTimer(
        roomId: 'salon',
        phase: WorkPhase.walls,
        startedAt: DateTime(2026, 11, 16, 9),
      ),
    );
    final vBack = Worksite.fromJson(vWorksite.toJson());

    expect(vBack.timeEntries.single.minutes, 90);
    expect(vBack.timeEntries.single.phase, WorkPhase.parquet);
    expect(vBack.timer!.phase, WorkPhase.walls);
    expect(vBack.copyWith(clearTimer: true).timer, isNull);
    expect(const Worksite(id: 'w', name: 'M').toJson().containsKey('timer'), isFalse);
  });
}
