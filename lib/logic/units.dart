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

/// Affiche des millimètres en centimètres, sans zéro inutile : 2455 donne « 245,5 ».
String formatCentimetres(int pMillimetres) {
  final vWhole = pMillimetres ~/ 10;
  final vTenth = (pMillimetres % 10).abs();
  final rText = vTenth == 0 ? '$vWhole' : '$vWhole,$vTenth';

  return rText;
}

/// Affiche une surface en mètres carrés avec deux décimales : « 12,35 ».
String formatSquareMetres(double pSquareMetres) {
  final rText = pSquareMetres.toStringAsFixed(2).replaceAll('.', ',');

  return rText;
}
