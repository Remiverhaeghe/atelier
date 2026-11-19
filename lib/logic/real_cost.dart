/// Coût réel du chantier : le temps passé étape par étape, face à ce qu'aurait coûté la
/// main-d'œuvre d'un artisan au taux horaire que l'utilisateur saisit lui-même.
library;

import 'diy_or_pro.dart';
import 'planning.dart';
import 'time_tracking.dart';

/// Une étape : minutes passées, heures qu'un artisan y aurait mises et ce qu'il aurait facturé.
typedef PhaseCost = ({WorkPhase phase, int minutes, double proHours, double proEuros});

typedef RealCost = ({
  List<PhaseCost> phases,
  int minutes,
  double proHours,
  double proEuros,
  double savedPerHour,
});

/// Temps passé par étape et main-d'œuvre évitée, pour un artisan [pSpeedFactor] fois plus
/// rapide (deux fois par défaut, comme dans le calcul « faire soi-même ou faire faire »).
RealCost realCost(
  List<TimeEntry> pEntries,
  double pHourlyRate, {
  double pSpeedFactor = beginnerFactor,
}) {
  final vFactor = pSpeedFactor <= 0 ? 1.0 : pSpeedFactor;
  final vPhases = <PhaseCost>[];
  for (final vPhase in WorkPhase.values) {
    final vMinutes = spentMinutes(pEntries, pPhase: vPhase);
    if (vMinutes > 0) {
      final vProHours = vMinutes / 60 / vFactor;
      vPhases.add((
        phase: vPhase,
        minutes: vMinutes,
        proHours: vProHours,
        proEuros: vProHours * pHourlyRate,
      ));
    }
  }
  final vMinutes = vPhases.fold(0, (pSum, pPhase) => pSum + pPhase.minutes);
  final vEuros = vPhases.fold(0.0, (pSum, pPhase) => pSum + pPhase.proEuros);
  final rCost = (
    phases: vPhases,
    minutes: vMinutes,
    proHours: vPhases.fold(0.0, (pSum, pPhase) => pSum + pPhase.proHours),
    proEuros: vEuros,
    savedPerHour: vMinutes == 0 ? 0.0 : vEuros / (vMinutes / 60),
  );

  return rCost;
}
