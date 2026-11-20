/// Suivi de l'humidité d'une pièce dans le temps : un résumé par jour gardé d'un import à
/// l'autre, et la comparaison avant / après les travaux.
///
/// Seuls les résumés du jour sont gardés, pas chaque relevé : un thermo-hygromètre en note un
/// par minute, la pièce resterait légère avec deux ans de suivi.
library;

import 'indoor_climate.dart';

/// Moyennes d'une journée de relevés.
class ClimateDay {
  const ClimateDay({
    required this.day,
    required this.tempC,
    required this.humidity,
    required this.maxHumidity,
    required this.count,
  });

  /// Jour, à minuit.
  final DateTime day;
  final double tempC;
  final double humidity;
  final double maxHumidity;

  /// Nombre de relevés du jour, pour pondérer les moyennes.
  final int count;

  Map<String, Object?> toJson() => {
    'day': _dayText(day),
    'tempC': tempC,
    'humidity': humidity,
    'maxHumidity': maxHumidity,
    'count': count,
  };

  static ClimateDay fromJson(Map<String, Object?> pJson) => ClimateDay(
    day: DateTime.parse(pJson['day']! as String),
    tempC: (pJson['tempC']! as num).toDouble(),
    humidity: (pJson['humidity']! as num).toDouble(),
    maxHumidity: (pJson['maxHumidity']! as num).toDouble(),
    count: pJson['count']! as int,
  );
}

String _dayText(DateTime pDay) =>
    '${pDay.year.toString().padLeft(4, '0')}-${pDay.month.toString().padLeft(2, '0')}-'
    '${pDay.day.toString().padLeft(2, '0')}';

/// Suivi d'une pièce : les jours relevés et la date des travaux, s'il y en a eu.
class ClimateLog {
  const ClimateLog({this.days = const [], this.worksOn});

  final List<ClimateDay> days;
  final DateTime? worksOn;

  ClimateLog copyWith({List<ClimateDay>? days, DateTime? worksOn, bool clearWorks = false}) =>
      ClimateLog(days: days ?? this.days, worksOn: clearWorks ? null : (worksOn ?? this.worksOn));

  Map<String, Object?> toJson() => {
    'days': [for (final vDay in days) vDay.toJson()],
    if (worksOn != null) 'worksOn': _dayText(worksOn!),
  };

  static ClimateLog fromJson(Map<String, Object?> pJson) => ClimateLog(
    days: [
      for (final vDay in (pJson['days'] as List<Object?>?) ?? const [])
        ClimateDay.fromJson(vDay! as Map<String, Object?>),
    ],
    worksOn: switch (pJson['worksOn']) {
      final String vText => DateTime.parse(vText),
      _ => null,
    },
  );
}

/// Jours gardés au plus : deux ans de suivi.
const climateDaysKept = 730;

/// Relevés regroupés par jour, du plus ancien au plus récent.
List<ClimateDay> dailyClimate(List<ClimateReading> pReadings) {
  final vByDay = <DateTime, List<ClimateReading>>{};
  for (final vReading in pReadings) {
    final vDay = DateTime(vReading.at.year, vReading.at.month, vReading.at.day);
    (vByDay[vDay] ??= []).add(vReading);
  }
  final rDays = [
    for (final MapEntry(key: vDay, value: vReadings) in vByDay.entries)
      ClimateDay(
        day: vDay,
        tempC: _mean([for (final vReading in vReadings) vReading.tempC]),
        humidity: _mean([for (final vReading in vReadings) vReading.humidity]),
        maxHumidity: vReadings
            .map((pReading) => pReading.humidity)
            .reduce((pA, pB) => pA > pB ? pA : pB),
        count: vReadings.length,
      ),
  ]..sort((pA, pB) => pA.day.compareTo(pB.day));

  return rDays;
}

/// Jours d'un nouvel import ajoutés au suivi : un jour déjà là est remplacé, les plus anciens
/// partent au-delà de [climateDaysKept].
List<ClimateDay> mergeClimateDays(List<ClimateDay> pKept, List<ClimateDay> pAdded) {
  final vByDay = {for (final vDay in pKept) vDay.day: vDay};
  for (final vDay in pAdded) {
    vByDay[vDay.day] = vDay;
  }
  final vSorted = vByDay.values.toList()..sort((pA, pB) => pA.day.compareTo(pB.day));
  final rDays = vSorted.length > climateDaysKept
      ? vSorted.sublist(vSorted.length - climateDaysKept)
      : vSorted;

  return rDays;
}

/// Moyennes d'une période : humidité, température, jours humides (moyenne au-dessus de 65 %).
typedef ClimatePeriod = ({int days, double humidity, double tempC, int dampDays});

ClimatePeriod? _period(Iterable<ClimateDay> pDays) {
  final vDays = pDays.toList();
  if (vDays.isEmpty) {
    return null;
  }
  final vCount = vDays.fold(0, (pSum, pDay) => pSum + pDay.count);
  double vWeighted(double Function(ClimateDay) pValue) =>
      vDays.fold(0.0, (pSum, pDay) => pSum + pValue(pDay) * pDay.count) / vCount;
  final ClimatePeriod rPeriod = (
    days: vDays.length,
    humidity: vWeighted((pDay) => pDay.humidity),
    tempC: vWeighted((pDay) => pDay.tempC),
    dampDays: vDays.where((pDay) => pDay.humidity > settledHumidity).length,
  );

  return rPeriod;
}

/// Avant et après les travaux ; null tant qu'un des deux côtés n'a aucun jour relevé. Le jour
/// des travaux lui-même n'est compté d'aucun côté.
({ClimatePeriod before, ClimatePeriod after})? compareClimate(ClimateLog pLog) {
  final vWorks = pLog.worksOn;
  if (vWorks == null) {
    return null;
  }
  final vDay = DateTime(vWorks.year, vWorks.month, vWorks.day);
  final vBefore = _period(pLog.days.where((pDay) => pDay.day.isBefore(vDay)));
  final vAfter = _period(pLog.days.where((pDay) => pDay.day.isAfter(vDay)));
  final rComparison = vBefore == null || vAfter == null ? null : (before: vBefore, after: vAfter);

  return rComparison;
}

double _mean(List<double> pValues) => pValues.reduce((pA, pB) => pA + pB) / pValues.length;

/// Écart d'humidité moyenne, en points, en dessous duquel avant et après se valent.
const climateTrendPoints = 3.0;

/// Sens du changement après les travaux.
enum ClimateTrend { drier, damper, same }

ClimateTrend climateTrend(({ClimatePeriod before, ClimatePeriod after}) pComparison) {
  final vChange = pComparison.after.humidity - pComparison.before.humidity;
  final rTrend = vChange <= -climateTrendPoints
      ? ClimateTrend.drier
      : (vChange >= climateTrendPoints ? ClimateTrend.damper : ClimateTrend.same);

  return rTrend;
}
