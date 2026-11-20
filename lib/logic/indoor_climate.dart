/// Relevés d'un thermo-hygromètre (ThermoPro ou autre) : lecture du fichier exporté et
/// analyse de la pièce, de ce qui est normal à ce qui appelle des travaux.
///
/// Repères utilisés, courants en France : 40 à 60 % d'humidité pour une pièce saine,
/// moisissures favorisées quand l'air reste au-dessus de 70 %, air sec sous 30 %,
/// 19 °C en moyenne pour une pièce de vie chauffée (article R241-26 du Code de
/// l'énergie), 16 à 17 °C conseillés dans une chambre.
library;

import 'dart:math' as math;

/// Un relevé : heure, température en °C, humidité relative en %.
typedef ClimateReading = ({DateTime at, double tempC, double humidity});

/// Usage de la pièce : il change les températures attendues et les pointes tolérées.
enum ClimateRoom { living, bedroom, bathroom, kitchen }

/// Ce que montrent les relevés, du plus urgent au plus anodin.
enum ClimateFinding {
  /// Humidité au-dessus de 70 % une bonne partie du temps : moisissures probables.
  damp,

  /// Après une douche ou la cuisine, l'humidité met plus de deux heures à redescendre.
  slowDrying,

  /// La pièce perd beaucoup de chaleur la nuit.
  nightDrop,

  /// Pièce souvent froide.
  cold,

  /// Pièce chauffée au-dessus de la référence.
  warm,

  /// Air trop sec une bonne partie du temps.
  dry,

  /// Rien de marqué.
  healthy,
}

/// Seuils, tirés des repères ci-dessus.
const dampHumidity = 70.0;
const dryHumidity = 30.0;
const comfortHumidityLow = 40.0;
const comfortHumidityHigh = 60.0;

/// Part du temps au-delà de laquelle un écart compte : un quart des relevés.
const notableShare = 0.25;

/// Pointe d'humidité (douche, cuisson) et niveau où elle est retombée.
const peakHumidity = 80.0;
const settledHumidity = 65.0;
const slowDryingHours = 2.0;

/// Baisse de température moyenne d'une nuit qui mérite d'être signalée.
const nightDropC = 3.0;

/// Température de référence d'une pièce chauffée, selon son usage.
double referenceTempC(ClimateRoom pRoom) => pRoom == ClimateRoom.bedroom ? 17 : 19;

/// Écart toléré autour de la référence avant de parler de pièce froide ou chaude.
const tempMarginC = 2.0;

/// Résumé et constats d'une série de relevés.
typedef ClimateReport = ({
  DateTime from,
  DateTime to,
  int count,
  double meanTempC,
  double minTempC,
  double maxTempC,
  double meanHumidity,
  double dampShare,
  double dryShare,
  double comfortShare,
  double? dryingHours,
  double? nightDropC,
  List<ClimateFinding> findings,
});

/// Analyse des relevés d'une pièce ; null sans relevé.
ClimateReport? analyseClimate(List<ClimateReading> pReadings, ClimateRoom pRoom) {
  if (pReadings.isEmpty) {
    return null;
  }
  final vSorted = [...pReadings]..sort((pA, pB) => pA.at.compareTo(pB.at));
  final vTemps = vSorted.map((pReading) => pReading.tempC).toList();
  final vHumidities = vSorted.map((pReading) => pReading.humidity).toList();
  double vShare(bool Function(double) pTest) =>
      vHumidities.where(pTest).length / vHumidities.length;
  final vMeanTemp = _mean(vTemps);
  final vDamp = vShare((pValue) => pValue > dampHumidity);
  final vDry = vShare((pValue) => pValue < dryHumidity);
  final vComfort = vShare(
    (pValue) => pValue >= comfortHumidityLow && pValue <= comfortHumidityHigh,
  );
  final vDrying = dryingHours(vSorted);
  final vNight = meanNightDrop(vSorted);
  final vReference = referenceTempC(pRoom);
  final vWet = pRoom == ClimateRoom.bathroom || pRoom == ClimateRoom.kitchen;
  final vFindings = [
    if (vDamp >= notableShare) ClimateFinding.damp,
    if (vWet && vDrying != null && vDrying > slowDryingHours) ClimateFinding.slowDrying,
    if (vNight != null && vNight >= nightDropC) ClimateFinding.nightDrop,
    if (vMeanTemp < vReference - tempMarginC) ClimateFinding.cold,
    if (vMeanTemp > vReference + tempMarginC) ClimateFinding.warm,
    if (vDry >= notableShare) ClimateFinding.dry,
  ];
  final ClimateReport rReport = (
    from: vSorted.first.at,
    to: vSorted.last.at,
    count: vSorted.length,
    meanTempC: vMeanTemp,
    minTempC: vTemps.reduce(math.min),
    maxTempC: vTemps.reduce(math.max),
    meanHumidity: _mean(vHumidities),
    dampShare: vDamp,
    dryShare: vDry,
    comfortShare: vComfort,
    dryingHours: vDrying,
    nightDropC: vNight,
    findings: vFindings.isEmpty ? const [ClimateFinding.healthy] : vFindings,
  );

  return rReport;
}

