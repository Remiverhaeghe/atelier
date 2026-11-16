/// Ticket de caisse lu sans réseau : le texte copié depuis la photo (Google Lens, l'appareil
/// photo du téléphone) donne le magasin, la date et le total.
library;

typedef ReceiptReading = ({String? store, String? date, double? total});

final _aAmount = RegExp(r'(\d{1,6})[.,](\d{2})(?!\d)');
final _aDate = RegExp(r'(\d{2})[/.-](\d{2})[/.-](\d{2,4})');

List<double> _amounts(String pLine) => [
  for (final vMatch in _aAmount.allMatches(pLine))
    double.parse('${vMatch.group(1)}.${vMatch.group(2)}'),
];

/// Lecture du ticket : le dernier montant d'une ligne « total » (sauf sous-total), sinon le plus
/// grand montant ; la première date jour/mois/année ; la première ligne écrite en lettres.
ReceiptReading readReceipt(String pText) {
  final vLines = [
    for (final vLine in pText.split('\n'))
      if (vLine.trim().isNotEmpty) vLine.trim(),
  ];
  double? vTotal;
  for (final vLine in vLines) {
    final vLower = vLine.toLowerCase();
    if (vLower.contains('total') && !vLower.contains('sous')) {
      final vFound = _amounts(vLine);
      if (vFound.isNotEmpty) {
        vTotal = vFound.last;
      }
    }
  }
  if (vTotal == null) {
    final vAll = [for (final vLine in vLines) ..._amounts(vLine)];
    vTotal = vAll.isEmpty ? null : vAll.reduce((pA, pB) => pA > pB ? pA : pB);
  }
  String? vDate;
  if (_aDate.firstMatch(pText) case final vMatch?) {
    final vYear = vMatch.group(3)!;
    vDate = '${vYear.length == 2 ? '20$vYear' : vYear}-${vMatch.group(2)}-${vMatch.group(1)}';
  }
  final vStore = vLines.where((pLine) => RegExp(r'[A-Za-zÀ-ÿ]{3}').hasMatch(pLine)).firstOrNull;
  final rReading = (store: vStore, date: vDate, total: vTotal);

  return rReading;
}
