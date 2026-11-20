/// Souvenirs du chantier : les photos d'avant et d'après du carnet, dans l'ordre des jours,
/// pour un PDF façon carnet ou un petit diaporama.
library;

import 'journal.dart';

/// Une image du diaporama : la photo, l'entrée du carnet et s'il s'agit de l'avant.
typedef MemorySlide = ({String path, JournalEntry entry, bool before});

/// Entrées du carnet qui ont une photo, du plus ancien au plus récent ; celles avec un avant et
/// un après d'abord pour un même jour.
List<JournalEntry> memoryEntries(List<JournalEntry> pJournal) {
  final rEntries =
      [
        for (final vEntry in pJournal)
          if (vEntry.photoPath != null || vEntry.beforePath != null) vEntry,
      ]..sort((pA, pB) {
        final vDay = pA.day.compareTo(pB.day);
        if (vDay != 0) {
          return vDay;
        }
        final vPairA = hasBeforeAfter(pA) ? 0 : 1;
        final vPairB = hasBeforeAfter(pB) ? 0 : 1;

        return vPairA.compareTo(vPairB);
      });

  return rEntries;
}

/// Images du diaporama : l'avant puis l'après de chaque entrée.
List<MemorySlide> memorySlides(List<JournalEntry> pJournal) => [
  for (final vEntry in memoryEntries(pJournal)) ...[
    if (vEntry.beforePath case final vBefore?) (path: vBefore, entry: vEntry, before: true),
    if (vEntry.photoPath case final vAfter?) (path: vAfter, entry: vEntry, before: false),
  ],
];

/// Durée d'une image du diaporama.
const slideDuration = Duration(seconds: 4);

/// Image suivante, en boucle.
int nextSlide(int pIndex, int pCount) => pCount == 0 ? 0 : (pIndex + 1) % pCount;

/// Premier et dernier jour du chantier en photos, ou null sans photo.
({String first, String last})? memorySpan(List<JournalEntry> pJournal) {
  final vEntries = memoryEntries(pJournal);
  if (vEntries.isEmpty) {
    return null;
  }

  return (first: vEntries.first.day, last: vEntries.last.day);
}
