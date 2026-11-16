/// Conseils et tutos : fiches pas à pas, classées par sujet.
library;

/// Sujet d'une fiche.
enum TipTopic { baseboard, parquet, door, airConditioning }

/// Fiches disponibles ; le texte de chacune vit dans les traductions.
enum Tip {
  baseboardSealant(TipTopic.baseboard, hasWarning: false),
  baseboardGlue(TipTopic.baseboard, hasWarning: false),
  baseboardNails(TipTopic.baseboard, hasWarning: true),
  crookedWalls(TipTopic.baseboard, hasWarning: false),
  parquetMargin(TipTopic.parquet, hasWarning: false),
  doorSeal(TipTopic.door, hasWarning: false),
  airConMaintenance(TipTopic.airConditioning, hasWarning: true);

  const Tip(this.topic, {required this.hasWarning});

  final TipTopic topic;

  /// La fiche porte une mise en garde (sécurité, réglementation).
  final bool hasWarning;
}

/// Fiches d'un sujet, dans l'ordre de l'énumération.
List<Tip> tipsAbout(TipTopic pTopic) => [
  for (final vTip in Tip.values)
    if (vTip.topic == pTopic) vTip,
];

/// Étapes d'une fiche : une par ligne du texte, lignes vides ignorées.
List<String> tipSteps(String pText) => [
  for (final vLine in pText.split('\n'))
    if (vLine.trim().isNotEmpty) vLine.trim(),
];
