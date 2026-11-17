/// Travaux extérieurs et prévisions saisies à la main : quels jours conviennent.
library;

/// Travaux du dehors, avec leurs limites courantes : températures, jours secs à suivre, gel à
/// éviter les jours d'après, vent.
enum OutdoorJob {
  facadePaint(minC: 5, maxC: 30, dryDaysAfter: 1, frostFreeDaysAfter: 1, maxWindKmh: 40),
  render(minC: 5, maxC: 30, dryDaysAfter: 1, frostFreeDaysAfter: 2, maxWindKmh: 40),
  concrete(minC: 5, maxC: 30, dryDaysAfter: 1, frostFreeDaysAfter: 2, maxWindKmh: 60),
  woodStain(minC: 10, maxC: 30, dryDaysAfter: 1, frostFreeDaysAfter: 0, maxWindKmh: 40),
  roofing(minC: -10, maxC: 35, dryDaysAfter: 0, frostFreeDaysAfter: 0, maxWindKmh: 30);

  const OutdoorJob({
    required this.minC,
    required this.maxC,
    required this.dryDaysAfter,
    required this.frostFreeDaysAfter,
    required this.maxWindKmh,
  });

  final int minC;
  final int maxC;
  final int dryDaysAfter;
  final int frostFreeDaysAfter;
  final int maxWindKmh;
}

/// Prévision d'un jour, recopiée de la météo.
typedef DayForecast = ({int minC, int maxC, bool rain, int windKmh});

enum WeatherIssue { cold, hot, rain, rainAfter, frostAfter, wind }

/// Raisons pour lesquelles le jour [pIndex] ne convient pas ; vide s'il convient. Les jours
/// d'après qui manquent dans la liste ne comptent pas contre lui.
List<WeatherIssue> weatherIssues(OutdoorJob pJob, List<DayForecast> pDays, int pIndex) {
  final vDay = pDays[pIndex];
  List<DayForecast> vAfter(int pCount) => [
    for (var vNext = pIndex + 1; vNext <= pIndex + pCount && vNext < pDays.length; vNext++)
      pDays[vNext],
  ];
  final rIssues = <WeatherIssue>[
    if (vDay.minC < pJob.minC) WeatherIssue.cold,
    if (vDay.maxC > pJob.maxC) WeatherIssue.hot,
    if (vDay.rain) WeatherIssue.rain,
    if (vAfter(pJob.dryDaysAfter).any((pNext) => pNext.rain)) WeatherIssue.rainAfter,
    if (vAfter(pJob.frostFreeDaysAfter).any((pNext) => pNext.minC <= 0)) WeatherIssue.frostAfter,
    if (vDay.windKmh > pJob.maxWindKmh) WeatherIssue.wind,
  ];

  return rIssues;
}

/// Numéros des jours qui conviennent.
List<int> goodDays(OutdoorJob pJob, List<DayForecast> pDays) => [
  for (var vIndex = 0; vIndex < pDays.length; vIndex++)
    if (weatherIssues(pJob, pDays, vIndex).isEmpty) vIndex,
];
