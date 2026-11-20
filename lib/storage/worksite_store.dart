/// Enregistrement des chantiers dans un fichier JSON du téléphone.
library;

import 'dart:convert';
import 'dart:io';

import '../logic/data_format.dart';
import '../logic/workshop_stock.dart';
import '../logic/worksite.dart';
import 'backups.dart';

/// Lecture et écriture de tous les chantiers ; remplacée par une version en mémoire dans les tests.
abstract interface class WorksiteStorage {
  Future<List<Worksite>> load();

  Future<void> save(List<Worksite> pWorksites);
}

/// Lit et écrit tous les chantiers dans un seul fichier, réécrit en entier à chaque changement.
class WorksiteStore implements WorksiteStorage {
  WorksiteStore(this.file, {this.backups});

  final File file;

  /// Copie du jour gardée à part : une fausse manipulation se rattrape le lendemain.
  final Backups? backups;

  /// Version du format, pour pouvoir le faire évoluer sans perdre de chantier.
  static const formatVersion = currentFormat;

  @override
  Future<List<Worksite>> load() async {
    if (!file.existsSync()) {
      return const [];
    }
    final vText = await file.readAsString();
    try {
      final rWorksites = decode(vText);

      return rWorksites;
    } on FormatException {
      // Copie gardée à part : si l'on continue et qu'on enregistre, l'original n'est pas perdu
      await File('${file.path}.illisible').writeAsString(vText, flush: true);
      rethrow;
    }
  }

  @override
  Future<void> save(List<Worksite> pWorksites) async {
    await file.parent.create(recursive: true);
    // Écriture dans un fichier temporaire puis renommage : un arrêt brutal ne laisse pas un fichier coupé.
    final vTemporary = File('${file.path}.tmp');
    final vContent = encode(pWorksites);
    await vTemporary.writeAsString(vContent, flush: true);
    await vTemporary.rename(file.path);
    await backups?.record(vContent);
  }

  /// [pWorkshop] : stock de l'atelier, ajouté seulement aux sauvegardes complètes.
  static String encode(List<Worksite> pWorksites, {List<StockItem>? pWorkshop}) {
    final rText = const JsonEncoder.withIndent('  ').convert({
      'formatVersion': formatVersion,
      'worksites': [for (final vWorksite in pWorksites) vWorksite.toJson()],
      if (pWorkshop != null) 'workshop': stockToJson(pWorkshop),
    });

    return rText;
  }

  /// Stock de l'atelier d'une sauvegarde complète, ou null si le fichier n'en contient pas.
  static List<StockItem>? decodeWorkshop(String pText) {
    final vRaw = jsonDecode(pText);
    if (vRaw is! Map<String, Object?> || vRaw['workshop'] == null) {
      return null;
    }
    final rItems = stockFromJson(vRaw['workshop']);

    return rItems;
  }

  /// Lit un contenu exporté ; lève FormatException s'il n'est pas reconnu.
  static List<Worksite> decode(String pText) {
    final vRaw = jsonDecode(pText);
    if (vRaw is! Map<String, Object?> || vRaw['worksites'] is! List<Object?>) {
      throw const FormatException('Fichier de chantiers non reconnu');
    }
    final vJson = upgradeFormat(vRaw);
    final rWorksites = [
      for (final vWorksite in vJson['worksites']! as List<Object?>)
        Worksite.fromJson(vWorksite! as Map<String, Object?>),
    ];

    return rWorksites;
  }
}
