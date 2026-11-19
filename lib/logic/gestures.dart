/// Gestes de base pour qui débute : à quoi ils servent, comment les faire et avec quelle
/// protection.
library;

import 'glossary.dart';

/// Protections à porter.
enum Gear { glasses, mask, gloves, earmuffs }

/// Gestes expliqués, chacun avec ses protections et les mots du métier qui vont avec.
enum Gesture {
  saw(gear: {Gear.glasses}, terms: [Term.kerf, Term.grain]),
  plane(gear: {}, terms: [Term.grain, Term.edge, Term.chamfer]),
  drill(gear: {Gear.glasses}, terms: [Term.pilotHole], rotating: true),
  screw(gear: {}, terms: [Term.pilotHole, Term.countersink], rotating: true),
  sand(gear: {Gear.glasses, Gear.mask, Gear.earmuffs}, terms: [Term.grain]),
  chisel(gear: {Gear.glasses}, terms: [Term.mortise, Term.tenon]),
  caulk(gear: {Gear.gloves}, terms: []);

  const Gesture({required this.gear, required this.terms, this.rotating = false});

  final Set<Gear> gear;
  final List<Term> terms;

  /// Outil qui tourne : pas de gants, un gant pris par le mandrin entraîne la main.
  final bool rotating;
}

/// Une passe de l'outil : 0 au départ, 1 au bout de la course, et retour, sans à-coup.
double stroke(double pPhase) {
  final vPhase = pPhase - pPhase.floorToDouble();
  final rStroke = vPhase < 0.5 ? _ease(vPhase * 2) : _ease(2 - vPhase * 2);

  return rStroke;
}

double _ease(double pValue) => pValue * pValue * (3 - 2 * pValue);
