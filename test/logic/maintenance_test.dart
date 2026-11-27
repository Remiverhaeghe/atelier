import 'package:atelier/logic/maintenance.dart';
import 'package:atelier/logic/reminders.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('un mois de plus : le dernier jour du mois quand le jour n\'existe pas', () {
    expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28, 9));
    expect(addMonths(DateTime(2027, 1, 31), 1), DateTime(2027, 2, 28, 9));
    expect(addMonths(DateTime(2027, 12, 31), 2), DateTime(2028, 2, 29, 9));
  });

  test('l\'année change avec les mois', () {
    expect(addMonths(DateTime(2026, 11, 26), 12), DateTime(2027, 11, 26, 9));
    expect(addMonths(DateTime(2026, 11, 26), 24), DateTime(2028, 11, 26, 9));
    expect(addMonths(DateTime(2026, 11, 26), 6), DateTime(2027, 5, 26, 9));
  });

  test('le rappel d\'entretien tombe à l\'intervalle habituel, ou à celui qu\'on choisit', () {
    final vFrom = DateTime(2026, 11, 26, 18);
    final vSilicone = maintenanceReminder(
      pId: 'm1',
      pTask: MaintenanceTask.silicone,
      pLabel: 'Silicone',
      pFrom: vFrom,
      pRoomId: 'sdb',
    );
    final vCustom = maintenanceReminder(
      pId: 'm2',
      pTask: MaintenanceTask.silicone,
      pLabel: 'Silicone',
      pFrom: vFrom,
      pMonths: 3,
    );

    expect(vSilicone.kind, WaitKind.maintenance);
    expect(vSilicone.dueAt, DateTime(2027, 11, 26, 9));
    expect(vSilicone.roomId, 'sdb');
    expect(vCustom.dueAt, DateTime(2027, 2, 26, 9));
  });

  test('le rappel se range et se relit avec son genre', () {
    final vReminder = maintenanceReminder(
      pId: 'm',
      pTask: MaintenanceTask.woodStain,
      pLabel: 'Lasure',
      pFrom: DateTime(2026, 11, 26),
    );

    expect(Reminder.fromJson(vReminder.toJson()).kind, WaitKind.maintenance);
  });

  test('jours restants : arrondis au jour au-dessus, zéro une fois l\'échéance passée', () {
    final vReminder = maintenanceReminder(
      pId: 'm',
      pTask: MaintenanceTask.ventFilters,
      pLabel: 'Filtres',
      pFrom: DateTime(2026, 11, 26),
    );

    expect(daysLeft(vReminder, DateTime(2027, 5, 25, 9)), 1);
    expect(daysLeft(vReminder, DateTime(2027, 6, 1)), 0);
    expect(MaintenanceTask.values.every((pTask) => pTask.months > 0), isTrue);
  });
}
