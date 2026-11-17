/// Écran « Nouveautés » : montré une fois après une mise à jour qui apporte du nouveau.
library;

/// Numéro des nouveautés : l'augmenter avec une version qui mérite d'être présentée, et
/// réécrire les lignes `newsLines` du fichier de textes.
const newsVersion = 1;

/// À montrer si l'on n'a pas vu ces nouveautés et qu'on avait déjà des chantiers : une
/// première installation n'a rien de « nouveau » à découvrir.
bool shouldShowNews({required int pSeen, required bool pHasData}) =>
    pHasData && pSeen < newsVersion;
