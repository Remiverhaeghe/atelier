import 'package:atelier/logic/climate_history.dart';
import 'package:atelier/logic/indoor_climate.dart';
import 'package:atelier/logic/room.dart';
import 'package:flutter_test/flutter_test.dart';

ClimateDay day(int pDay, double pHumidity, {int pCount = 24}) => ClimateDay(
  day: DateTime(2026, 11, pDay),
  tempC: 19,
  humidity: pHumidity,
  maxHumidity: pHumidity + 5,
  count: pCount,
);

void main() {
  test('relevés regroupés par jour : moyennes, pointe et nombre', () {
    final List<ClimateReading> vReadings = [
      (at: DateTime(2026, 11, 2, 8), tempC: 18, humidity: 60),
      (at: DateTime(2026, 11, 1, 23), tempC: 20, humidity: 70),
      (at: DateTime(2026, 11, 1, 7), tempC: 18, humidity: 50),
    ];
    final vDays = dailyClimate(vReadings);

    expect(vDays.map((pDay) => pDay.day), [DateTime(2026, 11, 1), DateTime(2026, 11, 2)]);
    expect(vDays.first.humidity, 60);
    expect(vDays.first.tempC, 19);
    expect(vDays.first.maxHumidity, 70);
    expect(vDays.first.count, 2);
    expect(dailyClimate(const []), isEmpty);
  });

  test('un nouvel import remplace les jours déjà là et garde deux ans au plus', () {
    final vMerged = mergeClimateDays([day(1, 60), day(2, 62)], [day(2, 70), day(3, 55)]);
    expect(vMerged.map((pDay) => pDay.humidity), [60, 70, 55]);

    final vLong = [
      for (var vIndex = 0; vIndex < climateDaysKept + 10; vIndex++)
        ClimateDay(
          day: DateTime(2024).add(Duration(days: vIndex)),
          tempC: 19,
          humidity: 50,
          maxHumidity: 55,
          count: 1,
        ),
    ];
    final vKept = mergeClimateDays(const [], vLong);
    expect(vKept, hasLength(climateDaysKept));
    expect(vKept.first.day, vLong[10].day);
  });

  test('avant et après les travaux : moyennes pondérées, jours humides, sens du changement', () {
    final vLog = ClimateLog(
      days: [day(1, 72), day(2, 68, pCount: 72), day(3, 60), day(4, 55), day(5, 57)],
      worksOn: DateTime(2026, 11, 3, 15),
    );
    final vComparison = compareClimate(vLog)!;

    expect(vComparison.before.days, 2);
    expect(vComparison.before.humidity, 69);
    expect(vComparison.before.dampDays, 2);
    expect(vComparison.after.days, 2);
    expect(vComparison.after.humidity, 56);
    expect(vComparison.after.dampDays, 0);
    expect(vComparison.after.tempC, 19);
    expect(climateTrend(vComparison), ClimateTrend.drier);

    final vWorse = compareClimate(vLog.copyWith(days: [day(1, 55), day(5, 60)]))!;
    expect(climateTrend(vWorse), ClimateTrend.damper);
    final vSame = compareClimate(vLog.copyWith(days: [day(1, 55), day(5, 57)]))!;
    expect(climateTrend(vSame), ClimateTrend.same);

    expect(compareClimate(vLog.copyWith(clearWorks: true)), isNull);
    expect(compareClimate(vLog.copyWith(days: [day(1, 60)])), isNull);
  });

  test('le suivi part avec la pièce et en revient', () {
    final vLog = ClimateLog(days: [day(1, 60.5)], worksOn: DateTime(2026, 11, 3));
    final vRoom = Room.fromJson(
      Room(id: 'p', name: 'Salle d\'eau fictive', climate: vLog).toJson(),
    );

    expect(vRoom.climate.worksOn, DateTime(2026, 11, 3));
    expect(vRoom.climate.days.single.humidity, 60.5);
    expect(vRoom.climate.days.single.day, DateTime(2026, 11, 1));
    expect(vRoom.climate.days.single.count, 24);
    expect(const Room(id: 'p', name: 'Vide').toJson().containsKey('climate'), isFalse);
    expect(Room.fromJson(const Room(id: 'p', name: 'Vide').toJson()).climate.days, isEmpty);
    expect(ClimateLog.fromJson(const {}).worksOn, isNull);
  });

  test('la fiche reprend les derniers jours suivis', () {
    final vDays = [day(1, 70), day(10, 65), day(25, 58), day(30, 55)];

    expect(recentClimateDays(vDays, 20).map((pDay) => pDay.day.day), [25, 30]);
    expect(recentClimateDays(vDays, sheetClimateDays), hasLength(4));
    expect(recentClimateDays(const [], sheetClimateDays), isEmpty);
  });

  test('le suivi part en CSV et se réimporte tel quel', () {
    final vLog = ClimateLog(days: [day(1, 61.25), day(2, 58)]);
    final vCsv = climateCsv(vLog);

    expect(vCsv.split('\n').first, startsWith('date;température'));
    expect(vCsv, contains('2026-11-01;19,0;61,3;66,3;24'));

    final vBack = parseClimateCsv(vCsv)!;
    expect(vBack.skipped, 0);
    expect(vBack.readings.map((pReading) => pReading.humidity), [61.3, 58.0]);
    expect(vBack.readings.first.at, DateTime(2026, 11, 1));
    expect(
      climateCsv(const ClimateLog()).split('\n').where((pLine) => pLine.isNotEmpty),
      hasLength(1),
    );
  });

  group('deux pièces', () {
    ClimateLog log(Map<int, double> pHumidity) =>
        ClimateLog(days: [for (final vE in pHumidity.entries) day(vE.key, vE.value)]);

    test('seuls les jours relevés dans les deux pièces comptent', () {
      final vResult = compareRoomsClimate(
        log({1: 50, 2: 55, 3: 90}),
        log({2: 70, 3: 70, 4: 99}),
      )!;

      expect(vResult.first.days, 2);
      expect(vResult.second.days, 2);
      expect(vResult.first.humidity, 72.5);
      expect(vResult.second.humidity, 70);
    });

    test('sans jour en commun ou sans relevé, rien à comparer', () {
      expect(compareRoomsClimate(log({1: 50}), log({2: 50})), isNull);
      expect(compareRoomsClimate(const ClimateLog(), log({2: 50})), isNull);
    });

    test('la pièce la plus sèche, avec trois points de tolérance', () {
      RoomGap gap(double pA, double pB) =>
          roomGap(compareRoomsClimate(log({1: pA}), log({1: pB}))!);

      expect(gap(50, 60), RoomGap.firstDrier);
      expect(gap(60, 50), RoomGap.secondDrier);
      expect(gap(50, 52.9), RoomGap.same);
      expect(gap(50, 53), RoomGap.firstDrier);
      expect(gap(53, 50), RoomGap.secondDrier);
    });

    test('les jours humides se comptent par pièce sur les jours communs', () {
      final vResult = compareRoomsClimate(log({1: 80, 2: 40, 3: 80}), log({1: 40, 2: 40}))!;

      expect(vResult.first.dampDays, 1);
      expect(vResult.second.dampDays, 0);
    });
  });
}
