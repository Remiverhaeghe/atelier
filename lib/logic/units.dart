/// Conversions entre la saisie (centimètres, virgule ou point) et les millimètres du calcul.
library;

/// Lit une longueur saisie en centimètres (« 245,5 » ou « 245.5 ») ; null si invalide ou négative.
int? parseCentimetres(String pText) {
  final vText = pText.trim().replaceAll(' ', '').replaceAll(',', '.');
  final vValue = double.tryParse(vText);
  if (vValue == null || vValue < 0 || vValue.isNaN || vValue.isInfinite) {
    return null;
  }
  final rMillimetres = (vValue * 10).round();

  return rMillimetres;
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
