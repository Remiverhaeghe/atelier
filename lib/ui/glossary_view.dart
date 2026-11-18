import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/glossary.dart';

String termLabel(AppLocalizations pText, Term pTerm) => switch (pTerm) {
  Term.rafter => pText.termRafter,
  Term.ridge => pText.termRidge,
  Term.slope => pText.termSlope,
  Term.kneeWall => pText.termKneeWall,
  Term.header => pText.termHeader,
  Term.joist => pText.termJoist,
  Term.spacing => pText.termSpacing,
  Term.plasterboard => pText.termPlasterboard,
  Term.carrez => pText.termCarrez,
  Term.reveal => pText.termReveal,
  Term.frame => pText.termFrame,
  Term.stile => pText.termStile,
  Term.rail => pText.termRail,
  Term.tenon => pText.termTenon,
  Term.mortise => pText.termMortise,
  Term.rebate => pText.termRebate,
  Term.glazingBead => pText.termGlazingBead,
  Term.setting => pText.termSetting,
};

String termDefinition(AppLocalizations pText, Term pTerm) => switch (pTerm) {
  Term.rafter => pText.termRafterText,
  Term.ridge => pText.termRidgeText,
  Term.slope => pText.termSlopeText,
  Term.kneeWall => pText.termKneeWallText,
  Term.header => pText.termHeaderText,
  Term.joist => pText.termJoistText,
  Term.spacing => pText.termSpacingText,
  Term.plasterboard => pText.termPlasterboardText,
  Term.carrez => pText.termCarrezText,
  Term.reveal => pText.termRevealText,
  Term.frame => pText.termFrameText,
  Term.stile => pText.termStileText,
  Term.rail => pText.termRailText,
  Term.tenon => pText.termTenonText,
  Term.mortise => pText.termMortiseText,
  Term.rebate => pText.termRebateText,
  Term.glazingBead => pText.termGlazingBeadText,
  Term.setting => pText.termSettingText,
};

/// Explication d'un mot, en feuille sous le pouce.
Future<void> showTerm(BuildContext pContext, Term pTerm) {
  final vText = AppLocalizations.of(pContext);

  return showModalBottomSheet<void>(
    context: pContext,
    showDragHandle: true,
    builder: (pSheet) => Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(termLabel(vText, pTerm), style: Theme.of(pSheet).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(termDefinition(vText, pTerm), style: Theme.of(pSheet).textTheme.bodyLarge),
        ],
      ),
    ),
  );
}

/// « Mots du métier » d'un calcul : une puce par mot, touchée pour son explication.
class TermsRow extends StatelessWidget {
  const TermsRow(this.terms, {super.key});

  final List<Term> terms;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(vText.termsTitle, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final vTerm in terms)
                ActionChip(
                  avatar: const Icon(Icons.help_outline, size: 18),
                  label: Text(termLabel(vText, vTerm)),
                  onPressed: () => showTerm(context, vTerm),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lexique complet : tous les mots du métier, dépliés un par un.
class GlossaryScreen extends StatelessWidget {
  const GlossaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(vText.glossaryTitle)),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          for (final vTerm in Term.values)
            Card(
              child: ExpansionTile(
                title: Text(termLabel(vText, vTerm)),
                childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                shape: const Border(),
                children: [Text(termDefinition(vText, vTerm))],
              ),
            ),
        ],
      ),
    );
  }
}
