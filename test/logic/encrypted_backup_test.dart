import 'dart:convert';
import 'dart:math';

import 'package:atelier/logic/encrypted_backup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const vClear = '{"worksites":[{"id":"w","name":"Maison démo"}]}';
  const vPassword = 'mot-de-passe-de-test';

  test('chiffré puis déchiffré : le même texte, illisible entre les deux', () async {
    final vEnvelope = await encryptBackup(vClear, vPassword, pIterations: 1000, pRandom: Random(7));

    expect(isEncryptedBackup(vEnvelope), isTrue);
    expect(vEnvelope, isNot(contains('Maison')));
    expect((jsonDecode(vEnvelope) as Map)['iterations'], 1000);
    expect(await decryptBackup(vEnvelope, vPassword), vClear);
  });

  test('mauvais mot de passe ou fichier abîmé : refusé', () async {
    final vEnvelope = await encryptBackup(vClear, vPassword, pIterations: 1000, pRandom: Random(7));
    final vJson = jsonDecode(vEnvelope) as Map<String, Object?>;
    final vBroken = jsonEncode({...vJson, 'data': base64Encode([1, 2, 3])});
    final vData = base64Decode(vJson['data']! as String)..[0] ^= 1;
    final vTampered = jsonEncode({...vJson, 'data': base64Encode(vData)});

    expect(decryptBackup(vEnvelope, 'autre-mot-de-passe'), throwsA(isA<WrongPasswordException>()));
    expect(decryptBackup(vBroken, vPassword), throwsA(isA<WrongPasswordException>()));
    expect(decryptBackup(vTampered, vPassword), throwsA(isA<WrongPasswordException>()));
  });

  test('une sauvegarde en clair n\'est pas prise pour une chiffrée', () {
    expect(isEncryptedBackup(vClear), isFalse);
    expect(isEncryptedBackup('pas du JSON'), isFalse);
  });
}
