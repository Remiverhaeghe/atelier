import 'package:atelier/logic/journal.dart';
import 'package:atelier/logic/memories.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vJournal = [
    JournalEntry(id: 'c', roomId: 'r', day: '2026-11-12', title: 'Plinthes', photoPath: '/p/c.jpg'),
    JournalEntry(id: 'n', roomId: 'r', day: '2026-11-01', title: 'Sans photo'),
    JournalEntry(
      id: 'a',
      roomId: 'r',
      day: '2026-11-05',
      title: 'Parquet',
      beforePath: '/p/a0.jpg',
      photoPath: '/p/a.jpg',
    ),
    JournalEntry(id: 'b', roomId: 'r', day: '2026-11-12', title: 'Peinture', beforePath: '/p/b0.jpg', photoPath: '/p/b.jpg'),
  ];

  test('entrées en photo, par jour, l\'avant-après d\'abord', () {
    expect([for (final vEntry in memoryEntries(vJournal)) vEntry.id], ['a', 'b', 'c']);
    expect(memorySpan(vJournal), (first: '2026-11-05', last: '2026-11-12'));
    expect(memorySpan(const []), isNull);
  });

  test('diaporama : l\'avant puis l\'après, en boucle', () {
    final vSlides = memorySlides(vJournal);
    expect([for (final vSlide in vSlides) vSlide.path], [
      '/p/a0.jpg',
      '/p/a.jpg',
      '/p/b0.jpg',
      '/p/b.jpg',
      '/p/c.jpg',
    ]);
    expect(vSlides.first.before, isTrue);
    expect(vSlides[1].before, isFalse);
    expect(nextSlide(4, 5), 0);
    expect(nextSlide(1, 5), 2);
    expect(nextSlide(0, 0), 0);
  });
}
