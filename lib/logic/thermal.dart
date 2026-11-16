/// Relevés de caméra thermique : zone froide repérée, préconisation et matériel à prévoir.
library;

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
