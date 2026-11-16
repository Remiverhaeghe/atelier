/// Électricité : repères de quantités par pièce (prises, points lumineux, boîtes, gaine, fil).
///
/// Minimums courants de la norme NF C 15-100 pour un logement ; ils ne remplacent ni la norme
/// à jour ni l'avis d'un électricien.
library;

enum ElecRoomKind { living, bedroom, kitchen, bathroom, hallway, toilet }

class ElecRoom {
  const ElecRoom({required this.kind, this.areaM2 = 12});

  final ElecRoomKind kind;
  final double areaM2;
}

/// Prises de courant minimales d'une pièce.
int minSockets(ElecRoom pRoom) => switch (pRoom.kind) {
  // Une prise par tranche de 4 m², cinq au moins
  ElecRoomKind.living => _max(5, (pRoom.areaM2 / 4 - 1e-9).ceil()),
  ElecRoomKind.bedroom => 3,
  // Six prises dont quatre au-dessus du plan de travail
  ElecRoomKind.kitchen => 6,
  ElecRoomKind.bathroom => 1,
  ElecRoomKind.hallway => 1,
  ElecRoomKind.toilet => 0,
};

/// Circuits spécialisés de la cuisine : four, plaques, lave-vaisselle, lave-linge, congélateur.
int dedicatedCircuits(ElecRoom pRoom) => pRoom.kind == ElecRoomKind.kitchen ? 5 : 0;

int _max(int pA, int pB) => pA > pB ? pA : pB;

/// Quantités d'une installation : un point lumineux et un interrupteur par pièce au moins.
typedef ElecNeeds = ({
  int sockets,
  int lights,
  int switches,
  int boxes,
  int dedicated,
  int conduitMetres,
  int wireMetres,
});

/// [pRunMetres] : longueur moyenne d'une ligne jusqu'au tableau, plus 10 % de marge.
ElecNeeds elecNeeds(List<ElecRoom> pRooms, {int pRunMetres = 10}) {
  var vSockets = 0;
  var vDedicated = 0;
  for (final vRoom in pRooms) {
    vSockets += minSockets(vRoom);
    vDedicated += dedicatedCircuits(vRoom);
  }
  final vLights = pRooms.length;
  final vPoints = vSockets + vLights + vDedicated;
  final vConduit = (vPoints * pRunMetres * 1.1).ceil();
  final rNeeds = (
    sockets: vSockets,
    lights: vLights,
    switches: vLights,
    // Une boîte d'encastrement par prise, interrupteur et point lumineux
    boxes: vSockets + 2 * vLights,
    dedicated: vDedicated,
    conduitMetres: vConduit,
    // Phase, neutre et terre dans chaque gaine
    wireMetres: vConduit * 3,
  );

  return rNeeds;
}
