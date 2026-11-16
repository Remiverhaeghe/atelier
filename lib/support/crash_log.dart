/// Journal local des plantages, sans envoi automatique : l'utilisateur le partage s'il le veut.
library;

import 'dart:io';

class CrashLog {
  CrashLog(this.file, {this.maxLines = 300, DateTime Function()? pNow})
    : now = pNow ?? DateTime.now;

  final File file;

  /// Les lignes les plus anciennes sont retirées au-delà de cette limite.
  final int maxLines;
  final DateTime Function() now;

  /// Ajoute une erreur et sa pile ; ne lève jamais, un journal ne doit pas faire planter l'application.
  void record(Object pError, StackTrace? pStack) {
    try {
      final vLines = file.existsSync() ? file.readAsLinesSync() : <String>[];
      vLines
        ..add('${now().toIso8601String()} $pError')
        ..addAll(
          (pStack?.toString() ?? '').split('\n').where((pLine) => pLine.trim().isNotEmpty).take(20),
        );
      final vKept = vLines.length > maxLines ? vLines.sublist(vLines.length - maxLines) : vLines;
      file.parent.createSync(recursive: true);
      file.writeAsStringSync('${vKept.join('\n')}\n');
    } on FileSystemException {
      // Disque plein ou inaccessible : on renonce au journal.
    }
  }

  String read() => file.existsSync() ? file.readAsStringSync() : '';
}
