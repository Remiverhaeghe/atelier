/// Extérieur : surface d'une façade à peindre ou enduire, et clôture en panneaux rigides.
library;

typedef Facade = ({int widthMm, int heightMm, int gableMm, double openingsM2});

/// Surface à traiter : le mur, le pignon en triangle au-dessus, moins les ouvertures.
double facadeM2(Facade pFacade) {
  final vWall = pFacade.widthMm * pFacade.heightMm / 1e6;
  final vGable = pFacade.widthMm * pFacade.gableMm / 2 / 1e6;
  final vArea = vWall + vGable - pFacade.openingsM2;

  return vArea < 0 ? 0 : vArea;
}

/// Peinture de façade : deux couches à environ 6 m² par litre et par couche.
const facadeM2PerLitre = 6.0;

/// Enduit monocouche : environ 17 kg par mètre carré pour 15 mm.
const renderKgPerM2 = 17.0;

/// Sac d'enduit courant.
const renderBagKg = 25;

double facadePaintLitres(double pAreaM2) => pAreaM2 * 2 / facadeM2PerLitre;

int renderBags(double pAreaM2) => (pAreaM2 * renderKgPerM2 / renderBagKg - 1e-9).ceil();

/// Panneau rigide courant : 2,50 m entre poteaux.
const fencePanelMm = 2500;

/// Trou de poteau de 30 × 30 × 50 cm, rempli de béton : un sac de 35 kg donne environ 17 litres.
const postHoleLitres = 45.0;
const concreteBagLitres = 17.0;

typedef FencePlan = ({int panels, int posts, int concreteBags, int lastPanelMm});

/// Clôture de [pLengthMm] en [pSides] côtés droits : un poteau à chaque bout de panneau, un
/// poteau d'angle de plus par changement de direction compté dans le total, dernier panneau
/// recoupé.
FencePlan fencePlan(int pLengthMm, {int pSides = 1}) {
  if (pLengthMm <= 0) {
    return (panels: 0, posts: 0, concreteBags: 0, lastPanelMm: 0);
  }
  final vSides = pSides < 1 ? 1 : pSides;
  final vPanels = (pLengthMm / fencePanelMm - 1e-9).ceil();
  // Côtés ouverts : un poteau de plus que de panneaux, plus un par angle où un panneau est coupé
  final vPosts = vPanels + 1 + (vSides - 1);
  final vLast = pLengthMm - (vPanels - 1) * fencePanelMm;
  final rPlan = (
    panels: vPanels,
    posts: vPosts,
    concreteBags: (vPosts * postHoleLitres / concreteBagLitres - 1e-9).ceil(),
    lastPanelMm: vLast,
  );

  return rPlan;
}
