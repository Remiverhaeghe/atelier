/// Caisse à outils du débutant : ce qu'il faut d'abord, ce qui vient ensuite, et ce que ça
/// coûte à peu près en entrée de gamme.
library;

/// Indispensable dès le premier chantier, ou utile quand on avance.
enum ToolTier { essential, next }

/// Outils de départ, avec une fourchette de prix indicative en euros.
enum StarterTool {
  tape(ToolTier.essential, 8, 20),
  pencil(ToolTier.essential, 2, 6),
  square(ToolTier.essential, 8, 20),
  spiritLevel(ToolTier.essential, 10, 30),
  cutter(ToolTier.essential, 5, 15),
  handSaw(ToolTier.essential, 12, 30),
  hammer(ToolTier.essential, 10, 25),
  screwdrivers(ToolTier.essential, 10, 30),
  drillDriver(ToolTier.essential, 60, 150),
  bits(ToolTier.essential, 15, 40),
  glasses(ToolTier.essential, 5, 15),
  clamps(ToolTier.next, 15, 40),
  detector(ToolTier.next, 20, 50),
  mitreBox(ToolTier.next, 15, 35),
  caulkGun(ToolTier.next, 5, 15),
  plane(ToolTier.next, 25, 60),
  chisels(ToolTier.next, 20, 50),
  mallet(ToolTier.next, 10, 20),
  sander(ToolTier.next, 40, 90),
  laserLevel(ToolTier.next, 40, 120),
  groutFloat(ToolTier.next, 8, 20),
  dustMask(ToolTier.next, 10, 25);

  const StarterTool(this.tier, this.minEuros, this.maxEuros);

  final ToolTier tier;
  final int minEuros;
  final int maxEuros;
}

typedef ToolBudget = ({int count, int minEuros, int maxEuros});

/// Outils de [pTier] qui manquent quand on a déjà [pOwned], et leur coût total à peu près.
ToolBudget missingTools(Set<StarterTool> pOwned, ToolTier pTier) {
  final vMissing = StarterTool.values.where(
    (pTool) => pTool.tier == pTier && !pOwned.contains(pTool),
  );
  var vMin = 0;
  var vMax = 0;
  for (final vTool in vMissing) {
    vMin += vTool.minEuros;
    vMax += vTool.maxEuros;
  }
  final rBudget = (count: vMissing.length, minEuros: vMin, maxEuros: vMax);

  return rBudget;
}
