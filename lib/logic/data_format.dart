/// Format du fichier des chantiers : version, et passage d'une version à la suivante.
library;

/// Version écrite par cette appli. L'augmenter, c'est ajouter l'étape qui y mène.
const currentFormat = 1;

/// Étape de migration : reçoit le contenu dans la version N et le rend dans la version N + 1.
typedef FormatStep = Map<String, Object?> Function(Map<String, Object?> pJson);

/// Étapes connues, par version de départ. Vide tant que le format n'a pas changé.
const formatSteps = <int, FormatStep>{};

/// Fichier écrit par une version plus récente de l'appli : le lire ici en perdrait une partie.
class NewerFormatException extends FormatException {
  const NewerFormatException(int pVersion)
    : super('Fichier au format $pVersion, plus récent que cette version de l\'appli');
}

/// Contenu remis à la version courante, étape par étape. Un fichier sans numéro date d'avant
/// la numérotation : c'est la version 1.
Map<String, Object?> upgradeFormat(
  Map<String, Object?> pJson, {
  int pCurrent = currentFormat,
  Map<int, FormatStep> pSteps = formatSteps,
}) {
  var vVersion = (pJson['formatVersion'] as int?) ?? 1;
  if (vVersion > pCurrent) {
    throw NewerFormatException(vVersion);
  }
  var rJson = pJson;
  while (vVersion < pCurrent) {
    final vStep = pSteps[vVersion];
    if (vStep == null) {
      throw FormatException('Pas de migration depuis le format $vVersion');
    }
    rJson = {...vStep(rJson), 'formatVersion': vVersion + 1};
    vVersion++;
  }

  return rJson;
}
