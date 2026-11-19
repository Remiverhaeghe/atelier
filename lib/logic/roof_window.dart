/// Remplacer un plexi (ou ouvrir le toit) par une fenêtre de toit : quelle largeur passe
/// entre les chevrons, quand faut-il un chevêtre, quelle hauteur selon la pente.
library;

/// Largeurs et hauteurs de fenêtres de toit vendues couramment, en mm hors tout.
const roofWindowWidthsMm = [550, 660, 780, 940, 1140, 1340];
const roofWindowHeightsMm = [780, 980, 1180, 1400, 1600];

/// Jeu de pose de chaque côté de la fenêtre, pour le raccord d'étanchéité et l'isolant.
const roofWindowGapMm = 30;

/// Couverture : le raccord d'étanchéité n'est pas le même.
enum RoofCover {
  /// Tuiles mécaniques ou romanes, en relief.
  profiledTiles,

  /// Ardoises, tuiles plates, bardeaux : matériaux plats.
  flat,
}

typedef RoofWindowFit = ({
  /// Vide entre deux chevrons.
  int clearWidthMm,

  /// Fenêtre la plus large qui passe sans toucher aux chevrons.
  int? widestWithoutCutMm,

  /// Fenêtre retenue : la plus étroite qui couvre la largeur voulue.
  int? chosenWidthMm,

  /// Il faut couper un chevron et poser un chevêtre pour la largeur voulue.
  bool needsHeader,
  int heightMm,
});

/// Fenêtre pour une ouverture de [pWantedWidthMm] entre chevrons de [pRafterWidthMm] posés
/// tous les [pSpacingMm], sur un toit de [pSlopeDeg].
RoofWindowFit fitRoofWindow({
  required int pSpacingMm,
  required int pRafterWidthMm,
  required int pWantedWidthMm,
  required double pSlopeDeg,
}) {
  final vClear = pSpacingMm - pRafterWidthMm;
  int? vWidest(int pClear) =>
      roofWindowWidthsMm.where((pWidth) => pWidth + 2 * roofWindowGapMm <= pClear).lastOrNull;
  final vWithout = vWidest(vClear);
  final vFits = roofWindowWidthsMm
      .where((pWidth) => pWidth >= pWantedWidthMm && pWidth + 2 * roofWindowGapMm <= vClear)
      .firstOrNull;
  // Un chevron coupé : le vide passe à deux entraxes moins un chevron
  final vWithHeader = roofWindowWidthsMm
      .where(
        (pWidth) =>
            pWidth >= pWantedWidthMm &&
            pWidth + 2 * roofWindowGapMm <= 2 * pSpacingMm - pRafterWidthMm,
      )
      .firstOrNull;
  // Plus le toit est couché, plus la fenêtre doit être haute pour voir dehors
  final vHeight = pSlopeDeg < 30 ? 1400 : (pSlopeDeg <= 45 ? 1180 : 980);
  final rFit = (
    clearWidthMm: vClear,
    widestWithoutCutMm: vWithout,
    chosenWidthMm: vFits ?? vWithHeader,
    needsHeader: vFits == null && vWithHeader != null,
    heightMm: vHeight,
  );

  return rFit;
}

/// Largeur du dormant selon la lettre de la référence (CK04 : C), en millimètres.
const _referenceWidthsMm = {'B': 470, 'C': 550, 'F': 660, 'M': 780, 'P': 940, 'S': 1140, 'U': 1340};

/// Hauteur selon les deux chiffres de la référence (CK04 : 04).
const _referenceHeightsMm = {
  '01': 700,
  '02': 780,
  '04': 980,
  '06': 1180,
  '08': 1400,
  '10': 1600,
  '12': 1800,
};

/// Lettre de largeur des anciennes références à trois chiffres (308 : M08).
const _oldReferenceLetters = {'1': 'C', '2': 'F', '3': 'M', '4': 'P', '6': 'S', '8': 'U'};

/// Dimensions extérieures du dormant d'une fenêtre de toit d'après la référence de taille
/// gravée sur sa plaque : « MK08 », « M08 », « GGL MK08 » ou l'ancienne « 308 ». Null si la
/// référence n'est pas reconnue.
({int widthMm, int heightMm, String code})? roofWindowFromReference(String pReference) {
  final vText = pReference.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
  String? vLetter;
  String? vDigits;
  final vModern = RegExp(r'([BCFMPSU])[A-Z]?(\d{2})$').firstMatch(vText);
  final vOld = RegExp(r'^(?:[A-Z]*)([123468])(\d{2})$').firstMatch(vText);
  if (vModern != null) {
    vLetter = vModern.group(1);
    vDigits = vModern.group(2);
  } else if (vOld != null) {
    vLetter = _oldReferenceLetters[vOld.group(1)];
    vDigits = vOld.group(2);
  }
  final vWidth = _referenceWidthsMm[vLetter];
  final vHeight = _referenceHeightsMm[vDigits];
  final rWindow = vWidth == null || vHeight == null
      ? null
      : (widthMm: vWidth, heightMm: vHeight, code: '$vLetter$vDigits');

  return rWindow;
}

/// Code de taille tel qu'il est écrit sur la plaque (MK08, CK04, ou 308 sur un ancien modèle) :
/// c'est lui que demandent les stores et volets. Null si la référence n'est pas reconnue.
String? roofWindowSizeCode(String pReference) {
  if (roofWindowFromReference(pReference) == null) {
    return null;
  }
  final vText = pReference.toUpperCase().replaceAll(RegExp(r'[\s-]'), '');
  final rCode =
      RegExp(r'[BCFMPSU][A-Z]?\d{2}$').firstMatch(vText)?.group(0) ??
      RegExp(r'[123468]\d{2}$').firstMatch(vText)!.group(0);

  return rCode;
}

/// Stores et volets d'une fenêtre de toit : ils se commandent avec le même code de taille que
/// la fenêtre (MK08, par exemple), lu sur sa plaque.
enum RoofWindowAccessory {
  blackout(outside: false, heatBlock: 1),
  pleated(outside: false, heatBlock: 1),
  venetian(outside: false, heatBlock: 1),
  awning(outside: true, heatBlock: 3),
  shutter(outside: true, heatBlock: 3);

  const RoofWindowAccessory({required this.outside, required this.heatBlock});

  /// Posé dehors, devant la vitre.
  final bool outside;

  /// Efficacité contre la chaleur d'été : 1 faible, 3 forte. Un store dehors arrête le soleil
  /// avant la vitre ; dedans, la chaleur est déjà entrée.
  final int heatBlock;
}
