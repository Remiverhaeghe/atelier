/// Conversions entre la saisie (centimètres, virgule ou point) et les millimètres du calcul.
library;

/// Lit une longueur saisie en centimètres (« 245,5 » ou « 245.5 ») ; null si invalide ou négative.
///
/// Une unité tapée à la suite passe avant : « 2,45 m » et « 2450 mm » donnent aussi 2450.
int? parseCentimetres(String pText) {
  final vTyped = typedLengthMm(pText);
  if (vTyped != null) {
    return vTyped;
  }
  final vText = pText.trim().replaceAll(' ', '').replaceAll(',', '.');
  final vValue = double.tryParse(vText);
  if (vValue == null || vValue < 0 || vValue.isNaN || vValue.isInfinite) {
    return null;
  }
  final rMillimetres = (vValue * 10).round();

  return rMillimetres;
}

/// Unité d'un champ de saisie, lue entre parenthèses dans son libellé : « Hauteur (cm) ».
enum FieldUnit { mm, cm, m, m2, m3 }

final _aUnitInLabel = RegExp(r'\((mm|cm|m|m²|m³)[),\s]');

/// Unité annoncée par le libellé d'un champ, ou null s'il n'en annonce pas.
FieldUnit? unitOfLabel(String pLabel) {
  final rUnit = switch (_aUnitInLabel.firstMatch(pLabel)?.group(1)) {
    'mm' => FieldUnit.mm,
    'cm' => FieldUnit.cm,
    'm' => FieldUnit.m,
    'm²' => FieldUnit.m2,
    'm³' => FieldUnit.m3,
    _ => null,
  };

  return rUnit;
}

bool isLengthUnit(FieldUnit pUnit) =>
    pUnit == FieldUnit.mm || pUnit == FieldUnit.cm || pUnit == FieldUnit.m;

final _aTypedLength = RegExp(r'^(\d+(?:[.,]\d+)?)\s*(mm|cm|m)$');

/// Longueur tapée avec son unité (« 2,45 m », « 245 cm », « 2450mm ») ; null sans unité.
int? typedLengthMm(String pText) {
  final vMatch = _aTypedLength.firstMatch(pText.trim().toLowerCase().replaceAll(' ', ''));
  if (vMatch == null) {
    return null;
  }
  final vValue = double.parse(vMatch.group(1)!.replaceAll(',', '.'));
  final rMillimetres = switch (vMatch.group(2)) {
    'mm' => vValue,
    'cm' => vValue * 10,
    _ => vValue * 1000,
  }.round();

  return rMillimetres;
}

/// Longueur en millimètres écrite dans l'unité du champ : 2450 donne « 245 » en cm, « 2,45 » en m.
String lengthInUnit(int pMillimetres, FieldUnit pUnit) {
  final rText = switch (pUnit) {
    FieldUnit.mm => '$pMillimetres',
    FieldUnit.m =>
      (pMillimetres / 1000)
          .toStringAsFixed(3)
          .replaceFirst(RegExp(r'0+$'), '')
          .replaceFirst(RegExp(r'\.$'), '')
          .replaceAll('.', aDecimalSeparator),
    _ => formatCentimetres(pMillimetres),
  };

  return rText;
}

/// Longueur saisie dans [pUnit] (mm, cm ou m) ; une unité tapée à la suite passe avant.
int? parseInUnit(String pText, FieldUnit pUnit) {
  final vText = pText.trim();
  final rMillimetres = vText.isEmpty
      ? null
      : typedLengthMm(vText) ?? typedLengthMm('$vText${pUnit.name}');

  return rMillimetres;
}

/// Saisie ramenée à l'unité du champ : « 2,45 m » dans un champ en cm devient « 245 ».
///
/// Le texte est rendu tel quel s'il n'a pas d'unité ou si le champ n'attend pas une longueur.
String toFieldUnit(String pText, FieldUnit? pUnit) {
  final vMillimetres = typedLengthMm(pText);
  final rText = pUnit == null || !isLengthUnit(pUnit) || vMillimetres == null
      ? pText
      : lengthInUnit(vMillimetres, pUnit);

  return rText;
}

/// Lit un angle en degrés, entre 1 et 359 ; null sinon.
double? parseDegrees(String pText) {
  final vValue = double.tryParse(pText.trim().replaceAll(',', '.'));
  if (vValue == null || vValue <= 0 || vValue >= 360) {
    return null;
  }

  return vValue;
}

/// Séparateur décimal affiché : virgule en français, point en anglais. L'appli le règle
/// d'après la langue de l'écran ; la saisie accepte les deux.
var aDecimalSeparator = ',';

/// Affiche des millimètres en centimètres, sans zéro inutile : 2455 donne « 245,5 ».
String formatCentimetres(int pMillimetres) {
  final vWhole = pMillimetres ~/ 10;
  final vTenth = (pMillimetres % 10).abs();
  final rText = vTenth == 0 ? '$vWhole' : '$vWhole$aDecimalSeparator$vTenth';

  return rText;
}

/// Affiche une surface en mètres carrés avec deux décimales : « 12,35 ».
String formatSquareMetres(double pSquareMetres) {
  final rText = pSquareMetres.toStringAsFixed(2).replaceAll('.', aDecimalSeparator);

  return rText;
}

/// Lit un nombre positif à virgule (« 2,13 ») ; null si invalide.
double? parseDecimal(String pText) {
  final vValue = double.tryParse(pText.trim().replaceAll(' ', '').replaceAll(',', '.'));
  if (vValue == null || vValue < 0 || vValue.isNaN || vValue.isInfinite) {
    return null;
  }

  return vValue;
}

/// Lit un nombre qui peut être négatif (« -2,5 » pour une température) ; null si invalide.
double? parseSignedDecimal(String pText) {
  final vText = pText.trim().replaceAll(' ', '').replaceAll('−', '-');
  final vNegative = vText.startsWith('-');
  final vValue = parseDecimal(vNegative ? vText.substring(1) : vText);
  final rValue = vValue == null ? null : (vNegative ? -vValue : vValue);

  return rValue;
}

/// Lit un entier positif ; null si invalide.
int? parseWhole(String pText) {
  final vValue = int.tryParse(pText.trim().replaceAll(' ', ''));
  if (vValue == null || vValue < 0) {
    return null;
  }

  return vValue;
}

/// Affiche un nombre à virgule sans zéro inutile : 2.13 donne « 2,13 », 15.0 donne « 15 ».
String formatDecimal(double pValue) {
  var vText = pValue.toStringAsFixed(2);
  vText = vText.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
  final rText = vText.replaceAll('.', aDecimalSeparator);

  return rText;
}
