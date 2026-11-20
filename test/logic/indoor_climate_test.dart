import 'package:atelier/logic/indoor_climate.dart';
import 'package:flutter_test/flutter_test.dart';

/// Relevés fictifs toutes les heures sur [pDays] jours, à partir du 1er décembre 2026.
List<ClimateReading> hourly(
  int pDays,
  double Function(DateTime) pTemp,
  double Function(DateTime) pHumidity,
) => [
  for (var vHour = 0; vHour < pDays * 24; vHour++)
    () {
      final vAt = DateTime(2026, 12, 1).add(Duration(hours: vHour));
      return (at: vAt, tempC: pTemp(vAt), humidity: pHumidity(vAt));
    }(),
];

void main() {
  group('lecture du fichier', () {
    test('export ThermoPro : dates ISO, colonnes reconnues à leur titre', () {
      final vImport = parseClimateCsv(
        '﻿Timestamp,Temperature_Celsius(°C),Relative_Humidity(%)\n'
        '2026-12-01 08:00,19.4,52\n'
        '2026-12-01 09:00,19.8,55\n'
        'ligne abîmée\n',
      )!;

      expect(vImport.readings, hasLength(2));
      expect(vImport.skipped, 1);
      expect(vImport.readings.first.at, DateTime(2026, 12, 1, 8));
      expect(vImport.readings.last.tempC, 19.8);
      expect(vImport.readings.last.humidity, 55);
    });

    test('point-virgule, virgule décimale, jour avant le mois et degrés Fahrenheit', () {
      final vImport = parseClimateCsv(
        'Date;Température (°F);Humidité\n'
        '13/12/2026 22:30;68,0;61\n'
        '14/12/2026 05:00;59,0;150\n',
      )!;

      expect(vImport.readings.single.at, DateTime(2026, 12, 13, 22, 30));
      expect(vImport.readings.single.tempC, closeTo(20, 1e-9));
      // Plus de 100 % d'humidité : la ligne est écartée
      expect(vImport.skipped, 1);
    });

    test('mois avant le jour quand un second nombre dépasse 12', () {
      expect(
        parseClimateCsv('Time,Temp,RH\n12/25/2026 10:00,20,50\n')!.readings.single.at,
        DateTime(2026, 12, 25, 10),
      );
      expect(parseReadingTime('01/02/2026', pDayFirst: false), DateTime(2026, 1, 2));
      expect(parseReadingTime('pas une date'), isNull);
    });

    test('sans colonne de température, d\'humidité ou de date : illisible', () {
      expect(parseClimateCsv('Date,Temp\n2026-12-01,20\n'), isNull);
      expect(parseClimateCsv('Date,Temp,Humidité'), isNull);
    });
  });

  group('analyse', () {
    test('pièce saine : rien de marqué', () {
      final vReport = analyseClimate(hourly(3, (_) => 19.5, (_) => 50), ClimateRoom.living)!;

      expect(vReport.findings, [ClimateFinding.healthy]);
      expect(vReport.comfortShare, 1);
      expect(vReport.count, 72);
      expect(analyseClimate(const [], ClimateRoom.living), isNull);
    });

    test('salle d\'eau humide qui sèche lentement après chaque douche', () {
      // Douche à 7 h chaque matin : 90 %, puis l'air ne retombe sous 65 % que vers 11 h
      final vReport = analyseClimate(
        hourly(4, (_) => 21, (pAt) => pAt.hour >= 7 && pAt.hour < 11 ? 90 : 72),
        ClimateRoom.bathroom,
      )!;

      expect(vReport.findings, contains(ClimateFinding.damp));
      expect(vReport.dryingHours, isNull);
      final vSlow = analyseClimate(
        hourly(4, (_) => 21, (pAt) => pAt.hour >= 7 && pAt.hour < 11 ? 90 : 55),
        ClimateRoom.bathroom,
      )!;
      expect(vSlow.dryingHours, 4);
      expect(vSlow.findings, contains(ClimateFinding.slowDrying));
      // Dans une chambre, la même pointe n'est pas suivie
      expect(
        analyseClimate(
          hourly(4, (_) => 17, (pAt) => pAt.hour >= 7 && pAt.hour < 11 ? 90 : 55),
          ClimateRoom.bedroom,
        )!.findings,
        isNot(contains(ClimateFinding.slowDrying)),
      );
    });

    test('pièce froide qui perd sa chaleur la nuit', () {
      double vTemp(DateTime pAt) => pAt.hour >= 22 ? 18 : (pAt.hour < 6 ? 13 : 16);
      final vReport = analyseClimate(hourly(3, vTemp, (_) => 50), ClimateRoom.living)!;

      expect(vReport.nightDropC, 5);
      expect(vReport.findings, containsAll([ClimateFinding.nightDrop, ClimateFinding.cold]));
    });

    test('chambre surchauffée à l\'air sec', () {
      final vReport = analyseClimate(hourly(2, (_) => 22, (_) => 25), ClimateRoom.bedroom)!;

      expect(vReport.findings, [ClimateFinding.warm, ClimateFinding.dry]);
      expect(referenceTempC(ClimateRoom.bedroom), 17);
      expect(vReport.dryShare, 1);
    });
  });
}
