/// Matériel disponible : outils déjà là, et ce qui manque pour une pièce ou un chantier.
library;

import 'guidance.dart';
import 'room.dart';
import 'worksite.dart';

/// Outils nécessaires à la pièce et absents de [pOwned] ; aucun si l'inventaire n'est pas fait.
List<Tool> missingTools(Room pRoom, List<String> pOwned) {
  if (pOwned.isEmpty) {
    return const [];
  }
  final rMissing = [
    for (final vTool in toolsFor(pRoom.parquet.type, pRoom.baseboard.fixing))
      if (!pOwned.contains(vTool.name)) vTool,
  ];

  return rMissing;
}

/// Outils qui manquent sur tout le chantier, sans doublon, dans l'ordre des outils.
List<Tool> worksiteMissingTools(Worksite pWorksite) {
  final vMissing = {
    for (final vRoom in pWorksite.rooms.where((pRoom) => pRoom.walls.length >= 3))
      ...missingTools(vRoom, pWorksite.ownedTools),
  };
  final rTools = [
    for (final vTool in Tool.values)
      if (vMissing.contains(vTool)) vTool,
  ];

  return rTools;
}

/// Coche ou décoche un outil possédé.
List<String> toggleTool(List<String> pOwned, Tool pTool, bool pOwnedNow) {
  final vOwned = {...pOwned};
  pOwnedNow ? vOwned.add(pTool.name) : vOwned.remove(pTool.name);
  final rOwned = [
    for (final vTool in Tool.values)
      if (vOwned.contains(vTool.name)) vTool.name,
  ];

  return rOwned;
}
