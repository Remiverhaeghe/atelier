/// Projets modèles prêts à suivre : pour quelques cotes saisies, le débit, les courses et les
/// étapes, chacune reliée au geste animé qui la montre.
library;

import 'gestures.dart';

/// Projets proposés.
enum ReadyProject { wallShelf, fixedFrame, mezzanine, roofReveal }

/// Cotes d'un projet, en millimètres : largeur, hauteur et profondeur.
typedef ProjectSize = ({int widthMm, int heightMm, int depthMm});

/// Pièces du débit.
enum PartKind {
  shelfBoard,
  cleat,
  stile,
  rail,
  glazingBead,
  joist,
  ledger,
  frontBeam,
  post,
  floorPanel,
  sideBoard,
  headBoard,
  sillBoard,
  batten,
}

/// Articles des courses.
enum BuyKind {
  woodScrews,
  wallScrews,
  wallPlugs,
  woodGlue,
  sandpaper,
  varnish,
  glass,
  glazingBlocks,
  silicone,
  pins,
  frameScrews,
  joistHangers,
  hangerNails,
  anchorBolts,
  floorScrews,
  postBases,
  plasterScrews,
  cornerBead,
  jointTape,
  jointCompound,
}

/// Étapes, dans l'ordre où on les fait.
enum StepKind {
  measure,
  cutBoards,
  sand,
  drillWall,
  fixCleat,
  setShelf,
  finish,
  cutFrame,
  rebate,
  assembleFrame,
  cutBeads,
  setGlass,
  sealGlass,
  traceLedger,
  boltLedger,
  cutJoists,
  fixHangers,
  setJoists,
  setPosts,
  layFloor,
  fixBattens,
  cutPlaster,
  screwPlaster,
  cornerBeads,
  fillJoints,
}

/// Une ligne du débit : nombre, longueur, largeur et épaisseur en millimètres.
typedef ProjectPart = ({PartKind kind, int count, int lengthMm, int widthMm, int thicknessMm});

typedef ProjectBuy = ({BuyKind kind, int quantity});

/// Une étape et le geste qui la montre ; null quand aucun geste animé ne correspond.
typedef ProjectStep = ({StepKind kind, Gesture? gesture});

typedef ProjectPlan = ({List<ProjectPart> parts, List<ProjectBuy> buy, List<ProjectStep> steps});

/// Cotes proposées à l'ouverture d'un projet.
ProjectSize defaultSize(ReadyProject pProject) => switch (pProject) {
  ReadyProject.wallShelf => (widthMm: 800, heightMm: 0, depthMm: 250),
  ReadyProject.fixedFrame => (widthMm: 600, heightMm: 900, depthMm: 0),
  ReadyProject.mezzanine => (widthMm: 2400, heightMm: 2200, depthMm: 2000),
  ReadyProject.roofReveal => (widthMm: 780, heightMm: 980, depthMm: 300),
};

/// Cotes qui servent au projet.
({bool width, bool height, bool depth}) usedSizes(ReadyProject pProject) => switch (pProject) {
  ReadyProject.wallShelf => (width: true, height: false, depth: true),
  ReadyProject.fixedFrame => (width: true, height: true, depth: false),
  ReadyProject.mezzanine || ReadyProject.roofReveal => (width: true, height: true, depth: true),
};

/// Entraxe des solives d'une mezzanine simple ; la section reste à vérifier avec le calcul
/// de la mezzanine, selon la portée et la charge.
const joistSpacingMm = 400;

/// Montant et traverse du châssis fixe, feuillure qui reçoit le vitrage et jeu tout autour.
const frameSectionMm = 58;
const frameRebateMm = 12;
const glassPlayMm = 3;

/// Panneau de plancher courant : 2500 × 675 mm, rainuré et bouveté.
const floorPanelLengthMm = 2500;
const floorPanelWidthMm = 675;

/// Longueur des tasseaux et des cornières vendus en magasin.
const battenBarMm = 2400;
const cornerBarMm = 2500;

int _ceilDiv(int pAmount, int pSize) => pAmount <= 0 ? 0 : (pAmount + pSize - 1) ~/ pSize;

/// Débit, courses et étapes de [pProject] pour les cotes [pSize].
ProjectPlan projectPlan(ReadyProject pProject, ProjectSize pSize) {
  final rPlan = switch (pProject) {
    ReadyProject.wallShelf => _wallShelf(pSize),
    ReadyProject.fixedFrame => _fixedFrame(pSize),
    ReadyProject.mezzanine => _mezzanine(pSize),
    ReadyProject.roofReveal => _roofReveal(pSize),
  };

  return rPlan;
}

