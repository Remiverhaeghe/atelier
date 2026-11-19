/// Bruit et voisinage : horaires habituels des travaux bruyants chez soi.
///
/// Ce sont les horaires du modèle d'arrêté repris par beaucoup de préfectures et de communes.
/// Ils varient d'une commune à l'autre : à confirmer auprès de la mairie.
library;

/// Plage horaire, en minutes depuis minuit.
typedef NoiseWindow = ({int fromMinute, int toMinute});

/// Genre de journée, qui fixe les horaires.
enum NoiseDay { weekday, saturday, sundayOrHoliday }

/// Plages où les travaux bruyants sont habituellement tolérés, selon le genre de journée.
List<NoiseWindow> noiseWindows(NoiseDay pDay) => switch (pDay) {
  NoiseDay.weekday => const [
    (fromMinute: 8 * 60 + 30, toMinute: 12 * 60),
    (fromMinute: 14 * 60 + 30, toMinute: 19 * 60 + 30),
  ],
  NoiseDay.saturday => const [
    (fromMinute: 9 * 60, toMinute: 12 * 60),
    (fromMinute: 15 * 60, toMinute: 19 * 60),
  ],
  NoiseDay.sundayOrHoliday => const [(fromMinute: 10 * 60, toMinute: 12 * 60)],
};

/// Dimanche de Pâques de l'année [pYear] (calendrier grégorien, méthode de Meeus).
DateTime easterSunday(int pYear) {
  final vA = pYear % 19;
  final vB = pYear ~/ 100;
  final vC = pYear % 100;
  final vD = vB ~/ 4;
  final vE = vB % 4;
  final vF = (vB + 8) ~/ 25;
  final vG = (vB - vF + 1) ~/ 3;
  final vH = (19 * vA + vB - vD - vG + 15) % 30;
  final vI = vC ~/ 4;
  final vK = vC % 4;
  final vL = (32 + 2 * vE + 2 * vI - vH - vK) % 7;
  final vM = (vA + 11 * vH + 22 * vL) ~/ 451;
  final vMonth = (vH + vL - 7 * vM + 114) ~/ 31;
  final vDay = (vH + vL - 7 * vM + 114) % 31 + 1;
  final rEaster = DateTime(pYear, vMonth, vDay);

  return rEaster;
}

/// Jours fériés nationaux en France métropolitaine (sans les jours propres à l'Alsace-Moselle
/// ni aux outre-mer).
Set<DateTime> publicHolidays(int pYear) {
  final vEaster = easterSunday(pYear);
  DateTime vAfterEaster(int pDays) => DateTime(vEaster.year, vEaster.month, vEaster.day + pDays);
  final rDays = {
    DateTime(pYear, 1, 1),
    vAfterEaster(1),
    DateTime(pYear, 5, 1),
    DateTime(pYear, 5, 8),
    vAfterEaster(39),
    vAfterEaster(50),
    DateTime(pYear, 7, 14),
    DateTime(pYear, 8, 15),
    DateTime(pYear, 11, 1),
    DateTime(pYear, 11, 11),
    DateTime(pYear, 12, 25),
  };

  return rDays;
}

/// Genre de la journée [pDate] : semaine, samedi, ou dimanche et jour férié.
NoiseDay noiseDay(DateTime pDate) {
  final vDay = DateTime(pDate.year, pDate.month, pDate.day);
  final rDay = vDay.weekday == DateTime.sunday || publicHolidays(pDate.year).contains(vDay)
      ? NoiseDay.sundayOrHoliday
      : vDay.weekday == DateTime.saturday
      ? NoiseDay.saturday
      : NoiseDay.weekday;

  return rDay;
}

/// Où en est-on à [pNow] : bruit toléré ou non, fin de la plage en cours, ou début de la
/// prochaine.
typedef NoiseStatus = ({bool allowed, DateTime? until, DateTime next});

NoiseStatus noiseStatus(DateTime pNow) {
  final vMinute = pNow.hour * 60 + pNow.minute;
  for (final vWindow in noiseWindows(noiseDay(pNow))) {
    if (vMinute >= vWindow.fromMinute && vMinute < vWindow.toMinute) {
      return (allowed: true, until: _at(pNow, vWindow.toMinute), next: pNow);
    }
  }
  final rStatus = (allowed: false, until: null, next: _nextStart(pNow));

  return rStatus;
}

/// Début de la prochaine plage après [pNow], jusqu'à une semaine plus loin.
DateTime _nextStart(DateTime pNow) {
  for (var vOffset = 0; vOffset < 8; vOffset++) {
    final vDay = DateTime(pNow.year, pNow.month, pNow.day + vOffset);
    for (final vWindow in noiseWindows(noiseDay(vDay))) {
      final vStart = _at(vDay, vWindow.fromMinute);
      if (vStart.isAfter(pNow)) {
        return vStart;
      }
    }
  }

  // Toujours une plage dans la semaine : ce retour n'est jamais atteint
  return pNow;
}

DateTime _at(DateTime pDay, int pMinute) =>
    DateTime(pDay.year, pDay.month, pDay.day, pMinute ~/ 60, pMinute % 60);

/// Minutes d'avance du rappel sur l'ouverture de la plage du week-end.
const noiseReminderLeadMinutes = 15;

/// Moment du prochain rappel « outil bruyant le week-end » : un quart d'heure avant la
/// première plage du samedi, ou du dimanche si le samedi est passé.
DateTime weekendNoiseReminder(DateTime pNow) {
  for (var vOffset = 0; vOffset < 8; vOffset++) {
    final vDay = DateTime(pNow.year, pNow.month, pNow.day + vOffset);
    if (vDay.weekday != DateTime.saturday && vDay.weekday != DateTime.sunday) {
      continue;
    }
    final vFirst = noiseWindows(noiseDay(vDay)).first.fromMinute - noiseReminderLeadMinutes;
    final vAt = _at(vDay, vFirst);
    if (vAt.isAfter(pNow)) {
      return vAt;
    }
  }

  // Un samedi ou un dimanche à venir existe toujours dans les huit jours
  return pNow;
}
