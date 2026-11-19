import 'package:atelier/logic/gestures.dart';
import 'package:atelier/logic/glossary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('pas de gants avec un outil qui tourne', () {
    for (final vGesture in Gesture.values.where((pGesture) => pGesture.rotating)) {
      expect(vGesture.gear, isNot(contains(Gear.gloves)), reason: vGesture.name);
    }
    expect(Gesture.drill.rotating, isTrue);
    expect(Gesture.saw.rotating, isFalse);
  });

  test('poncer fait de la poussière et du bruit', () {
    expect(Gesture.sand.gear, containsAll([Gear.mask, Gear.earmuffs]));
  });

  test('visser renvoie à l\'avant-trou et à la fraisure', () {
    expect(Gesture.screw.terms, [Term.pilotHole, Term.countersink]);
    expect(Gesture.caulk.terms, isEmpty);
  });

  test('la passe part de 0, va au bout à mi-temps et revient', () {
    expect(stroke(0), 0);
    expect(stroke(0.25), closeTo(0.5, 1e-9));
    expect(stroke(0.5), 1);
    expect(stroke(0.75), closeTo(0.5, 1e-9));
    // Une passe après l'autre : même position à chaque tour
    expect(stroke(2.5), 1);
    expect(stroke(3.25), closeTo(0.5, 1e-9));
  });
}