double _mean(List<double> pValues) => pValues.reduce((pA, pB) => pA + pB) / pValues.length;

/// Temps moyen, en heures, pour qu'une pointe d'humidité (plus de 80 %) retombe sous
/// 65 % ; null sans pointe retombée dans la série.
double? dryingHours(List<ClimateReading> pSorted) {
  final vDurations = <double>[];
  DateTime? vPeak;
  for (final vReading in pSorted) {
    if (vPeak == null && vReading.humidity >= peakHumidity) {
      vPeak = vReading.at;
    } else if (vPeak != null && vReading.humidity < settledHumidity) {
      vDurations.add(vReading.at.difference(vPeak).inMinutes / 60);
      vPeak = null;
    }
  }
  final rHours = vDurations.isEmpty ? null : _mean(vDurations);

  return rHours;
}

/// Baisse moyenne de température entre 22 h et 6 h, nuit par nuit ; null sans nuit
/// complète dans la série.
double? meanNightDrop(List<ClimateReading> pSorted) {
  final vDrops = <double>[];
  final vByNight = <DateTime, List<ClimateReading>>{};
  for (final vReading in pSorted) {
    final vHour = vReading.at.hour;
    if (vHour >= 22 || vHour < 6) {
      // La nuit commence la veille au soir : on la range sous le jour du soir
      final vEvening = vHour >= 22 ? vReading.at : vReading.at.subtract(const Duration(days: 1));
      vByNight
          .putIfAbsent(DateTime(vEvening.year, vEvening.month, vEvening.day), () => [])
          .add(vReading);
    }
  }
  for (final vNight in vByNight.values) {
    final vEvening = vNight.where((pReading) => pReading.at.hour == 22);
    final vMorning = vNight.where((pReading) => pReading.at.hour == 5);
    if (vEvening.isNotEmpty && vMorning.isNotEmpty) {
      vDrops.add(vEvening.first.tempC - vMorning.last.tempC);
    }
  }
  final rDrop = vDrops.isEmpty ? null : _mean(vDrops);

  return rDrop;
}

/// Résultat de la lecture d'un fichier : relevés lus et lignes laissées de côté.
typedef ClimateImport = ({List<ClimateReading> readings, int skipped});

