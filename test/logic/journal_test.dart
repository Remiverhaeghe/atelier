import 'package:atelier/logic/journal.dart';
import 'package:atelier/logic/worksite.dart';
import 'package:flutter_test/flutter_test.dart';

const _entries = [
  JournalEntry(
    id: '1',
    roomId: 'salon',
    day: '2026-03-02',
    title: 'Peinture des murs',
    product: 'Acrylique mat blanc cassé',
    reference: 'TEINTE-0412',
    cost: 120,
  ),
  JournalEntry(id: '2', roomId: 'chambre', day: '2026-05-10', title: 'Parquet flottant', cost: 640),
  JournalEntry(
    id: '3',
    roomId: 'salon',
    day: '2026-09-21',
    title: 'Retouche murs',
    product: 'Acrylique mat blanc cassé',
    reference: 'TEINTE-0412-B',
  ),
];

void main() {
  test('entrées d\'une pièce, les plus récentes d\'abord, et coût', () {
    expect(journalOf(_entries, pRoomId: 'salon').map((pEntry) => pEntry.id), ['3', '1']);
    expect(journalOf(_entries).first.id, '3');
    expect(journalCost(_entries), 760);
    expect(journalCost(_entries, pRoomId: 'salon'), 120);
  });

  test('dernière référence pour une retouche', () {
    expect(lastReference(_entries, 'blanc')!.reference, 'TEINTE-0412-B');
    expect(lastReference(_entries, 'PARQUET'), isNull);
    expect(lastReference(_entries, '  '), isNull);
  });

  test('aller-retour JSON avec photo et facture', () {
    final vWorksite = Worksite(
      id: 'w',
      name: 'Maison',
      journal: [_entries.first.copyWith(photoPath: '/p.jpg', invoicePath: '/f.jpg')],
    );
    final vBack = Worksite.fromJson(vWorksite.toJson()).journal.single;

    expect(
      (vBack.reference, vBack.cost, vBack.photoPath, vBack.invoicePath),
      ('TEINTE-0412', 120.0, '/p.jpg', '/f.jpg'),
    );
    final vBare = JournalEntry.fromJson(_entries[1].toJson());
    expect((vBare.product, vBare.note, vBare.photoPath), ('', '', null));
    expect(const Worksite(id: 'w', name: 'M').toJson().containsKey('journal'), isFalse);
  });
}
