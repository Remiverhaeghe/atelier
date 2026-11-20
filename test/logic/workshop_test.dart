import 'package:atelier/logic/workshop.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final vStart = DateTime(2026, 11, 19, 9);
  DateTime vAt(int pSeconds) => vStart.add(Duration(seconds: pSeconds));

  test('le chronomètre compte, se met en pause et reprend', () {
    var vChrono = const Chrono().start(vStart);
    expect(vChrono.running, isTrue);
    expect(vChrono.start(vAt(5)).since, vStart);
    expect(vChrono.elapsed(vAt(30)), const Duration(seconds: 30));
    vChrono = vChrono.pause(vAt(30));
    expect(vChrono.running, isFalse);
    expect(vChrono.pause(vAt(90)).counted, const Duration(seconds: 30));
    expect(vChrono.elapsed(vAt(500)), const Duration(seconds: 30));
    vChrono = vChrono.start(vAt(100));
    expect(vChrono.elapsed(vAt(110)), const Duration(seconds: 40));
  });

  test('le temps s\'affiche en minutes, puis en heures', () {
    expect(formatChrono(const Duration(seconds: 7)), '00:07');
    expect(formatChrono(const Duration(minutes: 7, seconds: 45)), '07:45');
    expect(formatChrono(const Duration(hours: 1, minutes: 7, seconds: 45)), '1:07:45');
    expect(formatChrono(const Duration(seconds: -3)), '00:00');
  });

  test('cocher une étape garde son temps et passe à la suivante', () {
    var vRun = const WorkshopRun(stepCount: 3).start(vStart);
    vRun = vRun.markDone(vAt(60));
    expect(vRun.done, {0});
    expect(vRun.current, 1);
    expect(vRun.stepTimes[0], const Duration(minutes: 1));
    vRun = vRun.goTo(2, vAt(90));
    expect(vRun.current, 2);
    vRun = vRun.markDone(vAt(150));
    expect(vRun.stepTimes[2], const Duration(minutes: 1));
    // Retour à l'étape sautée
    expect(vRun.current, 1);
    vRun = vRun.markDone(vAt(180));
    expect(vRun.finished, isTrue);
    expect(vRun.stepsTotal, const Duration(seconds: 150));
    expect(vRun.current, 1);
  });

  test('changer d\'étape hors des bornes ne fait rien', () {
    const vRun = WorkshopRun(stepCount: 2);
    expect(vRun.goTo(5, vStart).current, 0);
    expect(vRun.goTo(-1, vStart).current, 0);
    expect(const WorkshopRun(stepCount: 0).markDone(vStart).done, isEmpty);
    expect(const WorkshopRun(stepCount: 0).finished, isFalse);
  });

  test('décocher une étape et remettre le chronomètre à zéro', () {
    var vRun = const WorkshopRun(stepCount: 2).start(vStart).markDone(vAt(20));
    vRun = vRun.reopen(0);
    expect(vRun.done, isEmpty);
    vRun = vRun.pause(vAt(40)).resetChrono();
    expect(vRun.chrono.elapsed(vAt(100)), Duration.zero);
    expect(vRun.stepStart, Duration.zero);
    expect(vRun.stepTimes[0], const Duration(seconds: 20));
  });
}
