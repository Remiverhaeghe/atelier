/// Recherche dans toute l'appli : sans accent ni majuscule, chaque mot cherché doit se trouver
/// dans le titre ou le détail.
library;

const _aAccents = 'àâäçéèêëîïôöùûüÿ';
const _aPlain = 'aaaceeeeiioouuuy';

/// Texte en minuscules, sans accent : « Plâtre » et « platre » se retrouvent.
String plainText(String pText) {
  final vBuffer = StringBuffer();
  for (final vChar in pText.toLowerCase().replaceAll('œ', 'oe').split('')) {
    final vIndex = _aAccents.indexOf(vChar);
    vBuffer.write(vIndex < 0 ? vChar : _aPlain[vIndex]);
  }

  return vBuffer.toString();
}

/// Élément cherchable : [key] permet à l'écran de savoir quoi ouvrir.
typedef SearchItem<T> = ({String title, String detail, T key});

/// Éléments dont chaque mot de [pQuery] se trouve dans le titre ou le détail ; ceux qui ont
/// tout dans le titre d'abord, puis dans l'ordre reçu.
List<SearchItem<T>> searchItems<T>(String pQuery, List<SearchItem<T>> pItems) {
  final vWords = plainText(pQuery).split(RegExp(r'\s+')).where((pWord) => pWord.isNotEmpty);
  if (vWords.isEmpty) {
    return const [];
  }
  final vInTitle = <SearchItem<T>>[];
  final vInDetail = <SearchItem<T>>[];
  for (final vItem in pItems) {
    final vTitle = plainText(vItem.title);
    final vAll = '$vTitle ${plainText(vItem.detail)}';
    if (vWords.every(vTitle.contains)) {
      vInTitle.add(vItem);
    } else if (vWords.every(vAll.contains)) {
      vInDetail.add(vItem);
    }
  }

  return [...vInTitle, ...vInDetail];
}
