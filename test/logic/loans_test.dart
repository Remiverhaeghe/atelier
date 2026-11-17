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
}
