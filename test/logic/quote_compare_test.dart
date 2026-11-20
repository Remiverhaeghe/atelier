import 'package:atelier/logic/quote_compare.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const Quote vFirst = (
    name: 'Entreprise A',
    posts: {
      QuotePost.protection: 80,
      QuotePost.supplies: 1200,
      QuotePost.labour: 1500,
      QuotePost.debrisRemoval: 250,
    },
  );
  const Quote vSecond = (
    name: 'Entreprise B',
    posts: {QuotePost.supplies: 1100, QuotePost.labour: 2400, QuotePost.finishes: 0},
  );

  test('total d\'un devis', () {
    expect(quoteTotal(vFirst), 3030);
    expect(quoteTotal(vSecond), 3500);
  });

  test('postes côte à côte : le moins cher, l\'écart et ce qui manque', () {
    final vRows = compareQuotes([vFirst, vSecond]);
    expect(
      [for (final vRow in vRows) vRow.post],
      [QuotePost.protection, QuotePost.supplies, QuotePost.labour, QuotePost.debrisRemoval],
    );
    final vLabour = vRows[2];
    expect(vLabour.cheapest, 0);
    expect(vLabour.gap, 900);
    expect(gapIsLarge(vLabour), isTrue);
    final vSupplies = vRows[1];
    expect(vSupplies.cheapest, 1);
    expect(gapIsLarge(vSupplies), isFalse);
    final vDebris = vRows.last;
    expect(vDebris.missing, [1]);
    expect(vDebris.cheapest, isNull);
    expect(vDebris.gap, 0);
    expect(gapIsLarge(vDebris), isFalse);
  });

  test('oublis courants : évacuation, finitions, protection, nettoyage', () {
    expect(forgottenPosts(vFirst), [QuotePost.finishes, QuotePost.cleaning]);
    expect(forgottenPosts(vSecond), [
      QuotePost.protection,
      QuotePost.finishes,
      QuotePost.debrisRemoval,
      QuotePost.cleaning,
    ]);
  });
}
