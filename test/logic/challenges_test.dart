import 'package:atelier/logic/app_settings.dart';
import 'package:atelier/logic/challenges.dart';
import 'package:atelier/logic/gestures.dart';
import 'package:atelier/logic/mistakes.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un essai s\'ajoute, réussi ou non', () {
    var vRecords = recordAttempt(const {}, Challenge.tenon, pSuccess: false);
    vRecords = recordAttempt(vRecords, Challenge.tenon, pSuccess: true);
    expect(vRecords[Challenge.tenon], (attempts: 2, successes: 1));
    expect(vRecords[Challenge.squareCut], isNull);
  });

  test('badge : premier défi, moitié, tous', () {
    expect(learningBadge(const {}), LearningBadge.none);
    expect(learningBadge({Challenge.tenon: (attempts: 3, successes: 0)}), LearningBadge.none);
    var vRecords = <Challenge, ChallengeRecord>{};
    final vExpected = [
      LearningBadge.first,
      LearningBadge.first,
      LearningBadge.half,
      LearningBadge.half,
      LearningBadge.half,
      LearningBadge.all,
    ];
    for (final (vIndex, vChallenge) in Challenge.values.indexed) {
      vRecords = recordAttempt(vRecords, vChallenge, pSuccess: true);
      expect(learningBadge(vRecords), vExpected[vIndex], reason: vChallenge.name);
    }
  });

  test('carnet des défis gardé dans les réglages, valeurs abîmées ignorées', () {
    final vSettings = const AppSettings().copyWith(
      challenges: {Challenge.squareCut: (attempts: 4, successes: 2)},
    );
    final vBack = AppSettings.fromJson(vSettings.toJson());
    expect(vBack.challenges, {Challenge.squareCut: (attempts: 4, successes: 2)});
    expect(const AppSettings().toJson().containsKey('challenges'), isFalse);
    expect(
      challengesFromJson({
        'tenon': [1, 1],
        'inconnu': [2, 2],
        'squareCut': 'abîmé',
      }),
      {Challenge.tenon: (attempts: 1, successes: 1)},
    );
    expect(challengesFromJson(null), isEmpty);
  });

  test('chaque défi renvoie à un geste animé', () {
    expect(Challenge.tenon.gesture, Gesture.chisel);
    expect(Challenge.values.map((pItem) => pItem.gesture).toSet(), hasLength(Challenge.values.length));
  });

  test('ratés : le geste à revoir et le moment où l\'on peut reprendre', () {
    expect(mistakesFor(Gesture.caulk), [Mistake.failedSealant]);
    expect(mistakesFor(Gesture.grout), isEmpty);
    expect(repairFrom(Mistake.varnishRun, DateTime(2026, 11, 19, 10)), DateTime(2026, 11, 20, 10));
    expect(repairFrom(Mistake.shortCut, DateTime(2026, 11, 19, 10)), DateTime(2026, 11, 19, 10));
    for (final vMistake in Mistake.values) {
      expect(vMistake.steps, greaterThan(0), reason: vMistake.name);
    }
    expect(Mistake.values.where((pItem) => pItem.outcome == MistakeOutcome.reuse), hasLength(2));
  });
}
