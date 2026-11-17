/// Visite d'une maison, pièce par pièce, avant un achat ou avant les travaux.
library;

/// Points à regarder dans chaque pièce, dans l'ordre d'une visite : du sol au plafond.
enum VisitCheck {
  floorLevel,
  dampness,
  cracks,
  windows,
  outlets,
  lights,
  heating,
  ventilation,
  ceilingStains,
  smell,
}

/// Points vus une fois dans la maison, pas dans chaque pièce.
enum HouseCheck { electricPanel, waterHeater, roofSpace, gutters, meters }

/// Réponses d'une pièce : chaque point à voir, avec sa note.
typedef VisitAnswers = Map<VisitCheck, String>;

/// Nombre de points à voir par pièce, pour le résumé de fin de visite.
Map<String, int> visitSummary(Map<String, VisitAnswers> pRooms) => {
  for (final vEntry in pRooms.entries)
    if (vEntry.value.isNotEmpty) vEntry.key: vEntry.value.length,
};
