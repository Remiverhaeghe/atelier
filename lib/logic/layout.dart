/// Mise en page selon la largeur : téléphone en portrait, en paysage ou tablette.
library;

/// Largeur à partir de laquelle on met le plan et la liste côte à côte (classe « étendue » de
/// Material 3).
const wideLayoutDp = 840.0;

bool isWideWidth(double pWidthDp) => pWidthDp >= wideLayoutDp;

/// Nombre de colonnes d'une grille de tuiles d'environ [pTileDp] de large, entre [pMin] et
/// [pMax].
int gridColumns(double pWidthDp, double pTileDp, {int pMin = 1, int pMax = 8}) {
  final vColumns = pTileDp <= 0 ? pMin : (pWidthDp / pTileDp).floor();

  return vColumns.clamp(pMin, pMax);
}
