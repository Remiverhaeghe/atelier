import 'dart:io';

import 'package:atelier/support/crash_log.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory vFolder;

  setUp(() => vFolder = Directory.systemTemp.createTempSync('atelier_'));
  tearDown(() => vFolder.deleteSync(recursive: true));

  test('une erreur est écrite avec sa date et sa pile', () {
    final vLog = CrashLog(
      File('${vFolder.path}/logs/plantages.txt'),
      pNow: () => DateTime(2026, 11, 16, 10, 30),
    );

    vLog.record(StateError('panne'), StackTrace.fromString('#0 main\n#1 run'));

    expect(vLog.read(), startsWith('2026-11-16T10:30:00.000 Bad state: panne\n#0 main\n#1 run'));
  });

  test('les lignes les plus anciennes sont retirées au-delà de la limite', () {
    final vLog = CrashLog(File('${vFolder.path}/plantages.txt'), maxLines: 3);

    for (var vIndex = 0; vIndex < 5; vIndex++) {
      vLog.record('erreur $vIndex', null);
    }

    final vLines = vLog.read().trim().split('\n');
    expect(vLines, hasLength(3));
    expect(vLines.last, endsWith('erreur 4'));
  });

  test('sans fichier, le journal est vide', () {
    expect(CrashLog(File('${vFolder.path}/absent.txt')).read(), isEmpty);
  });
}