ProjectPart _part(PartKind pKind, int pCount, int pLength, int pWidth, int pThickness) =>
    (kind: pKind, count: pCount, lengthMm: pLength, widthMm: pWidth, thicknessMm: pThickness);

/// Étagère murale sur tasseau caché : la planche se visse sur un tasseau fixé au mur.
ProjectPlan _wallShelf(ProjectSize pSize) {
  final vCleat = pSize.widthMm - 40;
  final vWallFixings = _ceilDiv(vCleat, 400) + 1;

  return (
    parts: [
      _part(PartKind.shelfBoard, 1, pSize.widthMm, pSize.depthMm, 22),
      _part(PartKind.cleat, 1, vCleat, 45, 22),
    ],
    buy: [
      (kind: BuyKind.wallScrews, quantity: vWallFixings),
      (kind: BuyKind.wallPlugs, quantity: vWallFixings),
      (kind: BuyKind.woodScrews, quantity: _ceilDiv(vCleat, 250) + 1),
      (kind: BuyKind.woodGlue, quantity: 1),
      (kind: BuyKind.sandpaper, quantity: 1),
      (kind: BuyKind.varnish, quantity: 1),
    ],
    steps: const [
      (kind: StepKind.measure, gesture: Gesture.laser),
      (kind: StepKind.cutBoards, gesture: Gesture.saw),
      (kind: StepKind.sand, gesture: Gesture.sand),
      (kind: StepKind.drillWall, gesture: Gesture.plug),
      (kind: StepKind.fixCleat, gesture: Gesture.screw),
      (kind: StepKind.setShelf, gesture: Gesture.drill),
      (kind: StepKind.finish, gesture: null),
    ],
  );
}

/// Châssis fixe à la place d'un plexi : cadre à feuillure, vitrage tenu par des parcloses.
ProjectPlan _fixedFrame(ProjectSize pSize) {
  final vRail = pSize.widthMm - 2 * frameSectionMm;
  final vGlassW = vRail + 2 * frameRebateMm - 2 * glassPlayMm;
  final vGlassH = pSize.heightMm - 2 * frameSectionMm + 2 * frameRebateMm - 2 * glassPlayMm;
  final vBeadsMm = 2 * (vGlassW + vGlassH + 4 * glassPlayMm);

  return (
    parts: [
      _part(PartKind.stile, 2, pSize.heightMm, frameSectionMm, 45),
      _part(PartKind.rail, 2, vRail, frameSectionMm, 45),
      _part(PartKind.glazingBead, 2, vGlassW + 2 * glassPlayMm, 15, 15),
      _part(PartKind.glazingBead, 2, vGlassH + 2 * glassPlayMm, 15, 15),
    ],
    buy: [
      (kind: BuyKind.glass, quantity: 1),
      (kind: BuyKind.glazingBlocks, quantity: 8),
      (kind: BuyKind.frameScrews, quantity: 8),
      (kind: BuyKind.woodGlue, quantity: 1),
      (kind: BuyKind.pins, quantity: _ceilDiv(vBeadsMm, 150)),
      (kind: BuyKind.silicone, quantity: 1),
      (kind: BuyKind.sandpaper, quantity: 1),
      (kind: BuyKind.varnish, quantity: 1),
    ],
    steps: const [
      (kind: StepKind.measure, gesture: Gesture.laser),
      (kind: StepKind.cutFrame, gesture: Gesture.saw),
      (kind: StepKind.rebate, gesture: Gesture.chisel),
      (kind: StepKind.assembleFrame, gesture: Gesture.screw),
      (kind: StepKind.sand, gesture: Gesture.sand),
      (kind: StepKind.cutBeads, gesture: Gesture.mitre),
      (kind: StepKind.setGlass, gesture: null),
      (kind: StepKind.sealGlass, gesture: Gesture.caulk),
    ],
  );
}

/// Vitrage à commander pour le châssis fixe : largeur et hauteur en millimètres.
({int widthMm, int heightMm}) frameGlass(ProjectSize pSize) {
  final vOpening = 2 * frameRebateMm - 2 * glassPlayMm - 2 * frameSectionMm;
  final rGlass = (widthMm: pSize.widthMm + vOpening, heightMm: pSize.heightMm + vOpening);

  return rGlass;
}

