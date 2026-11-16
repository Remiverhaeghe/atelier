import 'package:atelier/logic/geometry.dart';
import 'package:atelier/logic/room.dart';
import 'package:atelier/logic/tracing.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('échelle d\'après une cote connue', () {
    expect(traceScale(const PlanPoint(0, 0), const PlanPoint(200, 0), 4000), 20);
    expect(traceScale(const PlanPoint(5, 5), const PlanPoint(5, 5), 4000), 0);
  });

  test('rectangle touché dans le sens des aiguilles d\'une montre sur l\'écran', () {
    // Écran : y vers le bas ; 200 × 150 points à 20 mm le point, tracé un peu de travers
    final vWalls = wallsFromCorners(const [
      PlanPoint(0, 0),
      PlanPoint(200, 1),
      PlanPoint(200, 150),
      PlanPoint(0, 150),
    ], 20);
    expect(vWalls, hasLength(4));
    expect([for (final vWall in vWalls) vWall.angleToNextDeg], [90, 90, 90, 90]);
    expect(vWalls.map((pWall) => pWall.lengthMm).toSet(), containsAll([3000, 4000]));
    final vRoom = Room(id: 'r', name: 'Décalque', walls: vWalls);
    expect(closureGapMm(vRoom), lessThan(60));
  });

  test('pièce en L : un coin sortant, et le tour dans l\'autre sens donne la même pièce', () {
    const vL = [
      PlanPoint(0, 0),
      PlanPoint(0, 100),
      PlanPoint(100, 100),
      PlanPoint(100, 50),
      PlanPoint(50, 50),
      PlanPoint(50, 0),
    ];
    final vWalls = wallsFromCorners(vL, 10);
    expect(vWalls.where((pWall) => pWall.angleToNextDeg == 270), hasLength(1));
    expect(vWalls.fold(0, (pSum, pWall) => pSum + pWall.lengthMm), 4000);
    final vBack = wallsFromCorners(vL.reversed.toList(), 10);
    expect(vBack.where((pWall) => pWall.angleToNextDeg == 270), hasLength(1));
  });

  test('un angle franchement biais est gardé, moins de trois coins ne fait rien', () {
    final vWalls = wallsFromCorners(const [
      PlanPoint(0, 0),
      PlanPoint(100, 0),
      PlanPoint(70, 80),
    ], 10);
    expect(vWalls.any((pWall) => pWall.angleToNextDeg % 45 != 0), isTrue);
    expect(wallsFromCorners(const [PlanPoint(0, 0), PlanPoint(1, 1)], 10), isEmpty);
    expect(
      wallsFromCorners(const [PlanPoint(0, 0), PlanPoint(1, 1), PlanPoint(2, 0)], 0),
      isEmpty,
    );
  });
}
