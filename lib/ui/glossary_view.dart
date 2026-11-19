import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/glossary.dart';
import 'gestures_screen.dart';
import 'glossary_scenes.dart';

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
  Term.grain => pText.termGrain,
  Term.edge => pText.termEdge,
  Term.chamfer => pText.termChamfer,
  Term.kerf => pText.termKerf,
  Term.pilotHole => pText.termPilotHole,
  Term.countersink => pText.termCountersink,
  Term.furring => pText.termFurring,
  Term.vapourBarrier => pText.termVapourBarrier,
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
  Term.grain => pText.termGrainText,
  Term.edge => pText.termEdgeText,
  Term.chamfer => pText.termChamferText,
  Term.kerf => pText.termKerfText,
  Term.pilotHole => pText.termPilotHoleText,
  Term.countersink => pText.termCountersinkText,
  Term.furring => pText.termFurringText,
  Term.vapourBarrier => pText.termVapourBarrierText,
};

String termUse(AppLocalizations pText, Term pTerm) => switch (pTerm) {
  Term.rafter => pText.termRafterUse,
  Term.ridge => pText.termRidgeUse,
  Term.slope => pText.termSlopeUse,
  Term.kneeWall => pText.termKneeWallUse,
  Term.header => pText.termHeaderUse,
  Term.joist => pText.termJoistUse,
  Term.spacing => pText.termSpacingUse,
  Term.plasterboard => pText.termPlasterboardUse,
  Term.carrez => pText.termCarrezUse,
  Term.reveal => pText.termRevealUse,
  Term.frame => pText.termFrameUse,
  Term.stile => pText.termStileUse,
  Term.rail => pText.termRailUse,
  Term.tenon => pText.termTenonUse,
  Term.mortise => pText.termMortiseUse,
  Term.rebate => pText.termRebateUse,
  Term.glazingBead => pText.termGlazingBeadUse,
  Term.setting => pText.termSettingUse,
  Term.grain => pText.termGrainUse,
  Term.edge => pText.termEdgeUse,
  Term.chamfer => pText.termChamferUse,
  Term.kerf => pText.termKerfUse,
  Term.pilotHole => pText.termPilotHoleUse,
  Term.countersink => pText.termCountersinkUse,
  Term.furring => pText.termFurringUse,
  Term.vapourBarrier => pText.termVapourBarrierUse,
};

/// Fiche d'un mot : schéma en relief, à quoi ça sert, puis ce que c'est.
class TermCard extends StatelessWidget {
  const TermCard(this.term, {super.key});

  final Term term;

  @override
  Widget build(BuildContext context) {
    final vText = AppLocalizations.of(context);
    final vTheme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TermSketch(term),
        const SizedBox(height: 8),
        Text(vText.termUseTitle, style: vTheme.textTheme.titleSmall),
        Text(termUse(vText, term), style: vTheme.textTheme.bodyLarge),
        const SizedBox(height: 8),
        Text(vText.termWhatTitle, style: vTheme.textTheme.titleSmall),
        Text(termDefinition(vText, term), style: vTheme.textTheme.bodyMedium),
      ],
    );
  }
}

/// Explication d'un mot, en feuille sous le pouce.
Future<void> showTerm(BuildContext pContext, Term pTerm) {
  final vText = AppLocalizations.of(pContext);

  return showModalBottomSheet<void>(
    context: pContext,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (pSheet) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(termLabel(vText, pTerm), style: Theme.of(pSheet).textTheme.headlineSmall),
          TermCard(pTerm),
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
      appBar: AppBar(
        title: Text(vText.glossaryTitle),
        actions: [
          IconButton(
            tooltip: vText.gesturesTitle,
            icon: const Icon(Icons.handyman_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (_) => const GesturesScreen()),
            ),
          ),
        ],
      ),
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
                children: [TermCard(vTerm)],
              ),
            ),
        ],
      ),
    );
  }
}
