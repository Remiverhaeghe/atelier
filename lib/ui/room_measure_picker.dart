import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../logic/room.dart';
import '../logic/room_measures.dart';
import '../logic/units.dart';

String measureName(AppLocalizations pText, RoomMeasureKey pKey) => switch (pKey) {
  RoomMeasureKey.length => pText.measureLength,
  RoomMeasureKey.width => pText.measureWidth,
  RoomMeasureKey.height => pText.measureHeight,
  RoomMeasureKey.perimeter => pText.measurePerimeter,
  RoomMeasureKey.floor => pText.measureFloor,
  RoomMeasureKey.walls => pText.measureWalls,
  RoomMeasureKey.volume => pText.measureVolume,
};

/// Longueur avec son unité, dans celle que l'utilisateur a choisie : « 245 cm », « 2,45 m ».
String lengthText(AppLocalizations pText, int pMillimetres, FieldUnit pUnit) =>
    '${lengthInUnit(pMillimetres, pUnit)} ${unitName(pText, pUnit)}';

String unitName(AppLocalizations pText, FieldUnit pUnit) => switch (pUnit) {
  FieldUnit.mm => pText.unitMm,
  FieldUnit.cm => pText.unitCm,
  FieldUnit.m => pText.unitM,
  FieldUnit.m2 => pText.unitM2,
  FieldUnit.m3 => pText.unitM3,
};

/// Pièces qui ont au moins une cote à proposer pour un champ de cette unité.
List<Room> roomsWithMeasures(List<Room> pRooms, FieldUnit pUnit) => [
  for (final vRoom in pRooms)
    if (roomMeasures(vRoom).any((pMeasure) => fitsField(pMeasure.key, pUnit))) vRoom,
];

/// Feuille « Reprendre une cote d'une pièce » : renvoie le texte à mettre dans le champ.
Future<String?> pickRoomMeasure(BuildContext pContext, List<Room> pRooms, FieldUnit pUnit) =>
    showModalBottomSheet<String>(
      context: pContext,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (pSheetContext) {
        final vText = AppLocalizations.of(pSheetContext);
        final vTheme = Theme.of(pSheetContext);

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          builder: (_, pController) => ListView(
            controller: pController,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            children: [
              Text(vText.measuresPick, style: vTheme.textTheme.titleMedium),
              Text(vText.measuresHint, style: vTheme.textTheme.bodySmall),
              for (final vRoom in roomsWithMeasures(pRooms, pUnit)) ...[
                const SizedBox(height: 12),
                Text(vRoom.name, style: vTheme.textTheme.titleSmall),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final vMeasure in roomMeasures(vRoom))
                      if (fitsField(vMeasure.key, pUnit))
                        ActionChip(
                          label: Text(
                            vText.measureChoice(
                              measureName(vText, vMeasure.key),
                              measureInUnit(vMeasure, pUnit),
                              unitName(vText, pUnit),
                            ),
                          ),
                          onPressed: () =>
                              Navigator.pop(pSheetContext, measureInUnit(vMeasure, pUnit)),
                        ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
