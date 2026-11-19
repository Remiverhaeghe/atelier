/// Finitions du bois : ce qu'on passe dessus pour le protéger, combien en acheter et combien de
/// temps attendre entre deux couches.
///
/// Deux familles : celles qui forment un film en surface (vernis, vitrificateur, peinture) et
/// celles qui pénètrent ou nourrissent le bois (lasure, huile, cire). Un film protège mieux
/// mais s'écaille et se ponce avant d'être refait ; une finition qui pénètre se ravive par une
/// simple couche.
library;

import 'paint.dart';

/// Où va le bois fini.
enum FinishUse { furniture, floor, outdoor }

/// Finitions courantes, avec ce qu'en disent les fiches techniques du commerce.
enum WoodFinish {
  stain(coverageM2PerL: 12, coats: 3, recoatHours: 6, film: false, renewYears: 4),
  varnish(coverageM2PerL: 12, coats: 3, recoatHours: 12, film: true, renewYears: 10),
  floorVarnish(coverageM2PerL: 10, coats: 3, recoatHours: 12, film: true, renewYears: 10),
  oil(coverageM2PerL: 15, coats: 2, recoatHours: 24, film: false, renewYears: 1),
  wax(coverageM2PerL: 20, coats: 2, recoatHours: 2, film: false, renewYears: 1),
  microporousPaint(coverageM2PerL: 10, coats: 2, recoatHours: 12, film: true, renewYears: 8);

  const WoodFinish({
    required this.coverageM2PerL,
    required this.coats,
    required this.recoatHours,
    required this.film,
    required this.renewYears,
  });

  /// Surface couverte par un litre et par couche.
  final double coverageM2PerL;
  final int coats;

  /// Séchage avant la couche suivante, à 20 °C.
  final int recoatHours;

  /// Forme une couche en surface, à poncer avant d'en remettre.
  final bool film;

  /// Entretien à prévoir, en années, à l'usage auquel la finition convient le mieux.
  final int renewYears;
}

/// Pots vendus pour les finitions, en litres.
const finishPotSizes = [0.5, 1.0, 2.5, 5.0];

/// Finitions qui conviennent à [pUse] : un sol veut une couche qui résiste aux pas, le dehors
/// une couche qui laisse le bois respirer et ne craint pas les UV.
List<WoodFinish> finishesFor(FinishUse pUse) => switch (pUse) {
  FinishUse.furniture =>
    WoodFinish.values.where((pFinish) => pFinish != WoodFinish.floorVarnish).toList(),
  FinishUse.floor => const [WoodFinish.floorVarnish, WoodFinish.oil],
  FinishUse.outdoor => const [WoodFinish.stain, WoodFinish.oil, WoodFinish.microporousPaint],
};

typedef FinishPlan = ({double litres, Map<double, int> pots, int waitHours});

/// Quantité de [pFinish] pour [pAreaM2] de bois, pots les moins chers et attente totale entre
/// la première et la dernière couche.
FinishPlan planFinish(WoodFinish pFinish, double pAreaM2) {
  final vArea = pAreaM2 < 0 ? 0.0 : pAreaM2;
  final vLitres = vArea * pFinish.coats / pFinish.coverageM2PerL;
  final rPlan = (
    litres: vLitres,
    pots: cheapestPots(vLitres, finishPotSizes, const {}),
    waitHours: (pFinish.coats - 1) * pFinish.recoatHours,
  );

  return rPlan;
}
