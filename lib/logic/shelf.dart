/// Étagère sur mesure : portée possible selon le panneau, liste de débit, panneaux et vis.
library;

import 'bar_cutting.dart';

/// Panneaux courants, avec la portée au-delà de laquelle une tablette chargée de livres fléchit.
enum ShelfMaterial {
  /// Aggloméré mélaminé.
  particleBoard(spanPer18Mm: 700),
  mdf(spanPer18Mm: 800),
  plywood(spanPer18Mm: 900),
  solidWood(spanPer18Mm: 1000);

  const ShelfMaterial({required this.spanPer18Mm});

  /// Portée conseillée pour 18 mm d'épaisseur ; elle croît avec l'épaisseur.
  final int spanPer18Mm;
}

class ShelfDesign {
  const ShelfDesign({
    this.widthMm = 800,
    this.heightMm = 1800,
    this.depthMm = 300,
    this.shelves = 5,
    this.thicknessMm = 18,
    this.material = ShelfMaterial.particleBoard,
    this.back = true,
    this.boardLengthMm = 2500,
  });

  /// Dimensions hors tout.
  final int widthMm;
  final int heightMm;
  final int depthMm;

  /// Tablettes entre les montants, dessus et dessous compris.
  final int shelves;
  final int thicknessMm;
  final ShelfMaterial material;

  /// Fond en panneau fin cloué au dos : il raidit l'étagère.
  final bool back;

  /// Longueur des panneaux vendus, débités en bandes de la profondeur.
  final int boardLengthMm;

  ShelfDesign copyWith({
    int? widthMm,
    int? heightMm,
    int? depthMm,
    int? shelves,
    int? thicknessMm,
    ShelfMaterial? material,
    bool? back,
    int? boardLengthMm,
  }) => ShelfDesign(
    widthMm: widthMm ?? this.widthMm,
    heightMm: heightMm ?? this.heightMm,
    depthMm: depthMm ?? this.depthMm,
    shelves: shelves ?? this.shelves,
    thicknessMm: thicknessMm ?? this.thicknessMm,
    material: material ?? this.material,
    back: back ?? this.back,
    boardLengthMm: boardLengthMm ?? this.boardLengthMm,
  );
}

/// Une pièce de la liste de débit.
typedef ShelfPart = ({String name, int count, int lengthMm, int widthMm});

/// Noms des pièces, traduits à l'affichage.
const sidePart = 'side';
const shelfPart = 'shelf';
const backPart = 'back';

/// Résultat : pièces à débiter, panneaux, vis, portée et écart entre tablettes.
class ShelfPlan {
  const ShelfPlan({
    required this.parts,
    required this.boards,
    required this.screws,
    required this.maxSpanMm,
    required this.gapMm,
  });

  final List<ShelfPart> parts;

  /// Panneaux à acheter, débités en bandes de la profondeur.
  final int boards;

  /// Deux vis à chaque bout de chaque tablette.
  final int screws;
  final int maxSpanMm;

  /// Hauteur libre entre deux tablettes.
  final int gapMm;

  /// La tablette, entre les montants, fléchira sous des livres.
  bool get tooWide => parts.firstWhere((pPart) => pPart.name == shelfPart).lengthMm > maxSpanMm;
}

ShelfPlan planShelf(ShelfDesign pDesign) {
  final vInner = pDesign.widthMm - 2 * pDesign.thicknessMm;
  final vShelves = pDesign.shelves < 2 ? 2 : pDesign.shelves;
  final vParts = <ShelfPart>[
    (name: sidePart, count: 2, lengthMm: pDesign.heightMm, widthMm: pDesign.depthMm),
    (name: shelfPart, count: vShelves, lengthMm: vInner, widthMm: pDesign.depthMm),
    if (pDesign.back)
      (name: backPart, count: 1, lengthMm: pDesign.heightMm, widthMm: pDesign.widthMm),
  ];
  // Montants et tablettes ont la même profondeur : ils se débitent en bandes, comme des barres
  final vStrips = [
    for (final vPart in vParts.where((pPart) => pPart.name != backPart))
      for (var vIndex = 0; vIndex < vPart.count; vIndex++) vPart.lengthMm,
  ];
  final vBars = planBars(vStrips, pDesign.boardLengthMm, 3);
  // Bandes par panneau : un panneau de 1250 mm de large donne plusieurs bandes de la profondeur
  final vStripsPerBoard = pDesign.depthMm <= 0
      ? 1
      : (1250 ~/ (pDesign.depthMm + 3)).clamp(1, 1 << 20);
  final rPlan = ShelfPlan(
    parts: vParts,
    boards: (vBars.bars.length + vStripsPerBoard - 1) ~/ vStripsPerBoard,
    screws: vShelves * 2 * 2,
    maxSpanMm: pDesign.material.spanPer18Mm * pDesign.thicknessMm ~/ 18,
    gapMm: (pDesign.heightMm - vShelves * pDesign.thicknessMm) ~/ (vShelves - 1),
  );

  return rPlan;
}
