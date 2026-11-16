import 'package:atelier/logic/goals.dart';
import 'package:atelier/logic/home_summary.dart';
import 'package:atelier/logic/reminders.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final vNow = DateTime(2026, 11, 17, 9);

  test('sans chantier, pas de résumé', () {
    expect(homeSummary(const [], vNow), isNull);
  });

  test('le chantier qui a un objectif aujourd\'hui, et la plus proche des attentes', () {
    final vSummary = homeSummary([
      const Worksite(id: 'a', name: 'Garage'),
      Worksite(
        id: 'b',
        name: 'Maison',
        goal: const DailyGoal(
          date: '2026-11-17',
          items: [GoalItem(kind: GoalKind.pieces, roomId: 'salon', numbers: [1, 2])],
        ),
        reminders: [
          startWait(pId: 'r1', pKind: WaitKind.screed, pNow: vNow),
          startWait(pId: 'r2', pKind: WaitKind.paintCoat, pNow: vNow),
          startWait(pId: 'r3', pKind: WaitKind.glue, pNow: vNow.subtract(const Duration(days: 2))),
        ],
      ),
    ], vNow)!;
    expect(vSummary.worksite, 'Maison');
    // La pièce n'existe plus : l'élément compte comme fait
    expect((vSummary.done, vSummary.total), (1, 1));
    expect(vSummary.nextWaitHours, 6);
  });

  test('objectif d\'un autre jour ignoré, premier chantier par défaut', () {
    final vSummary = homeSummary([
      const Worksite(
        id: 'a',
        name: 'Garage',
        goal: DailyGoal(date: '2026-11-16', items: []),
      ),
    ], vNow)!;
    expect((vSummary.worksite, vSummary.total, vSummary.nextWaitHours), ('Garage', 0, null));
  });
}
