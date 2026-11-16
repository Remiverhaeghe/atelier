/// Faire soi-même ou faire faire : le devis face au matériel, aux outils et au temps passé.
library;

/// Ce qu'on sait du travail : le devis TTC de l'artisan et le chiffrage en le faisant soi-même.
typedef DiyQuote = ({
  double quoteEuros,
  double materialEuros,
  double toolsEuros,
  double hours,
  bool beginner,
  bool aidsNeedPro,
  double aidEuros,
});

/// Un débutant met environ deux fois le temps annoncé dans les tutos.
const beginnerFactor = 2.0;

typedef DiyVerdict = ({
  double diyEuros,
  double proEuros,
  double savingEuros,
  double realHours,
  double savingPerHour,
});

/// Comparaison : coût en le faisant soi-même, coût réel du devis une fois les aides déduites
/// (seulement si l'artisan est RGE quand elles l'exigent), et ce que rapporte chaque heure.
DiyVerdict compareDiy(DiyQuote pQuote) {
  final vDiy = pQuote.materialEuros + pQuote.toolsEuros;
  final vPro = (pQuote.quoteEuros - (pQuote.aidsNeedPro ? pQuote.aidEuros : 0)).clamp(
    0.0,
    double.infinity,
  );
  final vHours = pQuote.hours * (pQuote.beginner ? beginnerFactor : 1);
  final vSaving = vPro - vDiy;
  final rVerdict = (
    diyEuros: vDiy,
    proEuros: vPro,
    savingEuros: vSaving,
    realHours: vHours,
    savingPerHour: vHours > 0 ? vSaving / vHours : 0.0,
  );

  return rVerdict;
}
