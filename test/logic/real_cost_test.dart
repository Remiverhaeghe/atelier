import 'package:atelier/logic/planning.dart';
import 'package:atelier/logic/real_cost.dart';
import 'package:atelier/logic/time_tracking.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vEntries = [
    TimeEntry(roomId: 'a', phase: WorkPhase.parquet, minutes: 240, day: '2026-11-10'),
    TimeEntry(roomId: 'b', phase: WorkPhase.parquet, minutes: 120, day: '2026-11-11'),
    TimeEntry(roomId: 'a', phase: WorkPhase.walls, minutes: 180, day: '2026-11-12'),
  ];

  test('temps par étape face à la main-d\'œuvre d\'un artisan deux fois plus rapide', () {
    final vCost = realCost(vEntries, 45);
    expect([for (final vPhase in vCost.phases) vPhase.phase], [WorkPhase.walls, WorkPhase.parquet]);
    final vParquet = vCost.phases.last;
    expect(vParquet.minutes, 360);
    expect(vParquet.proHours, 3);
    expect(vParquet.proEuros, 135);
    expect(vCost.minutes, 540);
    expect(vCost.proHours, 4.5);
    expect(vCost.proEuros, closeTo(202.5, 1e-9));
    // Chaque heure passée a évité 22,50 € de main-d'œuvre
    expect(vCost.savedPerHour, closeTo(22.5, 1e-9));
  });

  test('vitesse de l\'artisan réglable, nulle ramenée à la même vitesse', () {
    expect(realCost(vEntries, 40, pSpeedFactor: 1).proEuros, 360);
    expect(realCost(vEntries, 40, pSpeedFactor: 0).proEuros, 360);
  });

  test('sans temps noté, rien à comparer', () {
    final vCost = realCost(const [], 50);
    expect(vCost.phases, isEmpty);
    expect(vCost.savedPerHour, 0);
  });
}
