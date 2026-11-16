import 'package:atelier/logic/undo_history.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final vStart = DateTime(2026, 11, 17, 10);
  DateTime vAt(int pSeconds) => vStart.add(Duration(seconds: pSeconds));

  test('annuler puis refaire, dans l\'ordre', () {
    final vHistory = UndoHistory<String>();
    vHistory.record('a', vAt(0));
    vHistory.record('b', vAt(5));
    expect(vHistory.undo('c'), 'b');
    expect(vHistory.undo('b'), 'a');
    expect(vHistory.undo('a'), isNull);
    expect(vHistory.redo('a'), 'b');
    expect(vHistory.redo('b'), 'c');
    expect(vHistory.redo('c'), isNull);
  });

  test('une saisie rapide compte pour une seule étape, un nouveau changement efface le futur', () {
    final vHistory = UndoHistory<String>();
    vHistory.record('3', vAt(0));
    vHistory.record('30', vAt(0));
    vHistory.record('300', vAt(0));
    expect(vHistory.undo('3000'), '3');
    expect(vHistory.canUndo, isFalse);
    expect(vHistory.canRedo, isTrue);
    vHistory.record('3', vAt(10));
    expect(vHistory.canRedo, isFalse);
  });

  test('les états les plus anciens sont oubliés au-delà de la limite', () {
    final vHistory = UndoHistory<int>(limit: 2);
    for (var vStep = 0; vStep < 4; vStep++) {
      vHistory.record(vStep, vAt(vStep * 10));
    }
    expect(vHistory.undo(4), 3);
    expect(vHistory.undo(3), 2);
    expect(vHistory.undo(2), isNull);
  });
}
