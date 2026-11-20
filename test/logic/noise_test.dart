import 'package:atelier/logic/noise.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Pâques et fêtes mobiles', () {
    expect(easterSunday(2024), DateTime(2024, 3, 31));
    expect(easterSunday(2025), DateTime(2025, 4, 20));
    expect(easterSunday(2026), DateTime(2026, 4, 5));
    final vHolidays = publicHolidays(2026);
    expect(vHolidays, hasLength(11));
    // Lundi de Pâques, Ascension, lundi de Pentecôte
    expect(
      vHolidays,
      containsAll([DateTime(2026, 4, 6), DateTime(2026, 5, 14), DateTime(2026, 5, 25)]),
    );
  });

  test('genre de la journée : semaine, samedi, dimanche ou férié', () {
    expect(noiseDay(DateTime(2026, 11, 19, 10)), NoiseDay.weekday);
    expect(noiseDay(DateTime(2026, 11, 21)), NoiseDay.saturday);
    expect(noiseDay(DateTime(2026, 11, 22)), NoiseDay.sundayOrHoliday);
    // Le 11 novembre tombe un mercredi en 2026
    expect(noiseDay(DateTime(2026, 11, 11, 9)), NoiseDay.sundayOrHoliday);
  });

  test('en semaine : toléré le matin, silence au déjeuner', () {
    final vMorning = noiseStatus(DateTime(2026, 11, 19, 10));
    expect(vMorning.allowed, isTrue);
    expect(vMorning.until, DateTime(2026, 11, 19, 12));

    final vLunch = noiseStatus(DateTime(2026, 11, 19, 13));
    expect(vLunch.allowed, isFalse);
    expect(vLunch.until, isNull);
    expect(vLunch.next, DateTime(2026, 11, 19, 14, 30));
  });

  test('le soir, la prochaine plage est le lendemain, selon le jour', () {
    expect(noiseStatus(DateTime(2026, 11, 20, 20)).next, DateTime(2026, 11, 21, 9));
    expect(noiseStatus(DateTime(2026, 11, 21, 20)).next, DateTime(2026, 11, 22, 10));
    expect(noiseStatus(DateTime(2026, 11, 22, 12, 30)).next, DateTime(2026, 11, 23, 8, 30));
  });

  test('rappel du week-end : un quart d\'heure avant la première plage', () {
    expect(weekendNoiseReminder(DateTime(2026, 11, 19, 10)), DateTime(2026, 11, 21, 8, 45));
    expect(weekendNoiseReminder(DateTime(2026, 11, 21, 9)), DateTime(2026, 11, 22, 9, 45));
    expect(weekendNoiseReminder(DateTime(2026, 11, 22, 10)), DateTime(2026, 11, 28, 8, 45));
  });
}
