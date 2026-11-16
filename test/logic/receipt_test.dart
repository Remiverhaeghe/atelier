import 'package:atelier/logic/receipt.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ticket fictif : magasin, date et total, sous-total ignoré', () {
    final vReading = readReceipt('''
12345
BRICO DÉMO
Le 14/11/2026 10:42
PARQUET CHENE 12,5 M2   487,50
COLLE                     24,90
SOUS-TOTAL               512,40
TOTAL TTC EUR            512,40
CB                       512,40
''');
    expect(vReading.store, 'BRICO DÉMO');
    expect(vReading.date, '2026-11-14');
    expect(vReading.total, 512.40);
  });

  test('sans ligne total : le plus grand montant ; année sur deux chiffres', () {
    final vReading = readReceipt('Quincaillerie\n03.10.26\nVis 4x40  6.90\nChevilles  2,50\n');
    expect(vReading.total, 6.90);
    expect(vReading.date, '2026-10-03');
  });

  test('texte sans rien d\'utile', () {
    final vReading = readReceipt('  \n42\n');
    expect((vReading.store, vReading.date, vReading.total), (null, null, null));
  });
}
