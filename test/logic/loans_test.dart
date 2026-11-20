import 'package:atelier/logic/loans.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vSander = Loan(id: 'a', tool: 'Ponceuse', person: 'Voisin', since: '2026-10-30');
  const vLevel = Loan(id: 'b', tool: 'Niveau laser', person: 'Collègue', since: '2026-11-15');

  test('jours de prêt et rappel au-delà de deux semaines', () {
    final vToday = DateTime(2026, 11, 17, 18);
    expect(loanDays(vSander, vToday), 18);
    expect(loanOverdue(vSander, vToday), isTrue);
    expect(loanOverdue(vLevel, vToday), isFalse);
    expect(
      [
        for (final vLoan in sortedLoans([vLevel, vSander])) vLoan.id,
      ],
      ['a', 'b'],
    );
  });

  test('prêt gardé avec le chantier', () {
    final vBack = Loan.fromJson(vSander.toJson());
    expect((vBack.tool, vBack.person, vBack.since), ('Ponceuse', 'Voisin', '2026-10-30'));
  });

  const vMixer = Loan(
    id: 'c',
    tool: 'Malaxeur',
    person: 'Loueur du coin',
    since: '2026-11-18',
    returnBy: '2026-11-21',
    depositEuros: 150,
    dayEuros: 22,
  );

  test('location : jours facturés, coût, retard et rappel la veille du retour', () {
    expect(vMixer.rented, isTrue);
    expect(vSander.rented, isFalse);
    expect(rentalDays(vMixer), 3);
    expect(rentalCost(vMixer), 66);
    expect(rentalDays(vSander), 0);
    // Pris et rendu le même jour : une journée facturée
    expect(
      rentalDays(
        const Loan(
          id: 'd',
          tool: 'Ponceuse',
          person: '',
          since: '2026-11-18',
          returnBy: '2026-11-18',
        ),
      ),
      1,
    );
    expect(rentalLateDays(vMixer, DateTime(2026, 11, 20)), 0);
    expect(rentalLateDays(vMixer, DateTime(2026, 11, 23, 9)), 2);
    expect(rentalLateDays(vSander, DateTime(2026, 11, 23)), 0);
    expect(loanOverdue(vMixer, DateTime(2026, 11, 22)), isTrue);
    expect(loanOverdue(vMixer, DateTime(2026, 11, 21)), isFalse);
    final vReminder = rentalReminder(vMixer)!;
    expect(vReminder.dueAt, DateTime(2026, 11, 20, 18));
    expect(vReminder.id, rentalReminderId(vMixer));
    expect(vReminder.label, 'Malaxeur');
    expect(rentalReminder(vSander), isNull);
  });

  test('location gardée avec le chantier, caution et prix compris', () {
    final vBack = Loan.fromJson(vMixer.toJson());
    expect((vBack.returnBy, vBack.depositEuros, vBack.dayEuros), ('2026-11-21', 150.0, 22.0));
    expect(vSander.toJson().containsKey('returnBy'), isFalse);
  });
}
