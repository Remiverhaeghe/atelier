/// Projet complet dans un seul fichier : le chantier (croquis, débit, notes) et ses photos, à
/// chiffrer avant de le partager.
library;

import 'dart:convert';

/// Marque du fichier, pour le reconnaître à l'import.
const projectBundleFormat = 'atelier-projet';
const projectBundleVersion = 1;

/// Photos, factures et tickets rangés dans le JSON des chantiers : les clés qui finissent par
/// « Path » (photoPath, beforePath, invoicePath, receiptPath).
Set<String> attachedPaths(Object? pJson) {
  final rPaths = <String>{};
  void vWalk(Object? pNode) {
    if (pNode is Map<String, Object?>) {
      for (final vEntry in pNode.entries) {
        final vValue = vEntry.value;
        if (vEntry.key.endsWith('Path') && vValue is String) {
          rPaths.add(vValue);
        } else {
          vWalk(vValue);
        }
      }
    } else if (pNode is List<Object?>) {
      pNode.forEach(vWalk);
    }
  }

  vWalk(pJson);

  return rPaths;
}

/// Remplace les chemins de [pMoves] dans le JSON des chantiers, une fois les photos recopiées
/// sur le téléphone qui reçoit le projet.
Object? relocatePaths(Object? pJson, Map<String, String> pMoves) {
  final rJson = switch (pJson) {
    final Map<String, Object?> vMap => {
      for (final vEntry in vMap.entries)
        vEntry.key: vEntry.key.endsWith('Path') && vEntry.value is String
            ? pMoves[vEntry.value] ?? vEntry.value
            : relocatePaths(vEntry.value, pMoves),
    },
    final List<Object?> vList => [for (final vItem in vList) relocatePaths(vItem, pMoves)],
    _ => pJson,
  };

  return rJson;
}

/// Nom du fichier recopié : le nom d'origine, précédé de [pStamp] pour ne rien écraser.
String importedName(String pOldPath, String pStamp) {
  final vName = pOldPath.split(RegExp(r'[\\/]')).last;
  final rName = '$pStamp-${vName.replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')}';

  return rName;
}

/// Réunit le JSON des chantiers et le contenu des fichiers joints, rangés par chemin.
String encodeProjectBundle(String pWorksitesJson, Map<String, List<int>> pFiles) {
  final rText = jsonEncode({
    'format': projectBundleFormat,
    'version': projectBundleVersion,
    'worksites': jsonDecode(pWorksitesJson),
    'files': {for (final vEntry in pFiles.entries) vEntry.key: base64Encode(vEntry.value)},
  });

  return rText;
}

Map<String, Object?>? _bundle(String pText) {
  try {
    final vRaw = jsonDecode(pText);
    if (vRaw is Map<String, Object?> && vRaw['format'] == projectBundleFormat) {
      return vRaw;
    }
  } on FormatException {
    return null;
  }

  return null;
}

bool isProjectBundle(String pText) => _bundle(pText) != null;

/// Sépare un projet complet en JSON des chantiers et fichiers joints ; lève FormatException
/// s'il n'est pas reconnu.
({Object? worksites, Map<String, List<int>> files}) decodeProjectBundle(String pText) {
  final vBundle = _bundle(pText);
  final vFiles = vBundle?['files'];
  if (vBundle == null || vFiles is! Map<String, Object?>) {
    throw const FormatException('Projet non reconnu');
  }
  final rBundle = (
    worksites: vBundle['worksites'],
    files: {
      for (final vEntry in vFiles.entries)
        if (vEntry.value is String) vEntry.key: base64Decode(vEntry.value! as String),
    },
  );

  return rBundle;
}
