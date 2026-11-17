/// Sauvegarde chiffrée par mot de passe, pour garder les chantiers hors du téléphone sans
/// les laisser lisibles : AES-256-GCM, clé tirée du mot de passe par PBKDF2-HMAC-SHA256.
library;

import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

/// Marque du fichier chiffré, pour le reconnaître à l'import.
const encryptedFormat = 'atelier-chiffre';

/// Itérations de PBKDF2 : assez pour ralentir un essai de mots de passe, une seconde environ
/// sur un téléphone.
const defaultIterations = 210000;

/// Longueur minimale du mot de passe demandé.
const minPasswordLength = 8;

class WrongPasswordException implements Exception {
  const WrongPasswordException();
}

/// Le texte est-il une sauvegarde chiffrée par l'appli ?
bool isEncryptedBackup(String pText) {
  try {
    final vJson = jsonDecode(pText);
    return vJson is Map<String, Object?> && vJson['format'] == encryptedFormat;
  } on FormatException {
    return false;
  }
}

Future<SecretKey> _key(String pPassword, List<int> pSalt, int pIterations) => Pbkdf2(
  macAlgorithm: Hmac.sha256(),
  iterations: pIterations,
  bits: 256,
).deriveKeyFromPassword(password: pPassword, nonce: pSalt);

/// Chiffre [pClear] avec [pPassword] ; [pRandom] fixe le sel et le nonce dans les tests.
Future<String> encryptBackup(
  String pClear,
  String pPassword, {
  int pIterations = defaultIterations,
  Random? pRandom,
}) async {
  final vRandom = pRandom ?? Random.secure();
  final vSalt = [for (var vIndex = 0; vIndex < 16; vIndex++) vRandom.nextInt(256)];
  final vNonce = [for (var vIndex = 0; vIndex < 12; vIndex++) vRandom.nextInt(256)];
  final vBox = await AesGcm.with256bits().encrypt(
    utf8.encode(pClear),
    secretKey: await _key(pPassword, vSalt, pIterations),
    nonce: vNonce,
  );
  final rEnvelope = jsonEncode({
    'format': encryptedFormat,
    'version': 1,
    'kdf': 'pbkdf2-hmac-sha256',
    'iterations': pIterations,
    'salt': base64Encode(vSalt),
    'nonce': base64Encode(vNonce),
    'data': base64Encode([...vBox.cipherText, ...vBox.mac.bytes]),
  });

  return rEnvelope;
}

/// Déchiffre une sauvegarde ; un mauvais mot de passe ou un fichier abîmé lève
/// [WrongPasswordException].
Future<String> decryptBackup(String pEnvelope, String pPassword) async {
  final vJson = jsonDecode(pEnvelope) as Map<String, Object?>;
  final vSalt = base64Decode(vJson['salt']! as String);
  final vNonce = base64Decode(vJson['nonce']! as String);
  final vData = base64Decode(vJson['data']! as String);
  if (vData.length < 16) {
    throw const WrongPasswordException();
  }
  final vBox = SecretBox(
    vData.sublist(0, vData.length - 16),
    nonce: vNonce,
    mac: Mac(vData.sublist(vData.length - 16)),
  );
  try {
    final vClear = await AesGcm.with256bits().decrypt(
      vBox,
      secretKey: await _key(pPassword, vSalt, vJson['iterations']! as int),
    );
    return utf8.decode(vClear);
  } on SecretBoxAuthenticationError {
    throw const WrongPasswordException();
  }
}
