/// Carnet de la maison : travaux faits pièce par pièce, avec produits, références, photos et
/// factures, pour une retouche dans dix ans ou une revente.
library;

class JournalEntry {
  const JournalEntry({
    required this.id,
    required this.roomId,
    required this.day,
    required this.title,
    this.product = '',
    this.reference = '',
    this.note = '',
    this.cost,
    this.photoPath,
    this.invoicePath,
    this.beforePath,
  });

  final String id;
  final String roomId;

  /// Jour des travaux, au format AAAA-MM-JJ.
  final String day;
  final String title;

  /// Produit et référence : marque, teinte, numéro de lot.
  final String product;
  final String reference;
  final String note;
  final double? cost;
  final String? photoPath;
  final String? invoicePath;

  /// Photo d'avant les travaux, comparée à [photoPath] en glissant le doigt.
  final String? beforePath;

  JournalEntry copyWith({String? photoPath, String? invoicePath, String? beforePath}) =>
      JournalEntry(
    id: id,
    roomId: roomId,
    day: day,
    title: title,
    product: product,
    reference: reference,
    note: note,
    cost: cost,
    photoPath: photoPath ?? this.photoPath,
    invoicePath: invoicePath ?? this.invoicePath,
    beforePath: beforePath ?? this.beforePath,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'roomId': roomId,
    'day': day,
    'title': title,
    if (product.isNotEmpty) 'product': product,
    if (reference.isNotEmpty) 'reference': reference,
    if (note.isNotEmpty) 'note': note,
    if (cost != null) 'cost': cost,
    if (photoPath != null) 'photoPath': photoPath,
    if (invoicePath != null) 'invoicePath': invoicePath,
    if (beforePath != null) 'beforePath': beforePath,
  };

  static JournalEntry fromJson(Map<String, Object?> pJson) => JournalEntry(
    id: pJson['id']! as String,
    roomId: pJson['roomId']! as String,
    day: pJson['day']! as String,
    title: pJson['title']! as String,
    product: (pJson['product'] as String?) ?? '',
    reference: (pJson['reference'] as String?) ?? '',
    note: (pJson['note'] as String?) ?? '',
    cost: (pJson['cost'] as num?)?.toDouble(),
    photoPath: pJson['photoPath'] as String?,
    invoicePath: pJson['invoicePath'] as String?,
    beforePath: pJson['beforePath'] as String?,
  );
}

/// Entrées d'une pièce, ou de toute la maison, les plus récentes d'abord.
List<JournalEntry> journalOf(List<JournalEntry> pEntries, {String? pRoomId}) => [
  for (final vEntry in pEntries)
    if (pRoomId == null || vEntry.roomId == pRoomId) vEntry,
]..sort((pA, pB) => pB.day.compareTo(pA.day));

/// Coût total noté, pour une pièce ou toute la maison.
double journalCost(List<JournalEntry> pEntries, {String? pRoomId}) =>
    journalOf(pEntries, pRoomId: pRoomId).fold(0.0, (pSum, pEntry) => pSum + (pEntry.cost ?? 0));

/// Dernière référence notée pour un produit qui contient [pSearch] (« blanc », « Velux ») :
/// celle à racheter pour une retouche.
JournalEntry? lastReference(List<JournalEntry> pEntries, String pSearch) {
  final vSearch = pSearch.toLowerCase().trim();
  if (vSearch.isEmpty) {
    return null;
  }

  return journalOf(pEntries)
      .where(
        (pEntry) =>
            pEntry.reference.isNotEmpty &&
            '${pEntry.title} ${pEntry.product} ${pEntry.reference}'.toLowerCase().contains(vSearch),
      )
      .firstOrNull;
}

/// L'entrée a ses deux photos, d'avant et d'après : on peut les comparer.
bool hasBeforeAfter(JournalEntry pEntry) => pEntry.beforePath != null && pEntry.photoPath != null;
