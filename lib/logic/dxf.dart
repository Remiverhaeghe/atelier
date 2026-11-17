/// Plan de la maison au format DXF (ASCII, version R12), lisible par les logiciels de dessin :
/// un calque par pièce, ses murs en lignes et son nom au milieu, en millimètres.
library;

import 'geometry.dart';
import 'house.dart';
import 'room.dart';

/// Nom de calque accepté partout : lettres sans accent, chiffres et soulignés.
String dxfLayer(String pName) {
  final vPlain = pName
      .toUpperCase()
      .replaceAll(RegExp('[ÀÂÄ]'), 'A')
      .replaceAll(RegExp('[ÉÈÊË]'), 'E')
      .replaceAll(RegExp('[ÎÏ]'), 'I')
      .replaceAll(RegExp('[ÔÖ]'), 'O')
      .replaceAll(RegExp('[ÙÛÜ]'), 'U')
      .replaceAll('Ç', 'C')
      .replaceAll(RegExp(r'[^A-Z0-9_]+'), '_');

  return vPlain.isEmpty ? 'PIECE' : vPlain;
}

String _number(double pValue) => pValue.toStringAsFixed(1);

/// Fichier DXF des pièces [pRooms], placées comme sur le plan de la maison.
String buildDxf(List<Room> pRooms) {
  final rText = StringBuffer();
  void vPair(int pCode, Object pValue) => rText
    ..writeln(pCode)
    ..writeln(pValue);

  vPair(0, 'SECTION');
  vPair(2, 'ENTITIES');
  for (final vRoom in pRooms) {
    final vPoints = houseOutline(vRoom);
    if (vPoints.length < 2) {
      continue;
    }
    final vLayer = dxfLayer(vRoom.name);
    // Le contour a un point de plus que de murs : le dernier ferme la pièce.
    for (var vIndex = 0; vIndex + 1 < vPoints.length; vIndex++) {
      final vFrom = vPoints[vIndex];
      final vTo = vPoints[vIndex + 1];
      vPair(0, 'LINE');
      vPair(8, vLayer);
      vPair(10, _number(vFrom.x));
      vPair(20, _number(vFrom.y));
      vPair(11, _number(vTo.x));
      vPair(21, _number(vTo.y));
    }
    final vCorners = vPoints.take(vPoints.length - 1);
    final vCentre = PlanPoint(
      vCorners.fold(0.0, (pSum, pPoint) => pSum + pPoint.x) / vCorners.length,
      vCorners.fold(0.0, (pSum, pPoint) => pSum + pPoint.y) / vCorners.length,
    );
    vPair(0, 'TEXT');
    vPair(8, vLayer);
    vPair(10, _number(vCentre.x));
    vPair(20, _number(vCentre.y));
    vPair(40, '200.0');
    vPair(1, vRoom.name);
  }
  vPair(0, 'ENDSEC');
  vPair(0, 'EOF');

  return rText.toString();
}
