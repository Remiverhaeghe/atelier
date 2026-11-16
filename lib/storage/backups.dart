/// Sauvegardes datées des chantiers : une copie par jour, les plus anciennes effacées.
library;

import 'dart:io';

/// Une sauvegarde : son jour et son fichier.
typedef Backup = ({String day, File file});

/// Copies quotidiennes du fichier des chantiers dans [folder], [keep] jours gardés.
class Backups {
  Backups(this.folder, {this.keep = 14, DateTime Function()? pNow}) : _now = pNow ?? DateTime.now;

  final Directory folder;
  final int keep;
  final DateTime Function() _now;

  static final _name = RegExp(r'^chantiers-(\d{4}-\d{2}-\d{2})\.json$');

  static String _day(DateTime pDay) =>
      '${pDay.year.toString().padLeft(4, '0')}-${pDay.month.toString().padLeft(2, '0')}-'
      '${pDay.day.toString().padLeft(2, '0')}';

  /// Sauvegardes présentes, de la plus récente à la plus ancienne.
  List<Backup> list() {
    if (!folder.existsSync()) {
      return const [];
    }
    final rBackups = [
      for (final vFile in folder.listSync().whereType<File>())
        if (_name.firstMatch(vFile.uri.pathSegments.last) case final vMatch?)
          (day: vMatch.group(1)!, file: vFile),
    ]..sort((pA, pB) => pB.day.compareTo(pA.day));

    return rBackups;
  }

  /// Copie [pContent] comme sauvegarde du jour, une seule fois par jour, puis fait le ménage.
  Future<void> record(String pContent) async {
    final vToday = File('${folder.path}/chantiers-${_day(_now())}.json');
    if (vToday.existsSync()) {
      return;
    }
    await folder.create(recursive: true);
    await vToday.writeAsString(pContent, flush: true);
    for (final vOld in list().skip(keep)) {
      await vOld.file.delete();
    }
  }
}