/// Mezzanine simple entre un mur porteur et une poutre sur deux poteaux.
ProjectPlan _mezzanine(ProjectSize pSize) {
  final vJoists = _ceilDiv(pSize.widthMm, joistSpacingMm) + 1;
  final vArea = pSize.widthMm * pSize.depthMm;
  // Dix pour cent de plus pour les chutes en bout de rangée
  final vPanels = _ceilDiv(vArea * 11, floorPanelLengthMm * floorPanelWidthMm * 10);

  return (
    parts: [
      _part(PartKind.ledger, 1, pSize.widthMm, 195, 45),
      _part(PartKind.frontBeam, 1, pSize.widthMm, 220, 70),
      // Les solives s'arrêtent entre la lambourde du mur et la poutre avant
      _part(PartKind.joist, vJoists, pSize.depthMm - 45 - 70, 195, 45),
      _part(PartKind.post, 2, pSize.heightMm, 90, 90),
      _part(PartKind.floorPanel, vPanels, floorPanelLengthMm, floorPanelWidthMm, 22),
    ],
    buy: [
      (kind: BuyKind.anchorBolts, quantity: _ceilDiv(pSize.widthMm, 500) + 1),
      (kind: BuyKind.joistHangers, quantity: 2 * vJoists),
      (kind: BuyKind.hangerNails, quantity: 2 * vJoists * 10),
      (kind: BuyKind.postBases, quantity: 2),
      (kind: BuyKind.floorScrews, quantity: vPanels * 20),
      (kind: BuyKind.woodGlue, quantity: 1),
    ],
    steps: const [
      (kind: StepKind.traceLedger, gesture: Gesture.laser),
      (kind: StepKind.boltLedger, gesture: Gesture.drill),
      (kind: StepKind.setPosts, gesture: Gesture.drill),
      (kind: StepKind.cutJoists, gesture: Gesture.saw),
      (kind: StepKind.fixHangers, gesture: Gesture.screw),
      (kind: StepKind.setJoists, gesture: Gesture.screw),
      (kind: StepKind.layFloor, gesture: Gesture.screw),
      (kind: StepKind.sand, gesture: Gesture.sand),
    ],
  );
}

/// Embrasure d'une fenêtre de toit en plaque de plâtre : deux joues, un linteau et un appui.
ProjectPlan _roofReveal(ProjectSize pSize) {
  final vPerimeter = 2 * (pSize.widthMm + pSize.heightMm);
  final vAreaM2 = 2 * pSize.depthMm * (pSize.widthMm + pSize.heightMm) / 1e6;

  return (
    parts: [
      _part(PartKind.sideBoard, 2, pSize.heightMm, pSize.depthMm, 13),
      _part(PartKind.headBoard, 1, pSize.widthMm, pSize.depthMm, 13),
      _part(PartKind.sillBoard, 1, pSize.widthMm, pSize.depthMm, 13),
      // Un tasseau le long de chaque bord des quatre plaques
      _part(PartKind.batten, _ceilDiv(2 * vPerimeter, battenBarMm), battenBarMm, 27, 18),
    ],
    buy: [
      (kind: BuyKind.plasterScrews, quantity: (vAreaM2 * 20).ceil() + 10),
      (kind: BuyKind.cornerBead, quantity: _ceilDiv(vPerimeter, cornerBarMm)),
      (kind: BuyKind.jointTape, quantity: 1),
      (kind: BuyKind.jointCompound, quantity: 1),
      (kind: BuyKind.sandpaper, quantity: 1),
    ],
    steps: const [
      (kind: StepKind.measure, gesture: Gesture.laser),
      (kind: StepKind.fixBattens, gesture: Gesture.screw),
      (kind: StepKind.cutPlaster, gesture: Gesture.cutBoard),
      (kind: StepKind.screwPlaster, gesture: Gesture.screw),
      (kind: StepKind.cornerBeads, gesture: null),
      (kind: StepKind.fillJoints, gesture: null),
      (kind: StepKind.sand, gesture: Gesture.sand),
    ],
  );
}

/// Plus grande cote acceptée : au-delà, ce n'est plus un petit projet à suivre seul.
const maxProjectMm = 6000;

/// Cotes acceptées : assez grandes pour le cadre ou le tasseau, sans dépasser [maxProjectMm].
bool sizeIsValid(ReadyProject pProject, ProjectSize pSize) {
  final vUsed = usedSizes(pProject);
  final vMin = switch (pProject) {
    ReadyProject.wallShelf => 200,
    ReadyProject.fixedFrame => 3 * frameSectionMm,
    ReadyProject.mezzanine => 1000,
    ReadyProject.roofReveal => 100,
  };
  bool vOk(bool pUsed, int pValue, int pMin) =>
      !pUsed || (pValue >= pMin && pValue <= maxProjectMm);
  final rOk =
      vOk(vUsed.width, pSize.widthMm, vMin) &&
      vOk(vUsed.height, pSize.heightMm, vMin) &&
      vOk(vUsed.depth, pSize.depthMm, 100);

  return rOk;
}
