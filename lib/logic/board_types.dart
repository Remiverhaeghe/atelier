/// Panneaux de bois du commerce : lequel prendre selon l'usage, et ce que pèse une plaque.
///
/// Les valeurs sont des ordres de grandeur pour comparer les panneaux entre eux ; la fiche du
/// fabricant fait foi (classe d'humidité, charge admise).
library;

/// À quoi va servir le panneau.
enum BoardUse { shelf, furniture, floor, bracing, damp, outdoor, painted }

/// Panneaux courants.
enum BoardType {
  plywood(densityKgM3: 550, price: 3, screwHold: 3, uses: {
    BoardUse.shelf, BoardUse.furniture, BoardUse.floor, BoardUse.bracing, BoardUse.damp,
    BoardUse.outdoor,
  }),
  osb(densityKgM3: 620, price: 1, screwHold: 2, uses: {BoardUse.floor, BoardUse.bracing, BoardUse.damp}),
  mdf(densityKgM3: 750, price: 1, screwHold: 1, uses: {BoardUse.furniture, BoardUse.painted}),
  blockboard(densityKgM3: 480, price: 2, screwHold: 3, uses: {BoardUse.shelf, BoardUse.furniture}),
  melamine(densityKgM3: 680, price: 1, screwHold: 1, uses: {BoardUse.furniture}),
  particleboard(densityKgM3: 650, price: 1, screwHold: 1, uses: {BoardUse.floor});

  const BoardType({
    required this.densityKgM3,
    required this.price,
    required this.screwHold,
    required this.uses,
  });

  final int densityKgM3;

  /// 1 bon marché, 3 cher, à épaisseur égale.
  final int price;

  /// Tenue d'une vis dans le chant : 1 faible, 3 bonne.
  final int screwHold;

  final Set<BoardUse> uses;
}

/// Format de plaque le plus courant en magasin, en mm.
const boardSheetLengthMm = 2500;
const boardSheetWidthMm = 1250;

/// Poids au-delà duquel une plaque se porte à deux.
const carryAloneKg = 25;

/// Panneaux qui conviennent à [pUse], du moins cher au plus cher, puis du mieux tenu.
List<BoardType> boardsFor(BoardUse pUse) {
  final rBoards = BoardType.values.where((pBoard) => pBoard.uses.contains(pUse)).toList()
    ..sort((pA, pB) {
      final vPrice = pA.price.compareTo(pB.price);
      return vPrice != 0 ? vPrice : pB.screwHold.compareTo(pA.screwHold);
    });

  return rBoards;
}

/// Poids d'une plaque de [pBoard] de [pThicknessMm], au format courant.
double sheetKg(BoardType pBoard, int pThicknessMm) {
  final vM3 = boardSheetLengthMm * boardSheetWidthMm * pThicknessMm / 1e9;
  final rKg = vM3 * pBoard.densityKgM3;

  return rKg;
}
