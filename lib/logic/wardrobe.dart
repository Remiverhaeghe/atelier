/// Armoire sur mesure : caisson, compartiments (penderie ou étagères), portes, liste de débit.
library;

import 'shelf.dart';

/// Contenu d'un compartiment.
enum CompartmentKind {
  /// Tringle sous une tablette haute.
  hanging,

  /// Étagères régulièrement espacées.
  shelves,

  /// Tiroirs sur coulisses, du bas jusqu'en haut du compartiment.
  drawers,
}

class Compartment {
  const Compartment({this.kind = CompartmentKind.shelves, this.shelves = 4});

  final CompartmentKind kind;

  /// Étagères intérieures (hors dessus et dessous du caisson) pour un compartiment à
  /// étagères, ou nombre de tiroirs pour un compartiment à tiroirs.
  final int shelves;
}

class WardrobeDesign {
  const WardrobeDesign({
    this.widthMm = 1200,
    this.heightMm = 2200,
    this.depthMm = 600,
    this.thicknessMm = 18,
    this.material = ShelfMaterial.particleBoard,
    this.compartments = const [Compartment(kind: CompartmentKind.hanging), Compartment()],
    this.doors = true,
  });

  final int widthMm;
  final int heightMm;
  final int depthMm;
  final int thicknessMm;
  final ShelfMaterial material;
  final List<Compartment> compartments;
  final bool doors;

  WardrobeDesign copyWith({
    int? widthMm,
    int? heightMm,
    int? depthMm,
    int? thicknessMm,
    ShelfMaterial? material,
    List<Compartment>? compartments,
    bool? doors,
  }) => WardrobeDesign(
    widthMm: widthMm ?? this.widthMm,
    heightMm: heightMm ?? this.heightMm,
    depthMm: depthMm ?? this.depthMm,
    thicknessMm: thicknessMm ?? this.thicknessMm,
    material: material ?? this.material,
    compartments: compartments ?? this.compartments,
    doors: doors ?? this.doors,
  );
}

/// Noms des pièces, traduits à l'affichage.
const topBottomPart = 'topBottom';
const dividerPart = 'divider';
const doorPart = 'door';
const railPart = 'rail';
const drawerFrontPart = 'drawerFront';
const drawerSidePart = 'drawerSide';
const drawerEndPart = 'drawerEnd';
const drawerBottomPart = 'drawerBottom';
const slidePart = 'slide';

/// Coulisses à billes : longueurs vendues, et jeu de 12,5 mm de chaque côté du tiroir.
const slideLengthsMm = [250, 300, 350, 400, 450, 500, 550, 600, 650];
const slideClearanceMm = 13;

/// Le caisson du tiroir est 40 mm moins haut que sa façade.
const drawerBoxDropMm = 40;

/// Plus longue coulisse qui tient dans [pDepthMm] de profondeur utile, 1 cm de marge.
int slideLengthFor(int pDepthMm) =>
    slideLengthsMm.lastWhere((pLength) => pLength <= pDepthMm - 10, orElse: () => slideLengthsMm.first);

/// Hauteur des charnières sur une porte de [pHeightMm], depuis le haut : à 10 cm des bords,
/// les autres régulièrement entre les deux.
List<int> hingePositions(int pHeightMm) {
  final vCount = hingesPerDoor(pHeightMm);
  final vSpan = pHeightMm - 200;
  final rPositions = [
    for (var vIndex = 0; vIndex < vCount; vIndex++) 100 + vSpan * vIndex ~/ (vCount - 1),
  ];

  return rPositions;
}

/// Tablette haute d'une penderie : 30 cm sous le dessus, la tringle 5 cm dessous.
const hangingShelfGapMm = 300;
const railBelowShelfMm = 50;

/// Jeu entre deux portes et autour.
const doorGapMm = 3;

/// Un compartiment plus large se ferme par deux portes.
const maxDoorWidthMm = 600;

/// Charnières par porte selon sa hauteur, comme le conseillent les fabricants.
int hingesPerDoor(int pHeightMm) => switch (pHeightMm) {
  <= 900 => 2,
  <= 1600 => 3,
  <= 2000 => 4,
  _ => 5,
};

class WardrobePlan {
  const WardrobePlan({
    required this.parts,
    required this.compartmentWidthMm,
    required this.doorCount,
    required this.hinges,
    required this.maxSpanMm,
    this.drawers = 0,
    this.doorHeightMm = 0,
  });

  final List<ShelfPart> parts;

  /// Largeur intérieure de chaque compartiment.
  final int compartmentWidthMm;
  final int doorCount;
  final int hinges;
  final int maxSpanMm;
  final int drawers;
  final int doorHeightMm;

  /// Les étagères d'un compartiment fléchiront sous la charge.
  bool get tooWide => compartmentWidthMm > maxSpanMm;
}

