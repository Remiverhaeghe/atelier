/// Armoire sur mesure : caisson, compartiments (penderie ou étagères), portes, liste de débit.
library;

import 'shelf.dart';

/// Contenu d'un compartiment.
enum CompartmentKind {
  /// Tringle sous une tablette haute.
  hanging,

  /// Étagères régulièrement espacées.
  shelves,
}

class Compartment {
  const Compartment({this.kind = CompartmentKind.shelves, this.shelves = 4});

  final CompartmentKind kind;

  /// Étagères intérieures (hors dessus et dessous du caisson) pour un compartiment à étagères.
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
  });

  final List<ShelfPart> parts;

  /// Largeur intérieure de chaque compartiment.
  final int compartmentWidthMm;
  final int doorCount;
  final int hinges;
  final int maxSpanMm;

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
  for (final vItem in pDesign.compartments) {
    if (vItem.kind == CompartmentKind.hanging) {
      vShelves += 1;
      vRails += 1;
    } else {
      vShelves += vItem.shelves < 0 ? 0 : vItem.shelves;
    }
  }
  final vDoorsPerCompartment = vCompartment > maxDoorWidthMm ? 2 : 1;
  final vDoorCount = pDesign.doors ? vCount * vDoorsPerCompartment : 0;
  final vDoorWidth =
      (pDesign.widthMm - (vDoorCount + 1) * doorGapMm) ~/ (vDoorCount == 0 ? 1 : vDoorCount);
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
    ],
    compartmentWidthMm: vCompartment,
    doorCount: vDoorCount,
    hinges: vDoorCount * hingesPerDoor(vDoorHeight),
    maxSpanMm: pDesign.material.spanPer18Mm * vThick ~/ 18,
  );

  return rPlan;
}
