/// Comparaison de devis poste par poste : écarts entre artisans et oublis courants.
library;

/// Postes d'un devis de travaux, dans l'ordre où ils apparaissent d'habitude.
enum QuotePost {
  protection(true),
  demolition(false),
  supplies(false),
  labour(false),
  finishes(true),
  debrisRemoval(true),
  cleaning(true),
  travel(false);

  const QuotePost(this.oftenForgotten);

  /// Poste souvent absent d'un devis et facturé ensuite, ou laissé à la charge du client.
  final bool oftenForgotten;
}

/// Un devis : le nom de l'entreprise et le montant TTC de chaque poste ; un poste absent ou à
/// zéro n'est pas chiffré.
typedef Quote = ({String name, Map<QuotePost, double> posts});

double quoteTotal(Quote pQuote) => pQuote.posts.values.fold(0.0, (pSum, pAmount) => pSum + pAmount);

/// Un poste comparé : le montant de chaque devis (null s'il manque), le moins cher et l'écart
/// entre le plus cher et le moins cher.
typedef PostComparison = ({
  QuotePost post,
  List<double?> amounts,
  int? cheapest,
  double gap,
  List<int> missing,
});

/// Écart à partir duquel un poste mérite une question à l'artisan : la moitié du moins cher.
const suspiciousGapRatio = 0.5;

/// Postes de [pQuotes] côte à côte. Un poste chiffré par personne n'apparaît pas.
List<PostComparison> compareQuotes(List<Quote> pQuotes) {
  final rRows = <PostComparison>[];
  for (final vPost in QuotePost.values) {
    final vAmounts = [
      for (final vQuote in pQuotes) (vQuote.posts[vPost] ?? 0) > 0 ? vQuote.posts[vPost] : null,
    ];
    final vPriced = [
      for (final (vIndex, vAmount) in vAmounts.indexed)
        if (vAmount != null) (vIndex, vAmount),
    ];
    if (vPriced.isEmpty) {
      continue;
    }
    vPriced.sort((pA, pB) => pA.$2.compareTo(pB.$2));
    rRows.add((
      post: vPost,
      amounts: vAmounts,
      cheapest: vPriced.length > 1 ? vPriced.first.$1 : null,
      gap: vPriced.last.$2 - vPriced.first.$2,
      missing: [
        for (final (vIndex, vAmount) in vAmounts.indexed)
          if (vAmount == null) vIndex,
      ],
    ));
  }

  return rRows;
}

/// L'écart sur ce poste est grand : plus de [suspiciousGapRatio] du moins cher.
bool gapIsLarge(PostComparison pRow) {
  final vPriced = pRow.amounts.whereType<double>().toList()..sort();
  final rLarge = vPriced.length > 1 && pRow.gap > vPriced.first * suspiciousGapRatio;

  return rLarge;
}

/// Oublis courants d'un devis : les postes souvent laissés de côté qu'il ne chiffre pas.
List<QuotePost> forgottenPosts(Quote pQuote) => [
  for (final vPost in QuotePost.values)
    if (vPost.oftenForgotten && (pQuote.posts[vPost] ?? 0) <= 0) vPost,
];
