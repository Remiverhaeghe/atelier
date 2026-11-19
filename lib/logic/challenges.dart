/// Mode apprentissage : petits défis guidés, reliés aux gestes animés, avec un badge discret.
library;

import 'gestures.dart';

/// Défis, du plus simple au plus exigeant. [gesture] : le geste animé à revoir avant.
enum Challenge {
  squareCut(Gesture.saw),
  straightHole(Gesture.drill),
  sealantBead(Gesture.caulk),
  mitreCut(Gesture.mitre),
  levelLine(Gesture.laser),
  tenon(Gesture.chisel);

  const Challenge(this.gesture);

  final Gesture gesture;
}

/// Essais faits et réussis pour un défi.
typedef ChallengeRecord = ({int attempts, int successes});

const noAttempt = (attempts: 0, successes: 0);

/// Carnet des défis après un essai de [pChallenge], réussi ou non.
Map<Challenge, ChallengeRecord> recordAttempt(
  Map<Challenge, ChallengeRecord> pRecords,
  Challenge pChallenge, {
  required bool pSuccess,
}) {
  final vOld = pRecords[pChallenge] ?? noAttempt;
  final rRecords = {
    ...pRecords,
    pChallenge: (attempts: vOld.attempts + 1, successes: vOld.successes + (pSuccess ? 1 : 0)),
  };

  return rRecords;
}

/// Badge discret : rien, un premier défi réussi, la moitié, puis tous.
enum LearningBadge { none, first, half, all }

LearningBadge learningBadge(Map<Challenge, ChallengeRecord> pRecords) {
  final vDone = Challenge.values.where((pItem) => (pRecords[pItem]?.successes ?? 0) > 0).length;
  final rBadge = vDone == Challenge.values.length
      ? LearningBadge.all
      : vDone * 2 >= Challenge.values.length
      ? LearningBadge.half
      : vDone > 0
      ? LearningBadge.first
      : LearningBadge.none;

  return rBadge;
}

/// Carnet des défis en JSON : nom du défi, puis essais et réussites.
Map<String, Object?> challengesToJson(Map<Challenge, ChallengeRecord> pRecords) => {
  for (final MapEntry(key: vChallenge, value: vRecord) in pRecords.entries)
    vChallenge.name: [vRecord.attempts, vRecord.successes],
};

/// Carnet relu ; un défi inconnu ou une valeur abîmée est ignoré.
Map<Challenge, ChallengeRecord> challengesFromJson(Object? pJson) {
  final vByName = Challenge.values.asNameMap();
  final rRecords = <Challenge, ChallengeRecord>{
    if (pJson is Map<String, Object?>)
      for (final MapEntry(key: vName, value: vValue) in pJson.entries)
        if (vByName[vName] case final vChallenge?)
          if (vValue case [final int vAttempts, final int vSuccesses])
            vChallenge: (attempts: vAttempts, successes: vSuccesses),
  };

  return rRecords;
}
