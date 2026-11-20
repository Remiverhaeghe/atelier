import 'dart:convert';

import 'package:share_plus/share_plus.dart';

/// Partage un fichier texte construit en mémoire : même chemin sur le téléphone et dans Safari,
/// sans dossier temporaire (la version web n'en a pas).
Future<void> shareTextFile(String pName, String pContent, {String pMime = 'application/json'}) =>
    SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(utf8.encode(pContent), name: pName, mimeType: pMime)],
        fileNameOverrides: [pName],
      ),
    );
