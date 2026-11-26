/// Entretien après travaux : des rappels loin dans le temps (silicone, joints, lasure), posés
/// dans l'agenda de l'appli pour que les finitions ne se dégradent pas sans prévenir.
library;

import 'reminders.dart';

/// Contrôles courants, avec leur intervalle habituel en mois.
enum MaintenanceTask {
  silicone(12),
  grout(12),
  parquetCare(12),
  windowSeals(12),
  woodStain(24),
  ventFilters(6);

  const MaintenanceTask(this.months);

  final int months;
}

/// Même jour [pMonths] mois plus tard, à 9 h ; le dernier jour du mois si le jour n'existe pas
/// (le 31 janvier + 1 mois donne le 28 ou 29 février).
DateTime addMonths(DateTime pFrom, int pMonths) {
  final vMonthIndex = pFrom.month - 1 + pMonths;
  final vYear = pFrom.year + vMonthIndex ~/ 12;
  final vMonth = vMonthIndex % 12 + 1;
  final vLastDay = DateTime(vYear, vMonth + 1, 0).day;

  return DateTime(vYear, vMonth, pFrom.day > vLastDay ? vLastDay : pFrom.day, 9);
}

/// Rappel d'entretien de [pTask] à son intervalle habituel, ou à [pMonths] si on le choisit.
Reminder maintenanceReminder({
  required String pId,
  required MaintenanceTask pTask,
  required String pLabel,
  required DateTime pFrom,
  String? pRoomId,
  int? pMonths,
}) => Reminder(
  id: pId,
  kind: WaitKind.maintenance,
  label: pLabel,
  dueAt: addMonths(pFrom, pMonths ?? pTask.months),
  roomId: pRoomId,
);

/// Attente en jours entiers, arrondie au jour au-dessus.
int daysLeft(Reminder pReminder, DateTime pNow) => (hoursLeft(pReminder, pNow) / 24).ceil();

/// Au-delà de ce nombre de jours, l'attente se dit en mois.
const monthsFromDays = 60;
