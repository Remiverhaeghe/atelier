import 'package:atelier/logic/outdoor_weather.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vWeek = <DayForecast>[
    (minC: 8, maxC: 18, rain: false, windKmh: 10),
    (minC: 9, maxC: 19, rain: true, windKmh: 20),
    (minC: 6, maxC: 16, rain: false, windKmh: 15),
    (minC: 1, maxC: 9, rain: false, windKmh: 10),
    (minC: -2, maxC: 6, rain: false, windKmh: 50),
  ];

  test('peinture de façade : sec le jour même et le lendemain, sans gel la nuit d\'après', () {
    expect(weatherIssues(OutdoorJob.facadePaint, vWeek, 0), [WeatherIssue.rainAfter]);
    expect(weatherIssues(OutdoorJob.facadePaint, vWeek, 1), [WeatherIssue.rain]);
    expect(goodDays(OutdoorJob.facadePaint, vWeek), [2]);
  });

  test('béton : deux jours sans gel ; lasure : 10 °C au moins ; toiture : le vent compte', () {
    expect(weatherIssues(OutdoorJob.concrete, vWeek, 2), [WeatherIssue.frostAfter]);
    expect(weatherIssues(OutdoorJob.woodStain, vWeek, 2), [WeatherIssue.cold]);
    expect(weatherIssues(OutdoorJob.roofing, vWeek, 4), [WeatherIssue.wind]);
    expect(weatherIssues(OutdoorJob.render, vWeek, 4), [
      WeatherIssue.cold,
      WeatherIssue.wind,
    ]);
    expect(weatherIssues(OutdoorJob.roofing, vWeek, 3), isEmpty);
    const vHot = <DayForecast>[(minC: 10, maxC: 32, rain: false, windKmh: 0)];
    expect(weatherIssues(OutdoorJob.facadePaint, vHot, 0), [WeatherIssue.hot]);
  });
}
