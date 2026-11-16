import 'package:atelier/logic/expenses.dart';
import 'package:atelier/logic/merge.dart';
import 'package:atelier/logic/planning.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/time_tracking.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('ce qui manque est ajouté, ce qui est pareil gardé une fois, le mien gagne', () {
    final vSalon = rectangleRoom();
    final vMine = Worksite(
      id: 'w',
      name: 'Maison',
      rooms: [vSalon],
      prices: const {'Colle': 12},
      ownedTools: const ['Scie'],
      expenses: const [Expense(id: 'e1', label: 'Parquet', amount: 600, date: '2026-10-01')],
      timeEntries: const [
        TimeEntry(roomId: 'salon', phase: WorkPhase.parquet, minutes: 60, day: '2026-10-01'),
      ],
    );
    final vTheirs = Worksite(
      id: 'w',
      name: 'Maison',
      rooms: [
        vSalon,
        const Room(id: 'cuisine', name: 'Cuisine'),
      ],
      prices: const {'Colle': 15, 'Joint': 8},
      ownedTools: const ['Scie', 'Ponceuse'],
      expenses: const [
        Expense(id: 'e1', label: 'Parquet', amount: 600, date: '2026-10-01'),
        Expense(id: 'e2', label: 'Plinthes', amount: 80, date: '2026-10-04'),
      ],
      timeEntries: const [
        TimeEntry(roomId: 'salon', phase: WorkPhase.parquet, minutes: 60, day: '2026-10-01'),
        TimeEntry(roomId: 'salon', phase: WorkPhase.parquet, minutes: 30, day: '2026-10-02'),
      ],
    );

    final vResult = mergeWorksite(vMine, vTheirs, 'Léa');
    expect((vResult.added, vResult.conflicts), (1, 0));
    final vMerged = vResult.worksite;
    expect([for (final vRoom in vMerged.rooms) vRoom.id], ['salon', 'cuisine']);
    expect(vMerged.prices, {'Colle': 12, 'Joint': 8});
    expect(vMerged.ownedTools, ['Scie', 'Ponceuse']);
    expect(vMerged.expenses, hasLength(2));
    expect(vMerged.timeEntries, hasLength(2));
  });

  test('une pièce changée des deux côtés est gardée en double', () {
    final vMine = Worksite(id: 'w', name: 'Maison', rooms: [rectangleRoom()]);
    final vTheirs = Worksite(
      id: 'w',
      name: 'Maison',
      rooms: [rectangleRoom().copyWith(ceilingHeightMm: 2600)],
    );
    final vResult = mergeWorksite(vMine, vTheirs, 'Léa');
    expect(vResult.conflicts, 1);
    expect(vResult.worksite.rooms.last.id, 'salon-Léa');
    expect(vResult.worksite.rooms.last.name, 'Salon (Léa)');
    expect(vResult.worksite.rooms.last.ceilingHeightMm, 2600);
  });
}
