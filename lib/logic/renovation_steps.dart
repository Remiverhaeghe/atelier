/// Rénovation énergétique pas à pas : toit, fenêtres, murs, chauffage, ventilation, dans cet
/// ordre, avec l'effet estimé de chaque étape sur la facture.
///
/// Estimation relative et prudente : seule une part du gain théorique est retenue, et le prix
/// de chaque énergie n'entre pas dans le calcul.
library;

import 'heat_loss.dart';

/// Chauffage, avec son rendement saisonnier courant (indicatif).
enum HeatingSystem {
  oldBoiler(0.75),
  condensingBoiler(0.92),
  electric(1.0),
  heatPump(2.8),
  woodStove(0.7);

  const HeatingSystem(this.efficiency);

  /// Chaleur fournie pour une unité d'énergie achetée ; plus de 1 pour une pompe à chaleur.
  final double efficiency;
}

/// Part du gain théorique retenue : chauffage plus confortable après travaux, pose imparfaite.
const prudenceFactor = 0.8;

enum RenovationStep { roof, windows, walls, heating, ventilation }

typedef StepEffect = ({
  RenovationStep step,

  /// Rien à faire : la paroi est déjà à l'état visé, ou le chauffage ne change pas.
  bool skipped,

  /// Baisse de la facture due à cette étape, en part de la facture de départ.
  double stepShare,

  /// Facture restante après cette étape, en part de la facture de départ.
  double remainingShare,
});

/// Énergie achetée pour chauffer, en kWh par an : pertes divisées par le rendement.
double boughtKwh(Envelope pEnvelope, HeatingSystem pHeating) =>
    yearlyKwh(totalLossWK(pEnvelope)) / pHeating.efficiency;

/// Paroi travaillée par une étape ; null pour le chauffage.
EnvelopePart? partOf(RenovationStep pStep) => switch (pStep) {
  RenovationStep.roof => EnvelopePart.roof,
  RenovationStep.windows => EnvelopePart.windows,
  RenovationStep.walls => EnvelopePart.walls,
  RenovationStep.heating => null,
  RenovationStep.ventilation => EnvelopePart.air,
};

/// Effet de chaque étape, faite dans l'ordre et après les précédentes.
List<StepEffect> renovationPlan(Envelope pEnvelope, HeatingSystem pNow, HeatingSystem pNew) {
  final vStart = boughtKwh(pEnvelope, pNow);
  var vEnvelope = pEnvelope;
  var vHeating = pNow;
  var vRemaining = 1.0;
  final rSteps = <StepEffect>[];
  for (final vStep in RenovationStep.values) {
    final vBefore = boughtKwh(vEnvelope, vHeating);
    final vPart = partOf(vStep);
    var vSkipped = false;
    if (vPart == null) {
      vSkipped = pNew.efficiency <= vHeating.efficiency;
      if (!vSkipped) {
        vHeating = pNew;
      }
    } else if (vEnvelope.stateOf(vPart) >= vPart.targetState) {
      vSkipped = true;
    } else {
      vEnvelope = vEnvelope.withState(vPart, vPart.targetState);
    }
    final vAfter = boughtKwh(vEnvelope, vHeating);
    final vShare = vStart == 0 ? 0.0 : (vBefore - vAfter) / vStart * prudenceFactor;
    vRemaining -= vShare;
    rSteps.add((step: vStep, skipped: vSkipped, stepShare: vShare, remainingShare: vRemaining));
  }

  return rSteps;
}

/// Pourcentage arrondi à 5 près : l'estimation n'est pas plus précise que ça.
int roundedPercent(double pShare) => ((pShare * 100) / 5).round() * 5;
