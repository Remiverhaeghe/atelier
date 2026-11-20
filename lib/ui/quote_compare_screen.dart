import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/quote_compare.dart';
import '../logic/units.dart';
import 'parquet_view.dart';
import 'theme.dart';

String quotePostLabel(AppLocalizations pText, QuotePost pPost) => switch (pPost) {
  QuotePost.protection => pText.quotePostProtection,
  QuotePost.demolition => pText.quotePostDemolition,
  QuotePost.supplies => pText.quotePostSupplies,
  QuotePost.labour => pText.quotePostLabour,
  QuotePost.finishes => pText.quotePostFinishes,
  QuotePost.debrisRemoval => pText.quotePostDebrisRemoval,
  QuotePost.cleaning => pText.quotePostCleaning,
  QuotePost.travel => pText.quotePostTravel,
};

/// Deux ou trois devis recopiés poste par poste, puis comparés : écarts et oublis courants.
class QuoteCompareScreen extends StatefulWidget {
  const QuoteCompareScreen({super.key});

  @override
  State<QuoteCompareScreen> createState() => _QuoteCompareScreenState();
}

class _QuoteCompareScreenState extends State<QuoteCompareScreen> {
  /// Plus de trois devis ne s'affichent plus lisiblement sur un téléphone.
  static const _maxQuotes = 3;

  final _names = <String>['', ''];
  final _posts = <Map<QuotePost, double>>[{}, {}];

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);
    String vName(int pIndex) =>
        _names[pIndex].trim().isEmpty ? vText.quoteDefaultName(pIndex + 1) : _names[pIndex].trim();
    final vQuotes = <Quote>[
      for (var vIndex = 0; vIndex < _posts.length; vIndex++)
        (name: vName(vIndex), posts: _posts[vIndex]),
    ];
    final vRows = compareQuotes(vQuotes);

    return Scaffold(
      appBar: AppBar(title: Text(vText.quoteCompareTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(vText.quoteCompareIntro, style: vTheme.textTheme.bodyMedium),
          for (var vIndex = 0; vIndex < _posts.length; vIndex++)
            Card(
              key: ValueKey('devis-$vIndex'),
              child: ExpansionTile(
                initiallyExpanded: vIndex == 0,
                title: Text(vName(vIndex)),
                subtitle: Text(formatDecimal(quoteTotal(vQuotes[vIndex]))),
                childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                children: [
                  TextField(
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(labelText: vText.quoteName),
                    onChanged: (pValue) => setState(() => _names[vIndex] = pValue),
                  ),
                  for (final vPost in QuotePost.values)
                    NumberField<double>(
                      label: quotePostLabel(vText, vPost),
                      initial: '',
                      parse: parseDecimal,
                      onValue: (pValue) => setState(() => _posts[vIndex][vPost] = pValue),
                    ),
                ],
              ),
            ),
          if (_posts.length < _maxQuotes)
            OutlinedButton.icon(
              onPressed: () => setState(() {
                _names.add('');
                _posts.add({});
              }),
              icon: const Icon(Icons.add),
              label: Text(vText.quoteAdd),
            ),
          const SizedBox(height: 16),
          Text(vText.quoteComparison, style: vTheme.textTheme.titleMedium),
          for (final vQuote in vQuotes)
            IconLine(
              Icons.request_quote_outlined,
              vText.quoteTotalLine(vQuote.name, formatDecimal(quoteTotal(vQuote))),
            ),
          for (final vRow in vRows) ...[
            IconLine(
              gapIsLarge(vRow) ? AtelierIcons.warning : Icons.compare_arrows,
              vText.quotePostLine(
                quotePostLabel(vText, vRow.post),
                [
                  for (final (vIndex, vAmount) in vRow.amounts.indexed)
                    '${vQuotes[vIndex].name} ${vAmount == null ? vText.quoteMissingShort : '${formatDecimal(vAmount)} €'}',
                ].join(' · '),
              ),
              color: gapIsLarge(vRow) ? vTheme.colorScheme.error : null,
            ),
            if (gapIsLarge(vRow))
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Text(
                  vText.quoteGapLarge(formatDecimal(vRow.gap)),
                  style: vTheme.textTheme.bodySmall,
                ),
              ),
          ],
          const SizedBox(height: 8),
          for (final vQuote in vQuotes)
            if (forgottenPosts(vQuote) case final vForgotten when vForgotten.isNotEmpty)
              IconLine(
                Icons.help_outline,
                vText.quoteForgotten(
                  vQuote.name,
                  [for (final vPost in vForgotten) quotePostLabel(vText, vPost)].join(', '),
                ),
              ),
          const SizedBox(height: 8),
          Text(vText.quoteForgottenHint, style: vTheme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
