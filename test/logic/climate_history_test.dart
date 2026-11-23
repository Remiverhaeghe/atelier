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
}
