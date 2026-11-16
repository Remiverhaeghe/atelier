import 'package:atelier/logic/data_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('format courant ou sans numéro : rien à faire', () {
    expect(upgradeFormat({'formatVersion': currentFormat, 'worksites': []})['worksites'], []);
    expect(upgradeFormat({'worksites': []})['worksites'], []);
  });

  test('chaque étape s\'applique dans l\'ordre jusqu\'à la version courante', () {
    final vJson = upgradeFormat(
      {'formatVersion': 1, 'worksites': [], 'unite': 'cm'},
      pCurrent: 3,
      pSteps: {
        1: (pJson) => {...pJson, 'unite': 'mm'},
        2: (pJson) => {...pJson, 'etapes': '${pJson['unite']} puis 3'},
      },
    );
    expect(vJson['formatVersion'], 3);
    expect(vJson['etapes'], 'mm puis 3');
  });

  test('version plus récente refusée, étape manquante signalée', () {
    expect(
      () => upgradeFormat({'formatVersion': currentFormat + 1}),
      throwsA(isA<NewerFormatException>()),
    );
    expect(
      () => upgradeFormat({'formatVersion': 1}, pCurrent: 2),
      throwsA(isA<FormatException>().having((pError) => pError.message, 'message', contains('1'))),
    );
  });
}
