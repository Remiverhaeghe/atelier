import 'package:atelier/logic/achievements.dart';
import 'package:atelier/logic/goals.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/touch_up.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

/// Chantier d'une pièce de 400 × 300 cm (16 rangées, 8 morceaux de plinthe).
Worksite site(Room pRoom, {DailyGoal? pGoal, int pReached = 0}) =>
    Worksite(id: 'w', name: 'Maison', rooms: [pRoom], goal: pGoal, goalsReached: pReached);

final vDay = DateTime(2026, 11, 16);

void main() {
  const vTouchUps = [
    TouchUp(id: 'a', label: 'Enduit', passes: 3, donePasses: 1),
    TouchUp(id: 'b', label: 'Peinture'),
    TouchUp(id: 'c', label: 'Grille', donePasses: 1),
  ];

  test('objectif : cinq rangées, puis les reprises à finir, daté du jour', () {
    final vGoal = suggestGoal(site(rectangleRoom().copyWith(touchUps: vTouchUps)), vDay);

    expect(vGoal.date, '2026-11-16');
    expect(vGoal.items.map((pItem) => pItem.kind), [
      GoalKind.rows,
      GoalKind.touchUp,
      GoalKind.touchUp,
    ]);
    expect(vGoal.items.first.numbers, [1, 2, 3, 4, 5]);
    expect(vGoal.items[1].touchUpId, 'a');
    expect(vGoal.items[1].targetPasses, 2);
  });

  test('les plinthes viennent une fois le parquet posé', () {
    final vRoom = rectangleRoom().copyWith(
      laidRows: [for (var vRow = 1; vRow <= 16; vRow++) vRow],
      cutPieces: [0],
    );
    final vGoal = suggestGoal(site(vRoom), vDay);

    expect(vGoal.items.single.kind, GoalKind.pieces);
    expect(vGoal.items.single.numbers, [1, 2, 3, 4, 5, 6]);
  });

  test('l\'avancement suit la pièce ; une cible disparue compte comme faite', () {
    final vGoal = suggestGoal(site(rectangleRoom().copyWith(touchUps: vTouchUps)), vDay);
    final vStart = site(rectangleRoom().copyWith(touchUps: vTouchUps), pGoal: vGoal);
    expect(vGoal.doneCount(vStart), 0);
    expect(vGoal.reached(vStart), isFalse);

    final vLater = site(
      rectangleRoom().copyWith(
        laidRows: [1, 2, 3, 4, 5],
        touchUps: [vTouchUps.first.togglePass(1)],
      ),
      pGoal: vGoal,
    );
    expect(vGoal.doneCount(vLater), 3);
    expect(vGoal.reached(vLater), isTrue);
    expect(vGoal.items.first.isDone(null), isTrue);
  });

  test('l\'objectif se relit depuis le JSON avec le chantier', () {
    final vGoal = suggestGoal(site(rectangleRoom().copyWith(touchUps: vTouchUps)), vDay);
    final vBack = Worksite.fromJson(site(rectangleRoom(), pGoal: vGoal, pReached: 3).toJson());

    expect(vBack.goal!.toJson(), vGoal.toJson());
    expect(vBack.goalsReached, 3);
    expect(Worksite.fromJson(site(rectangleRoom()).toJson()).goal, isNull);
    expect(const DailyGoal(date: '2026-11-16', items: []).reached(site(rectangleRoom())), isFalse);
  });

  test('rien à proposer sur un chantier fini', () {
    final vRoom = rectangleRoom().copyWith(
      laidRows: [for (var vRow = 1; vRow <= 16; vRow++) vRow],
      cutPieces: [for (var vIndex = 0; vIndex < 8; vIndex++) vIndex],
    );

    expect(suggestGoal(site(vRoom), vDay).items, isEmpty);
  });

  test('badges : première rangée, pièce finie, plinthes, budget, objectifs', () {
    expect(earnedAchievements(site(rectangleRoom())), isEmpty);
    expect(earnedAchievements(site(rectangleRoom().copyWith(laidRows: [1]))), {
      Achievement.firstRow,
    });

    final vDone = rectangleRoom().copyWith(
      laidRows: [for (var vRow = 1; vRow <= 16; vRow++) vRow],
      cutPieces: [for (var vIndex = 0; vIndex < 8; vIndex++) vIndex],
      touchUps: [
        for (var vIndex = 0; vIndex < 10; vIndex++)
          TouchUp(id: '$vIndex', label: 'R', donePasses: 1),
      ],
    );
    final vGoal = DailyGoal(
      date: '2026-11-16',
      items: [
        GoalItem(kind: GoalKind.rows, roomId: vDone.id, numbers: const [1]),
      ],
    );
    final vSite = site(vDone, pGoal: vGoal, pReached: 4).copyWith(
      prices: const {'parquetPacks': 30, 'underlayRolls': 20, 'baseboardBars': 6, 'cartridges': 8},
    );

    expect(earnedAchievements(vSite), Achievement.values.toSet());
  });
}