WardrobePlan planWardrobe(WardrobeDesign pDesign) {
  final vCount = pDesign.compartments.isEmpty ? 1 : pDesign.compartments.length;
  final vThick = pDesign.thicknessMm;
  final vInnerHeight = pDesign.heightMm - 2 * vThick;
  final vCompartment = (pDesign.widthMm - (vCount + 1) * vThick) ~/ vCount;
  // Tablettes en retrait de 2 cm pour laisser passer les portes
  final vShelfDepth = pDesign.depthMm - (pDesign.doors ? 20 : 0);
  var vShelves = 0;
  var vRails = 0;
  var vDrawerCompartments = 0;
  final vDrawerParts = <(String, int, int), int>{};
  void vAdd(String pName, int pCount, int pLength, int pWidth) =>
      vDrawerParts[(pName, pLength, pWidth)] = (vDrawerParts[(pName, pLength, pWidth)] ?? 0) + pCount;
  for (final vItem in pDesign.compartments) {
    if (vItem.kind == CompartmentKind.hanging) {
      vShelves += 1;
      vRails += 1;
    } else if (vItem.kind == CompartmentKind.drawers) {
      vDrawerCompartments += 1;
      final vCountDrawers = vItem.shelves < 1 ? 1 : vItem.shelves;
      final vFrontHeight = (pDesign.heightMm - (vCountDrawers + 1) * doorGapMm) ~/ vCountDrawers;
      final vSlide = slideLengthFor(vShelfDepth);
      final vBoxWidth = vCompartment - 2 * slideClearanceMm;
      final vBoxHeight = vFrontHeight - drawerBoxDropMm;
      vAdd(drawerFrontPart, vCountDrawers, vCompartment + vThick - doorGapMm, vFrontHeight);
      vAdd(drawerSidePart, 2 * vCountDrawers, vSlide, vBoxHeight);
      vAdd(drawerEndPart, 2 * vCountDrawers, vBoxWidth - 2 * vThick, vBoxHeight);
      vAdd(drawerBottomPart, vCountDrawers, vBoxWidth, vSlide);
      vAdd(slidePart, vCountDrawers, vSlide, 0);
    } else {
      vShelves += vItem.shelves < 0 ? 0 : vItem.shelves;
    }
  }
  final vDoorsPerCompartment = vCompartment > maxDoorWidthMm ? 2 : 1;
  final vDoorCount = pDesign.doors ? (vCount - vDrawerCompartments) * vDoorsPerCompartment : 0;
  // Sans tiroirs, les portes se partagent toute la largeur ; avec, chaque porte couvre son
  // compartiment et la moitié des séparations
  final vDoorWidth = vDrawerCompartments == 0
      ? (pDesign.widthMm - (vDoorCount + 1) * doorGapMm) ~/ (vDoorCount == 0 ? 1 : vDoorCount)
      : (vCompartment + vThick) ~/ vDoorsPerCompartment - doorGapMm;
  final vDoorHeight = pDesign.heightMm - 2 * doorGapMm;
  final rPlan = WardrobePlan(
    parts: [
      (name: sidePart, count: 2, lengthMm: pDesign.heightMm, widthMm: pDesign.depthMm),
      (
        name: topBottomPart,
        count: 2,
        lengthMm: pDesign.widthMm - 2 * vThick,
        widthMm: pDesign.depthMm,
      ),
      if (vCount > 1)
        (name: dividerPart, count: vCount - 1, lengthMm: vInnerHeight, widthMm: pDesign.depthMm),
      if (vShelves > 0)
        (name: shelfPart, count: vShelves, lengthMm: vCompartment, widthMm: vShelfDepth),
      (name: backPart, count: 1, lengthMm: pDesign.heightMm, widthMm: pDesign.widthMm),
      if (vDoorCount > 0)
        (name: doorPart, count: vDoorCount, lengthMm: vDoorHeight, widthMm: vDoorWidth),
      if (vRails > 0) (name: railPart, count: vRails, lengthMm: vCompartment, widthMm: 0),
      for (final vEntry in vDrawerParts.entries)
        (name: vEntry.key.$1, count: vEntry.value, lengthMm: vEntry.key.$2, widthMm: vEntry.key.$3),
    ],
    compartmentWidthMm: vCompartment,
    doorCount: vDoorCount,
    hinges: vDoorCount * hingesPerDoor(vDoorHeight),
    maxSpanMm: pDesign.material.spanPer18Mm * vThick ~/ 18,
    drawers: vDrawerParts[(slidePart, slideLengthFor(vShelfDepth), 0)] ?? 0,
    doorHeightMm: vDoorCount == 0 ? 0 : vDoorHeight,
  );

  return rPlan;
}
