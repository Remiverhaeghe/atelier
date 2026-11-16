import 'package:atelier/logic/reminders.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final vNow = DateTime(2026, 11, 16, 10);

  test('attente lancée : échéance selon le type ou la durée choisie', () {
    final vParquet = startWait(pId: 'a', pKind: WaitKind.acclimatise, pNow: vNow, pRoomId: 'salon');
    expect(vParquet.dueAt, DateTime(2026, 11, 18, 10));
    expect(startWait(pId: 'b', pKind: WaitKind.custom, pNow: vNow, pHours: 3).dueAt.hour, 13);
  });

  test('heures restantes et ordre des rappels', () {
    final vSoon = startWait(pId: 's', pKind: WaitKind.paintCoat, pNow: vNow);
    final vLater = startWait(pId: 'l', pKind: WaitKind.screed, pNow: vNow);

    expect(hoursLeft(vSoon, vNow), 6);
    expect(hoursLeft(vSoon, vNow.add(const Duration(hours: 5, minutes: 1))), 1);
    expect(hoursLeft(vSoon, vNow.add(const Duration(hours: 7))), 0);
    expect(sortedReminders([vLater, vSoon]).map((pReminder) => pReminder.id), ['s', 'l']);
  });

  test('les attentes s\'enregistrent avec le chantier', () {
    final vWorksite = Worksite(
      id: 'w',
      name: 'Maison',
      reminders: [startWait(pId: 'a', pKind: WaitKind.glue, pNow: vNow, pLabel: 'Plinthes')],
    );
    final vBack = Worksite.fromJson(vWorksite.toJson()).reminders.single;

    expect((vBack.kind, vBack.label, vBack.dueAt, vBack.roomId), (
      WaitKind.glue,
      'Plinthes',
      DateTime(2026, 11, 17, 10),
      null,
    ));
    expect(Reminder.fromJson({...vBack.toJson(), 'kind': 'inconnu'}).kind, WaitKind.custom);
    expect(const Worksite(id: 'w', name: 'M').toJson().containsKey('reminders'), isFalse);
  });
}
