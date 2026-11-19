/// Mode atelier : un chronomètre et une suite d'étapes suivies une à une, en plein écran.
library;

/// Chronomètre qu'on met en pause : le temps déjà compté et l'instant de la dernière reprise.
class Chrono {
  const Chrono({this.counted = Duration.zero, this.since});

  final Duration counted;

  /// Instant du dernier départ ; null à l'arrêt.
  final DateTime? since;

  bool get running => since != null;

  Duration elapsed(DateTime pNow) {
    final vSince = since;
    final rElapsed = vSince == null ? counted : counted + pNow.difference(vSince);

    return rElapsed;
  }

  Chrono start(DateTime pNow) => running ? this : Chrono(counted: counted, since: pNow);

  Chrono pause(DateTime pNow) => running ? Chrono(counted: elapsed(pNow)) : this;
}

/// Temps lisible de loin : « 07:45 », ou « 1:07:45 » au-delà d'une heure.
String formatChrono(Duration pElapsed) {
  final vSeconds = pElapsed.inSeconds < 0 ? 0 : pElapsed.inSeconds;
  final vHours = vSeconds ~/ 3600;
  String vTwo(int pValue) => pValue.toString().padLeft(2, '0');
  final vRest = '${vTwo(vSeconds % 3600 ~/ 60)}:${vTwo(vSeconds % 60)}';
  final rText = vHours > 0 ? '$vHours:$vRest' : vRest;

  return rText;
}

/// Une séance en mode atelier : étapes faites, étape en cours et temps passé sur chacune.
class WorkshopRun {
  const WorkshopRun({
    required this.stepCount,
    this.done = const {},
    this.current = 0,
    this.stepTimes = const {},
    this.chrono = const Chrono(),
    this.stepStart = Duration.zero,
  });

  final int stepCount;
  final Set<int> done;
  final int current;

  /// Temps compté sur chaque étape faite, pour le comparer ensuite au devis d'un artisan.
  final Map<int, Duration> stepTimes;
  final Chrono chrono;

  /// Temps du chronomètre au début de l'étape en cours.
  final Duration stepStart;

  bool get finished => stepCount > 0 && done.length >= stepCount;

  Duration get stepsTotal => stepTimes.values.fold(Duration.zero, (pSum, pTime) => pSum + pTime);

  WorkshopRun _copy({
    Set<int>? done,
    int? current,
    Map<int, Duration>? stepTimes,
    Chrono? chrono,
    Duration? stepStart,
  }) => WorkshopRun(
    stepCount: stepCount,
    done: done ?? this.done,
    current: current ?? this.current,
    stepTimes: stepTimes ?? this.stepTimes,
    chrono: chrono ?? this.chrono,
    stepStart: stepStart ?? this.stepStart,
  );

  WorkshopRun start(DateTime pNow) => _copy(chrono: chrono.start(pNow));

  WorkshopRun pause(DateTime pNow) => _copy(chrono: chrono.pause(pNow));

  /// Remet le chronomètre à zéro ; les étapes cochées restent cochées.
  WorkshopRun resetChrono() => _copy(chrono: const Chrono(), stepStart: Duration.zero);

  /// Change d'étape sans la cocher : le temps repart de là pour la nouvelle.
  WorkshopRun goTo(int pIndex, DateTime pNow) {
    if (pIndex < 0 || pIndex >= stepCount) {
      return this;
    }

    return _copy(current: pIndex, stepStart: chrono.elapsed(pNow));
  }

  /// Coche l'étape en cours, garde son temps et passe à la suivante pas encore faite.
  WorkshopRun markDone(DateTime pNow) {
    if (stepCount == 0) {
      return this;
    }
    final vElapsed = chrono.elapsed(pNow);
    final vDone = {...done, current};
    final vTimes = {
      ...stepTimes,
      current: (stepTimes[current] ?? Duration.zero) + vElapsed - stepStart,
    };
    var vNext = current;
    for (var vShift = 1; vShift <= stepCount; vShift++) {
      final vIndex = (current + vShift) % stepCount;
      if (!vDone.contains(vIndex)) {
        vNext = vIndex;
        break;
      }
    }
    final rRun = _copy(done: vDone, current: vNext, stepTimes: vTimes, stepStart: vElapsed);

    return rRun;
  }

  /// Décoche une étape, pour la refaire.
  WorkshopRun reopen(int pIndex) => _copy(done: {...done}..remove(pIndex));
}
