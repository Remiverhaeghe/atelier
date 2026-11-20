/// Relevés de caméra thermique : zone froide repérée, préconisation et matériel à prévoir.
library;

import 'condensation.dart';

/// Défauts courants visibles à la caméra thermique, de l'intérieur, par temps froid.
enum ThermalIssue {
  /// Fuite d'air autour d'une fenêtre.
  windowFrame,

  /// Air sous ou autour d'une porte.
  doorGap,

  /// Prise ou interrupteur sur un mur donnant dehors.
  outlet,

  /// Angle ou jonction mur et plafond plus froid : pont thermique.
  thermalBridge,

  /// Plafond froid sous des combles.
  ceiling,

  /// Coffre de volet roulant.
  shutterBox,
}

/// Préconisation : clé de texte et matériel à acheter, traduits à l'affichage.
enum ThermalFix {
  sealWindow,
  doorSweep,
  airtightBox,
  insulateWall,
  insulateAttic,
  insulateShutterBox,
}

ThermalFix fixFor(ThermalIssue pIssue) => switch (pIssue) {
  ThermalIssue.windowFrame => ThermalFix.sealWindow,
  ThermalIssue.doorGap => ThermalFix.doorSweep,
  ThermalIssue.outlet => ThermalFix.airtightBox,
  ThermalIssue.thermalBridge => ThermalFix.insulateWall,
  ThermalIssue.ceiling => ThermalFix.insulateAttic,
  ThermalIssue.shutterBox => ThermalFix.insulateShutterBox,
};

/// Une reprise seule suffit pour les petits défauts ; une isolation demande souvent un devis.
bool needsQuote(ThermalIssue pIssue) =>
    pIssue == ThermalIssue.thermalBridge || pIssue == ThermalIssue.ceiling;

/// Écart de température qui mérite d'être noté : au-delà, la zone est nettement plus froide.
const notableGapCelsius = 3.0;

/// Le relevé est significatif si la zone est plus froide que le mur voisin d'au moins 3 °C.
bool isNotable(double pSpotCelsius, double pWallCelsius) =>
    pWallCelsius - pSpotCelsius >= notableGapCelsius;

/// Écart minimal entre dedans et dehors pour qu'une image thermique se lise : en dessous, les
/// parois froides ne ressortent pas assez.
const minThermalGapCelsius = 10.0;

/// Facteur de température en dessous duquel la paroi risque de moisir avec une humidité courante.
const mouldFactor = 0.7;

/// Ce que dit la zone froide, du plus léger au plus grave.
enum ThermalSeverity { none, mild, mouldRisk, condensation }

/// Lecture des températures relevées sur l'image : facteur de température et gravité.
typedef ThermalReading = ({double factor, ThermalSeverity severity});

/// Facteur de température de la zone : 1 quand elle est à la température de la pièce, 0 quand
/// elle est à celle du dehors. Il ne dépend pas du temps qu'il fait le jour du relevé.
double temperatureFactor(double pSpotC, double pInsideC, double pOutsideC) =>
    (pSpotC - pOutsideC) / (pInsideC - pOutsideC);

/// Lit un relevé : null si l'écart entre dedans et dehors est trop faible pour conclure.
///
/// Avec l'humidité de la pièce, une zone sous le point de rosée condense déjà.
ThermalReading? readThermal({
  required double spotC,
  required double wallC,
  required double insideC,
  required double outsideC,
  double? humidityPercent,
}) {
  if (insideC - outsideC < minThermalGapCelsius) {
    return null;
  }
  final vFactor = temperatureFactor(spotC, insideC, outsideC);
  final vWet = humidityPercent != null && spotC <= dewPoint(insideC, humidityPercent);
  final vSeverity = vWet
      ? ThermalSeverity.condensation
      : vFactor < mouldFactor
      ? ThermalSeverity.mouldRisk
      : isNotable(spotC, wallC)
      ? ThermalSeverity.mild
      : ThermalSeverity.none;
  final rReading = (factor: vFactor, severity: vSeverity);

  return rReading;
}
