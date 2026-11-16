import 'package:atelier/logic/progress.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/rooms.dart';

void main() {
  test('une pièce sans murs n\'a rien à faire', () {
    final vProgress = roomProgress(const Room(id: 'r', name: 'R'));

    expect(vProgress.total, 0);
    expect(vProgress.ratio, 0);
  });

  test('rangées posées et morceaux coupés comptent chacun pour une tâche', () {
    // 4000 × 3000 : 16 rangées de 19,3 cm et 8 morceaux de plinthe
    final vRoom = rectangleRoom().copyWith(laidRows: [1, 2], cutPieces: [0, 1, 2, 99]);
    final vProgress = roomProgress(vRoom);

    expect(vProgress.total, 16 + 8);
    expect(vProgress.done, 2 + 3);
    expect(vProgress.ratio, closeTo(5 / 24, 1e-9));
  });
}
