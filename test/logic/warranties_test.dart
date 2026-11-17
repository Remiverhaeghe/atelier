import 'package:atelier/logic/warranties.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vBoiler = Warranty(
    id: 'c',
    label: 'Chaudière',
    kind: WarrantyKind.biennial,
    start: '2025-01-10',
  );
  const vRoof = Warranty(
    id: 't',
    label: 'Toiture',
    kind: WarrantyKind.decennial,
    start: '2024-06-01',
  );
  const vTool = Warranty(
    id: 'p',
    label: 'Ponceuse',
    kind: WarrantyKind.custom,
    start: '2026-11-01',
    months: 36,
  );

  test('fin de garantie selon le type', () {
    expect(vBoiler.end, DateTime(2027, 1, 10));
    expect(vRoof.end, DateTime(2034, 6, 1));
    expect(vTool.end, DateTime(2029, 11, 1));
  });

  test('bientôt finie deux mois avant, puis finie', () {
    expect(warrantyState(vBoiler, DateTime(2026, 11, 17)), WarrantyState.endingSoon);
    expect(warrantyState(vBoiler, DateTime(2026, 9, 1)), WarrantyState.running);
    expect(warrantyState(vBoiler, DateTime(2027, 1, 11)), WarrantyState.ended);
    expect(
      [
        for (final vWarranty in sortedWarranties([vRoof, vTool, vBoiler])) vWarranty.id,
      ],
      ['c', 'p', 't'],
    );
  });

  test('garantie gardée avec le chantier', () {
    final vBack = Warranty.fromJson(vTool.toJson());
    expect((vBack.kind, vBack.months, vBack.end), (WarrantyKind.custom, 36, vTool.end));
    expect(Warranty.fromJson({...vBoiler.toJson(), 'kind': 'autre'}).kind, WarrantyKind.custom);
    expect(vBoiler.toJson().containsKey('months'), isFalse);
  });
}
