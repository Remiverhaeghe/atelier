import 'package:atelier/logic/video_moments.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('heure d\'un moment en minutes et secondes', () {
    expect(formatVideoTime(const Duration(seconds: 5)), '0:05');
    expect(formatVideoTime(const Duration(minutes: 1, seconds: 5, milliseconds: 900)), '1:05');
  });

  test('chaque moment devient une reprise, dans l\'ordre de la vidéo', () {
    final vTouchUps = touchUpsFromMoments(
      [
        (at: const Duration(seconds: 40), label: 'Plinthe décollée', photoPath: 'b.jpg', marks: const []),
        (
          at: const Duration(seconds: 12),
          label: 'Trace de rouleau',
          photoPath: 'a.jpg',
          marks: const [(x: 0.4, y: 0.6)],
        ),
      ],
      (pTime) => 'vu à $pTime',
      (pIndex) => 'r$pIndex',
    );

    expect(vTouchUps.map((pTouchUp) => pTouchUp.label), ['Trace de rouleau', 'Plinthe décollée']);
    expect(vTouchUps.first.id, 'r0');
    expect(vTouchUps.first.note, 'vu à 0:12');
    expect(vTouchUps.first.photoPath, 'a.jpg');
    expect(vTouchUps.first.photoMarks, [(x: 0.4, y: 0.6)]);
  });
}