/// Lit un export CSV de thermo-hygromètre (ThermoPro et la plupart des autres).
///
/// Les colonnes sont reconnues à leur titre : date ou heure, température, humidité ;
/// une température en °F est convertie. Séparateur virgule, point-virgule ou
/// tabulation ; dates au format ISO, jour/mois/année ou mois/jour/année. Null si le
/// fichier n'a pas ces trois colonnes.
ClimateImport? parseClimateCsv(String pText) {
  final vLines = pText
      .replaceAll('\r', '')
      .split('\n')
      .map((pLine) => pLine.replaceFirst('﻿', '').trim())
      .where((pLine) => pLine.isNotEmpty)
      .toList();
  if (vLines.length < 2) {
    return null;
  }
  final vSeparator = [';', '\t', ','].firstWhere(
    (pCandidate) => vLines.first.contains(pCandidate),
    orElse: () => ',',
  );
  final vHeader = _split(vLines.first, vSeparator).map((pCell) => pCell.toLowerCase()).toList();
  int vColumn(bool Function(String) pTest) => vHeader.indexWhere(pTest);
  final vTime = vColumn(
    (pCell) => pCell.contains('time') || pCell.contains('date') || pCell.contains('heure'),
  );
  final vTemp = vColumn((pCell) => pCell.contains('temp'));
  final vHumidity = vColumn(
    (pCell) => pCell.contains('hum') || pCell.contains('rh') || pCell.contains('hygro'),
  );
  if (vTime < 0 || vTemp < 0 || vHumidity < 0) {
    return null;
  }
  final vFahrenheit = vHeader[vTemp].contains('°f') ||
      vHeader[vTemp].contains('fahrenheit') ||
      vHeader[vTemp].contains('(f)');
  final vRows = [
    for (final vLine in vLines.skip(1)) _split(vLine, vSeparator),
  ];
  final vDayFirst = _dayFirst(vRows.map((pRow) => pRow.length > vTime ? pRow[vTime] : ''));
  final vReadings = <ClimateReading>[];
  var vSkipped = 0;
  for (final vRow in vRows) {
    final vAt = vRow.length > vTime ? parseReadingTime(vRow[vTime], pDayFirst: vDayFirst) : null;
    final vTempValue = vRow.length > vTemp ? _number(vRow[vTemp]) : null;
    final vHumidityValue = vRow.length > vHumidity ? _number(vRow[vHumidity]) : null;
    if (vAt == null || vTempValue == null || vHumidityValue == null || vHumidityValue > 100) {
      vSkipped++;
      continue;
    }
    vReadings.add((
      at: vAt,
      tempC: vFahrenheit ? (vTempValue - 32) * 5 / 9 : vTempValue,
      humidity: vHumidityValue,
    ));
  }
  final ClimateImport rImport = (readings: vReadings, skipped: vSkipped);

  return rImport;
}

List<String> _split(String pLine, String pSeparator) => pLine
    .split(pSeparator)
    .map((pCell) => pCell.trim().replaceAll('"', ''))
    .toList();

double? _number(String pText) {
  final vText = pText.replaceAll(RegExp(r'[^0-9,.\-]'), '').replaceAll(',', '.');

  return double.tryParse(vText);
}

final _aSlashDate = RegExp(r'^(\d{1,2})[/.-](\d{1,2})[/.-](\d{4})(?:[ T,]+(\d{1,2}):(\d{2})(?::(\d{2}))?)?');

/// Vrai si les dates à barres sont écrites jour d'abord : un premier nombre au-delà
/// de 12 ne peut être qu'un jour. Sans indice, la forme française est retenue.
bool _dayFirst(Iterable<String> pCells) {
  var vMonthFirst = false;
  for (final vCell in pCells) {
    final vMatch = _aSlashDate.firstMatch(vCell.trim());
    if (vMatch == null) {
      continue;
    }
    if (int.parse(vMatch.group(1)!) > 12) {
      return true;
    }
    if (int.parse(vMatch.group(2)!) > 12) {
      vMonthFirst = true;
    }
  }

  return !vMonthFirst;
}

/// Heure d'un relevé : ISO (2026-11-20 10:00) ou à barres (20/11/2026 10:00).
DateTime? parseReadingTime(String pText, {bool pDayFirst = true}) {
  final vText = pText.trim();
  final vIso = DateTime.tryParse(vText.replaceFirst(' ', 'T'));
  if (vIso != null) {
    return vIso;
  }
  final vMatch = _aSlashDate.firstMatch(vText);
  if (vMatch == null) {
    return null;
  }
  final vFirst = int.parse(vMatch.group(1)!);
  final vSecond = int.parse(vMatch.group(2)!);
  final rTime = DateTime(
    int.parse(vMatch.group(3)!),
    pDayFirst ? vSecond : vFirst,
    pDayFirst ? vFirst : vSecond,
    int.parse(vMatch.group(4) ?? '0'),
    int.parse(vMatch.group(5) ?? '0'),
    int.parse(vMatch.group(6) ?? '0'),
  );

  return rTime;
}
