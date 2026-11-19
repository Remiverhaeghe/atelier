/// Gestes de base pour qui débute : à quoi ils servent, comment les faire et avec quelle
/// protection.
library;

import 'glossary.dart';
import 'starter_tools.dart';

/// Protections à porter.
enum Gear { glasses, mask, gloves, earmuffs }

/// Gestes expliqués, chacun avec ses protections et les mots du métier qui vont avec.
enum Gesture {
  saw(
    gear: {Gear.glasses},
    terms: [Term.kerf, Term.grain],
    tools: [StarterTool.tape, StarterTool.pencil, StarterTool.square, StarterTool.handSaw],
  ),
  plane(
    gear: {},
    terms: [Term.grain, Term.edge, Term.chamfer],
    tools: [StarterTool.plane, StarterTool.clamps],
  ),
  drill(
    gear: {Gear.glasses},
    terms: [Term.pilotHole],
    tools: [StarterTool.pencil, StarterTool.drillDriver, StarterTool.bits, StarterTool.clamps],
    rotating: true,
  ),
  screw(
    gear: {},
    terms: [Term.pilotHole, Term.countersink],
    tools: [StarterTool.drillDriver, StarterTool.bits, StarterTool.screwdrivers],
    rotating: true,
  ),
  sand(
    gear: {Gear.glasses, Gear.mask, Gear.earmuffs},
    terms: [Term.grain],
    tools: [StarterTool.sander, StarterTool.dustMask],
  ),
  chisel(
    gear: {Gear.glasses},
    terms: [Term.mortise, Term.tenon],
    tools: [StarterTool.chisels, StarterTool.mallet, StarterTool.clamps, StarterTool.pencil],
  ),
  caulk(gear: {Gear.gloves}, terms: [], tools: [StarterTool.caulkGun, StarterTool.cutter]),
  plug(
    gear: {Gear.glasses},
    terms: [],
    tools: [StarterTool.detector, StarterTool.drillDriver, StarterTool.bits, StarterTool.hammer],
    rotating: true,
  ),
  cutBoard(
    gear: {Gear.gloves},
    terms: [Term.plasterboard],
    tools: [StarterTool.tape, StarterTool.pencil, StarterTool.cutter, StarterTool.spiritLevel],
  ),
  mitre(
    gear: {Gear.glasses},
    terms: [Term.kerf],
    tools: [StarterTool.mitreBox, StarterTool.handSaw, StarterTool.pencil, StarterTool.tape],
  ),
  laser(gear: {}, terms: [], tools: [StarterTool.laserLevel, StarterTool.pencil]),
  grout(
    gear: {Gear.gloves, Gear.mask},
    terms: [],
    tools: [StarterTool.groutFloat, StarterTool.dustMask],
  );

  const Gesture({
    required this.gear,
    required this.terms,
    required this.tools,
    this.rotating = false,
  });

  final Set<Gear> gear;
  final List<Term> terms;

  /// Outils de la caisse du débutant qui servent à ce geste.
  final List<StarterTool> tools;

  /// Outil qui tourne : pas de gants, un gant pris par le mandrin entraîne la main.
  final bool rotating;
}

/// Gestes qui se servent de [pTool].
List<Gesture> gesturesWith(StarterTool pTool) =>
    Gesture.values.where((pGesture) => pGesture.tools.contains(pTool)).toList();

/// Une passe de l'outil : 0 au départ, 1 au bout de la course, et retour, sans à-coup.
double stroke(double pPhase) {
  final vPhase = pPhase - pPhase.floorToDouble();
  final rStroke = vPhase < 0.5 ? _ease(vPhase * 2) : _ease(2 - vPhase * 2);

  return rStroke;
}

double _ease(double pValue) => pValue * pValue * (3 - 2 * pValue);
