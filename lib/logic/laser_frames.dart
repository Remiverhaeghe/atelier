/// Télémètres laser Bosch en Bluetooth basse consommation (GLM 50 C, GLM 50-27 C et CG,
/// GLM 100 C, GLM 120 C, PLR 30 C, 40 C et 50 C) : commandes et trames de mesure.
///
/// Protocole relevé par la communauté, pas documenté par Bosch : chaque mesure faite sur
/// l'appareil arrive dans une trame qui commence par C0 55, la distance en mètres codée en
/// nombre flottant sur 4 octets, poids faible d'abord, aux octets 7 à 10.
library;

import 'dart:typed_data';

const laserServiceUuid = '02a6c0d0-0451-4000-b000-fb3210111989';
const laserCharacteristicUuid = '02a6c0d1-0451-4000-b000-fb3210111989';

/// Demande à l'appareil d'envoyer chaque mesure faite avec son bouton.
const laserSyncCommand = [0xC0, 0x55, 0x02, 0x01, 0x00, 0x1A];

/// Débuts de nom des appareils proposés à la connexion.
const laserNamePrefixes = ['GLM', 'PLR', 'Bosch'];

bool isLaserName(String pName) => laserNamePrefixes.any(
  (pPrefix) => pName.toUpperCase().startsWith(pPrefix.toUpperCase()),
);

/// Distance d'une trame de mesure, en millimètres ; null pour une autre trame ou une valeur
/// impossible (zéro, négative ou au-delà de 250 m).
int? laserDistanceMm(List<int> pFrame) {
  if (pFrame.length < 11 || pFrame[0] != 0xC0 || pFrame[1] != 0x55) {
    return null;
  }
  final vBytes = Uint8List.fromList(pFrame.sublist(7, 11));
  final vMetres = ByteData.sublistView(vBytes).getFloat32(0, Endian.little);
  if (vMetres.isNaN || vMetres <= 0 || vMetres > 250) {
    return null;
  }

  return (vMetres * 1000).round();
}
