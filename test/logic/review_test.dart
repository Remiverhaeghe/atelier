import 'package:atelier/logic/expenses.dart';
import 'package:atelier/logic/journal.dart';
import 'package:atelier/logic/offcuts.dart';
import 'package:atelier/logic/planning.dart';
import 'package:atelier/logic/review.dart';
import 'package:atelier/logic/shopping.dart';
import 'package:atelier/logic/time_tracking.dart';
import 'package:atelier/logic/touch_up.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('bilan : prévu, dépensé, dépassement, temps, chutes, reprises, carnet', () {
    final vWorksite = Worksite(
      id: 'w',
      name: 'Maison',
      rooms: [
        rectangleRoom().copyWith(
          touchUps: const [
            TouchUp(id: 'a', label: 'Fissure', donePasses: 1),
            TouchUp(id: 'b', label: 'Angle'),
          ],
        ),
      ],
      prices: const {'parquetPacks': 30},
      expenses: const [Expense(id: 'e', label: 'Parquet', amount: 300, date: '2026-11-01')],
      timeEntries: const [
        TimeEntry(roomId: 'salon', phase: WorkPhase.parquet, minutes: 300, day: '2026-11-02'),
        TimeEntry(roomId: 'salon', phase: WorkPhase.baseboards, minutes: 90, day: '2026-11-03'),
      ],
      offcuts: const [Offcut(id: 'o', material: OffcutMaterial.plank, lengthMm: 600)],
      journal: const [JournalEntry(id: 'j', roomId: 'salon', day: '2026-11-03', title: 'Pose')],
    );
    final vPacks = shoppingList(
      vWorksite,
    ).firstWhere((pLine) => pLine.item == ShoppingItem.parquetPacks).quantity;
    final vReview = reviewWorksite(vWorksite);

    expect(vReview.plannedCost, 30.0 * vPacks);
    expect(vReview.plannedIncomplete, isTrue);
    expect(vReview.spentCost, 300);
    expect(vReview.overrunPercent, closeTo((300 - 30.0 * vPacks) / (30.0 * vPacks) * 100, 1e-9));
    expect(vReview.minutes, 390);
    expect(vReview.longestPhase, WorkPhase.parquet);
    expect(vReview.offcutsKept, 1);
    expect((vReview.touchUpsDone, vReview.touchUpsTotal), (1, 2));
    expect(vReview.journalEntries, 1);
  });

  test('sans budget prévu ni temps : pas de dépassement, pas d\'étape la plus longue', () {
    final vReview = reviewWorksite(const Worksite(id: 'w', name: 'Vide'));

    expect(vReview.overrunPercent, isNull);
    expect(vReview.longestPhase, isNull);
  });

  test('les leçons s\'enregistrent', () {
    const vWorksite = Worksite(id: 'w', name: 'M', lessons: ['Acheter les plinthes avant']);

    expect(Worksite.fromJson(vWorksite.toJson()).lessons, ['Acheter les plinthes avant']);
    expect(const Worksite(id: 'w', name: 'M').toJson().containsKey('lessons'), isFalse);
  });
}
